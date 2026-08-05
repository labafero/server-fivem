# CLAUDE.md

Este arquivo fornece orientações ao Claude Code (claude.ai/code) ao trabalhar com código neste repositório.

## Status do projeto

Fase 0 concluída. Fase 1 em andamento, com o núcleo mínimo da Fase 2 adiantado (ver nota no Roadmap abaixo). Já existem: monorepo pnpm + Turborepo (`package.json`, `pnpm-workspace.yaml`, `turbo.json`), lint/format compartilhado (`eslint.config.js`, `.prettierrc.json`), os scripts `scripts/download-fxserver.sh` / `scripts/setup-db.sh` / `scripts/install-qbcore.sh` (ver "Comandos" abaixo), os resources core do QBCore instalados em `server/resources/` (gitignored), `packages/cli` (`@labafero/cli`, comando `override:build`) e `packages/ui-loading-screen` (`@labafero/ui-loading-screen`, Vue 3 + Vite + Tailwind), e o manifesto `labafero.json` mapeando o loading screen (`qb-loading`) pra esse pacote (ver "Sistema de override" abaixo).

**Pendente de validação manual (fora do alcance do agente, precisa do cliente FiveM/Windows):** subir o servidor via txAdmin e confirmar que `sv_licenseKey`/`mysql_connection_string` funcionam de fato, entrar com um personagem e validar spawn/resmon no servidor "cru", e confirmar visual/audio da tela de loading customizada in-game depois de rodar `override:build`. Os assets reais de áudio (intro) e imagens (slideshow) também ainda não foram fornecidos — o componente usa placeholders.

## Comandos

```bash
pnpm install                    # instala devDependencies do monorepo (turbo, eslint, prettier)
pnpm lint                       # turbo run lint em todos os pacotes
./scripts/download-fxserver.sh  # baixa o build recomendado do FXServer (Linux) em server/ (gitignored); txAdmin já vem incluso
./scripts/setup-db.sh           # instala/configura MySQL/MariaDB nativo + cria db/user qbcore; precisa de sudo interativo, rode direto no terminal (não via automação sem TTY)
./scripts/link-cli.sh           # linka `labafero` no bin global do pnpm (rode 1x por máquina/setup); depois disso use direto: labafero override:build
labafero override:build         # builda os pacotes de UI mapeados em labafero.json e sobrescreve os arquivos NUI nativos do QBCore correspondentes (sem o link, use: node packages/cli/bin/labafero.js override:build)
labafero override:restore       # restaura os arquivos nativos originais do QBCore a partir do backup (ver seção "Sistema de override" abaixo)
```

`server.cfg.example` na raiz documenta os convars mínimos (`sv_licenseKey`, `mysql_connection_string`) — copie para `server/server.cfg` (gitignored) antes de subir o servidor.

Pra acesso via LAN (outra máquina na rede local jogando), rode no Windows (PowerShell, como Administrador):

```powershell
powershell -ExecutionPolicy Bypass -File scripts\windows\setup-portproxy.ps1
```

## O que é este projeto

Labafero Roleplay é um servidor de GTA V (FiveM) de roleplay construído sobre o QBCore. O objetivo é manter o core do QBCore atualizável a partir do upstream, ao mesmo tempo em que se adiciona uma UI Vue 3 customizada e de alta performance por cima dele, além de sistemas de roleplay proprietários — sem fazer fork ou modificar o Lua do QBCore diretamente.

## Arquitetura planejada (a partir do PRD.md)

- **Monorepo**: pnpm + Turborepo, unificando os resources do FXServer, pacotes de UI e ferramentas de CLI internas. O desenvolvimento acontece inteiramente dentro do WSL (Ubuntu, sistema de arquivos ext4) para I/O rápido com o binário Linux do FXServer.
- **Labafero CLI**: uma ferramenta Node.js privada (planejada em `packages/cli`) que gerencia as dependências de resources do QBCore e cria symlinks no diretório `resources` do FXServer, mantendo o código vendorizado do QBCore intocado e mergeável com o upstream.
- **Sistema de override explícito**: um manifesto `labafero.json` mapeia arquivos `.html`/`.js` nativos de UI do QBCore para componentes Vue 3 locais. A CLI compila os componentes Vue e substitui a saída compilada sobre os arquivos NUI nativos do QBCore no momento do build, deixando a lógica de jogo em Lua intocada para que as atualizações do upstream continuem sendo aplicadas sem conflitos.
- **Stack de NUI**: Vue 3 + Vite + Tailwind CSS (planejado em `packages/nui-core` e pacotes de UI por feature). O código frontend de NUI não deve conter condicionais de ambiente (ex.: `if dev`) — o mesmo build é usado tanto no jogo quanto no navegador.
- **Mocking de rede em modo dev**: o Mock Service Worker (MSW) intercepta as rotas NUI virtuais do jogo, permitindo construir e testar os painéis em um navegador comum sem precisar abrir o GTA V.

## Sistema de override (labafero.json)

O manifesto `labafero.json` na raiz do repo lista rotas de override. Cada rota tem:

- `package`: caminho do pacote de UI local (ex. `packages/ui-loading-screen`) que builda via Vite.
- `target.resource`: diretório do resource vendorizado do QBCore cujos arquivos serão sobrescritos (ex. `server/resources/[qb]/qb-loading/html`).
- `target.files`: mapa `caminho-relativo-de-destino (dentro de target.resource) -> caminho relativo no dist/ do pacote`. O valor pode ser uma string (arquivo obrigatório — erro se faltar) ou um objeto `{ path, optional: true }` (arquivo opcional — se ainda não existir no dist/, `override:build`/`override:restore` pulam com um aviso em vez de falhar; útil pra assets autorais, ex. áudio, que o usuário ainda não forneceu).

