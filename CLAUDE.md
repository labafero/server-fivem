# CLAUDE.md

Este arquivo fornece orientações ao Claude Code (claude.ai/code) ao trabalhar com código neste repositório.

## Status do projeto

Fase 0 em andamento. Já existem: monorepo pnpm + Turborepo (`package.json`, `pnpm-workspace.yaml`, `turbo.json`), lint/format compartilhado (`eslint.config.js`, `.prettierrc.json`), e os scripts `scripts/download-fxserver.sh` / `scripts/setup-db.sh` (ver "Comandos" abaixo). `packages/` e `resources/` ainda estão vazios (`.gitkeep`) — só serão populados nas Fases 1–2. Nenhum resource do QBCore foi instalado ainda.

## Comandos

```bash
pnpm install                    # instala devDependencies do monorepo (turbo, eslint, prettier)
pnpm lint                       # turbo run lint em todos os pacotes
./scripts/download-fxserver.sh  # baixa o build recomendado do FXServer (Linux) em server/ (gitignored); txAdmin já vem incluso
./scripts/setup-db.sh           # instala/configura MySQL/MariaDB nativo + cria db/user qbcore; precisa de sudo interativo, rode direto no terminal (não via automação sem TTY)
```

`server.cfg.example` na raiz documenta os convars mínimos (`sv_licenseKey`, `mysql_connection_string`) — copie para `server/server.cfg` (gitignored) antes de subir o servidor.

## O que é este projeto

Labafero Roleplay é um servidor de GTA V (FiveM) de roleplay construído sobre o QBCore. O objetivo é manter o core do QBCore atualizável a partir do upstream, ao mesmo tempo em que se adiciona uma UI Vue 3 customizada e de alta performance por cima dele, além de sistemas de roleplay proprietários — sem fazer fork ou modificar o Lua do QBCore diretamente.

## Arquitetura planejada (a partir do PRD.md)

- **Monorepo**: pnpm + Turborepo, unificando os resources do FXServer, pacotes de UI e ferramentas de CLI internas. O desenvolvimento acontece inteiramente dentro do WSL (Ubuntu, sistema de arquivos ext4) para I/O rápido com o binário Linux do FXServer.
- **Labafero CLI**: uma ferramenta Node.js privada (planejada em `packages/cli`) que gerencia as dependências de resources do QBCore e cria symlinks no diretório `resources` do FXServer, mantendo o código vendorizado do QBCore intocado e mergeável com o upstream.
- **Sistema de override explícito**: um manifesto `labafero.json` mapeia arquivos `.html`/`.js` nativos de UI do QBCore para componentes Vue 3 locais. A CLI compila os componentes Vue e substitui a saída compilada sobre os arquivos NUI nativos do QBCore no momento do build, deixando a lógica de jogo em Lua intocada para que as atualizações do upstream continuem sendo aplicadas sem conflitos.
- **Stack de NUI**: Vue 3 + Vite + Tailwind CSS (planejado em `packages/nui-core` e pacotes de UI por feature). O código frontend de NUI não deve conter condicionais de ambiente (ex.: `if dev`) — o mesmo build é usado tanto no jogo quanto no navegador.
- **Mocking de rede em modo dev**: o Mock Service Worker (MSW) intercepta as rotas NUI virtuais do jogo, permitindo construir e testar os painéis em um navegador comum sem precisar abrir o GTA V.

## Roadmap (define a ordem de construção — não pule etapas)

1. **Fase 0**: Configurar a estrutura de diretórios do monorepo no WSL, inicializar o Turborepo com configuração compartilhada de ESLint/Prettier, baixar o artefato do FXServer (Linux), instalar o txAdmin e configurar o banco de dados MySQL/MariaDB nativo via script de setup.
2. **Fase 1**: Instalar os resources core do QBCore manualmente (validar chaves de licença/conexão) para obter um servidor base estável e não modificado; construir a UI de loading/introdução com sound design customizado; validar o fluxo de entrada de jogadores e o resmon no servidor "cru".
3. **Fase 2**: Construir `packages/cli` e `packages/nui-core`; definir o dicionário de rotas do `labafero.json`; migrar o gerenciamento de resources do QBCore para a CLI (atualizações automatizadas + geração de symlinks).
4. **Fase 3**: Construir o primeiro override em Vue 3 (ex.: UI de banco ou concessionária), configurar o MSW para simulação de backend no navegador, e validar de ponta a ponta o pipeline de build via CLI → injeção no QBCore → substituição in-game.
5. **Fase 4**: Construir sistemas backend (Lua) + frontend (Vue) exclusivos para as mecânicas de roleplay proprietárias, depois ajustar performance/resmon em todos os módulos ativos.

## Restrições importantes a preservar

- A lógica Lua do QBCore deve permanecer não modificada pelo sistema de override — apenas os assets de UI compilados (`.html`/`.js`) são substituídos, via o manifesto `labafero.json`, nunca editados manualmente no lugar.
- O código frontend de NUI permanece agnóstico de ambiente (sem branches `if dev`); o MSW cuida da separação dev/prod externamente.
- O fluxo de symlink/build orientado pela CLI é o que mantém o QBCore atualizável a partir do upstream — evite modificar diretamente os arquivos de resources vendorizados do QBCore mesmo para correções rápidas.

## Decisões de infraestrutura (Fase 0)

- **Banco de dados**: MySQL/MariaDB **nativo** no WSL, não Docker. A instalação/configuração deve ser feita por um **script de setup** versionado no repo (idempotente, reexecutável), não passos manuais avulsos.
- **Gerenciamento do FXServer**: via **txAdmin** (interface web oficial do FiveM) — não criar tooling próprio para start/stop/updates do servidor enquanto o txAdmin cobrir a necessidade.
