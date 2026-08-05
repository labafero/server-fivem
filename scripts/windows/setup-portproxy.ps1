# ATENÇÃO: este arquivo precisa manter o BOM UTF-8 (bytes EF BB BF no início).
# Sem ele, o Windows PowerShell 5.1 lê mal os acentos/travessão e o parser
# quebra com "A cadeia de caracteres não tem o terminador" — não é erro de
# sintaxe, é encoding. Ao editar, garanta que o BOM não seja removido.
#
# Encaminha a porta do FXServer (30120, TCP+UDP) do Windows para o WSL2,
# para que outras máquinas na mesma rede local consigam conectar.
#
# Mantém o WSL em modo NAT (não usa networkingMode=mirrored) — só cria/atualiza
# regras de portproxy + firewall pontuais para a porta do jogo. Idempotente:
# remove regras antigas antes de recriar, então pode rodar de novo sempre que
# o IP interno do WSL mudar (acontece a cada reboot/restart do WSL).
#
# Rodar como Administrador, no PowerShell do Windows, sempre que for jogar
# em rede local (o IP interno do WSL muda a cada restart, então o proxy
# precisa ser refeito):
#   powershell -ExecutionPolicy Bypass -File scripts\windows\setup-portproxy.ps1
#
# Para acesso também ao txAdmin (porta 40120) pela rede local, rode:
#   .\setup-portproxy.ps1 -TxAdmin
#
# Pra não precisar lembrar de rodar manual: -Install registra uma Tarefa
# Agendada que roda este mesmo script sozinho, elevado, a cada logon —
# só precisa rodar -Install uma vez.
#   powershell -ExecutionPolicy Bypass -File scripts\windows\setup-portproxy.ps1 -Install

param(
    [int]$GamePort = 30120,
    [switch]$TxAdmin,
    [int]$TxAdminPort = 40120,
    [switch]$Install
)

$ErrorActionPreference = "Stop"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Rode este script como Administrador (PowerShell > Executar como administrador)."
    exit 1
}

if ($Install) {
    $taskName = "Labafero FXServer Portproxy"
    $scriptArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
    if ($TxAdmin) { $scriptArgs += " -TxAdmin" }
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $scriptArgs
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -RunLevel Highest -LogonType Interactive
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
    Write-Host "Tarefa agendada '$taskName' registrada — roda sozinha a cada logon, elevada, sem pedir senha de novo."
    Write-Host "Rodando uma vez agora pra já deixar o proxy atualizado..."
}

$wslIp = (wsl hostname -I).Trim().Split(" ")[0]
if ([string]::IsNullOrWhiteSpace($wslIp)) {
    Write-Error "Não consegui detectar o IP do WSL. O WSL está rodando?"
    exit 1
}
Write-Host "IP interno do WSL: $wslIp"

$ports = @($GamePort)
if ($TxAdmin) { $ports += $TxAdminPort }

foreach ($port in $ports) {
    foreach ($proto in @("tcp", "udp")) {
        netsh interface portproxy delete v4tov4 listenport=$port listenaddress=0.0.0.0 protocol=$proto | Out-Null
        netsh interface portproxy add v4tov4 listenport=$port listenaddress=0.0.0.0 connectport=$port connectaddress=$wslIp protocol=$proto | Out-Null
        Write-Host "Portproxy $proto/$port -> ${wslIp}:$port OK"
    }

    $ruleName = "Labafero FXServer $port"
    if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port | Out-Null
        New-NetFirewallRule -DisplayName "$ruleName (UDP)" -Direction Inbound -Action Allow -Protocol UDP -LocalPort $port | Out-Null
        Write-Host "Regra de firewall criada para a porta $port (TCP+UDP)"
    } else {
        Write-Host "Regra de firewall para a porta $port já existe"
    }
}

$lanIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" -and $_.InterfaceAlias -notmatch "WSL|Loopback"
} | Select-Object -First 1 -ExpandProperty IPAddress)

Write-Host ""
Write-Host "Pronto. Outras máquinas na rede local conectam em: connect ${lanIp}:${GamePort}"
netsh interface portproxy show all