O comando `override:build` do `packages/cli` (ver "Comandos") lê esse manifesto, builda cada pacote mapeado e sobrescreve os arquivos de destino. Sempre reexecutar esse comando depois de reinstalar/atualizar o resource vendorizado correspondente (ex. depois de rodar `scripts/install-qbcore.sh` de novo), senão a customização se perde no próximo clone/update.

**Backup e restore (inspirado no `pnpm patch`):** como o `loadscreen`/NUI do FiveM não tem nenhum mecanismo nativo de overlay em runtime — a única forma de trocar a UI é reescrevendo o arquivo físico do resource —, `override:build` sobrescreve o arquivo original de verdade no disco. Pra não perder o original, na PRIMEIRA vez que uma rota é aplicada o comando salva uma cópia dos arquivos como estavam antes em `.labafero/backups/<route-id>/` (gitignored, local à máquina). Rodadas seguintes de `override:build` não tocam mais nesse backup. `labafero override:restore` copia o backup de volta por cima dos arquivos do resource, revertendo pro visual nativo do QBCore sem precisar reinstalar nada. Se o backup nunca foi criado (resource nunca teve override aplicado) ou foi apagado, o `override:restore` falha com uma mensagem clara — nesse caso, reinstale o resource original via `scripts/install-qbcore.sh`.

## Roadmap (define a ordem de construção — não pule etapas)

1. **Fase 0**: Configurar a estrutura de diretórios do monorepo no WSL, inicializar o Turborepo com configuração compartilhada de ESLint/Prettier, baixar o artefato do FXServer (Linux), instalar o txAdmin e configurar o banco de dados MySQL/MariaDB nativo via script de setup.
2. **Fase 1**: Instalar os resources core do QBCore manualmente (validar chaves de licença/conexão) para obter um servidor base estável e não modificado; construir a UI de loading/introdução com sound design customizado; validar o fluxo de entrada de jogadores e o resmon no servidor "cru".
   - **Desvio registrado (2026-08-05):** a UI de loading não foi feita como resource separado (`labafero-intro`, abandonado). Em vez disso, adiantou-se o núcleo mínimo da Fase 2 (`packages/cli` + sistema de override via `labafero.json`) e usou-se o `qb-loading` do próprio QBCore como primeiro alvo de override — ele não tem nenhum arquivo `.lua`, então é um alvo de baixo risco pra validar o pipeline de override antes de aplicá-lo em resources com lógica Lua (Fase 3). O restante da Fase 2 (automação completa de dependências do QBCore + geração de symlinks) continua pendente. Plano completo: `.omc/plans/2026-08-05-fase1-loading-override.md`.
3. **Fase 2**: Construir `packages/cli` e `packages/nui-core`; definir o dicionário de rotas do `labafero.json`; migrar o gerenciamento de resources do QBCore para a CLI (atualizações automatizadas + geração de symlinks). (núcleo mínimo já adiantado na Fase 1, ver nota acima — falta a automação completa de dependências/symlinks)
4. **Fase 3**: Construir o primeiro override em Vue 3 (ex.: UI de banco ou concessionária), configurar o MSW para simulação de backend no navegador, e validar de ponta a ponta o pipeline de build via CLI → injeção no QBCore → substituição in-game.
5. **Fase 4**: Construir sistemas backend (Lua) + frontend (Vue) exclusivos para as mecânicas de roleplay proprietárias, depois ajustar performance/resmon em todos os módulos ativos.

## Restrições importantes a preservar

- A lógica Lua do QBCore deve permanecer não modificada pelo sistema de override — apenas os assets de UI compilados (`.html`/`.js`) são substituídos, via o manifesto `labafero.json`, nunca editados manualmente no lugar.
- O código frontend de NUI permanece agnóstico de ambiente (sem branches `if dev`); o MSW cuida da separação dev/prod externamente.
- O fluxo de symlink/build orientado pela CLI é o que mantém o QBCore atualizável a partir do upstream — evite modificar diretamente os arquivos de resources vendorizados do QBCore mesmo para correções rápidas.

## Decisões de infraestrutura (Fase 0)

- **Banco de dados**: MySQL/MariaDB **nativo** no WSL, não Docker. A instalação/configuração deve ser feita por um **script de setup** versionado no repo (idempotente, reexecutável), não passos manuais avulsos.
- **Gerenciamento do FXServer**: via **txAdmin** (interface web oficial do FiveM) — não criar tooling próprio para start/stop/updates do servidor enquanto o txAdmin cobrir a necessidade.
- **Rede (WSL2 em modo NAT)**: mantido em NAT — decisão explícita de não migrar para `networkingMode=mirrored` no `.wslconfig`, para não afetar outras aplicações já ancoradas no NAT atual. Acesso ao FXServer (porta 30120):
  - Da própria máquina Windows: `connect localhost:30120` funciona direto (WSL2 já encaminha `localhost` automaticamente).
  - De outra máquina na rede local: precisa do `scripts/windows/setup-portproxy.ps1` (roda no Windows como Administrador) — cria/atualiza `netsh interface portproxy` + regras de firewall apontando para o IP interno do WSL, que muda a cada reboot. Reexecutar o script sempre que for jogar em LAN após reiniciar o WSL.
  - Exposição externa (internet/lista pública de servidores) ainda não configurada — precisaria de port forward no roteador, fora do escopo atual.
