# Labafero Roleplay

Servidor de GTA V (FiveM) de roleplay construído sobre o [QBCore](https://github.com/qbcore-framework), com foco em imersão, performance e uma UI própria de alto nível. O core do QBCore é mantido intocado e atualizável a partir do upstream, enquanto uma camada de UI em Vue 3 e sistemas de roleplay proprietários são adicionados por cima, sem fork do Lua original.

> Status: pré-Fase 0 — apenas planejamento (`PRD.md`) até o momento, nenhum código de servidor ainda.

## Arquitetura

- **Monorepo**: pnpm + Turborepo, unificando resources do FXServer, pacotes de UI e a CLI interna. Desenvolvimento 100% em WSL (Ubuntu, ext4) para I/O rápido com o FXServer Linux.
- **Labafero CLI** (`packages/cli`): ferramenta Node.js privada que gerencia dependências de resources do QBCore e cria symlinks no diretório `resources`, mantendo o QBCore vendorizado pristino e mergeável com o upstream.
- **Sistema de override** (`labafero.json`): manifesto que mapeia arquivos `.html`/`.js` nativos do QBCore para componentes Vue 3 locais. A CLI compila e substitui os arquivos NUI no build, sem tocar na lógica Lua.
- **NUI** (`packages/nui-core` + pacotes por feature): Vue 3 + Vite + Tailwind CSS. Código frontend agnóstico de ambiente (sem `if dev`) — o dev/prod é resolvido externamente via MSW.

Detalhes completos em [`PRD.md`](./PRD.md) e orientações para o Claude Code em [`CLAUDE.md`](./CLAUDE.md).

## Roadmap

1. **Fase 0** — Setup do monorepo, Turborepo, ESLint/Prettier, download do FXServer (Linux), banco de dados local.
2. **Fase 1** — Servidor base QBCore, tela de loading/introdução com sound design, validação de entrada de jogadores e resmon.
3. **Fase 2** — `packages/cli` + `packages/nui-core`, dicionário de rotas do `labafero.json`, automação de updates/symlinks.
4. **Fase 3** — Primeiro override em Vue 3 (banco ou concessionária), MSW, pipeline build → injeção → validação in-game.
5. **Fase 4** — Sistemas exclusivos de backend (Lua) e frontend (Vue), tuning de performance/resmon.

## Restrições

- Lua do QBCore nunca é editado diretamente — apenas assets de UI compilados são substituídos via `labafero.json`.
- NUI frontend não tem condicionais de ambiente; MSW cuida do dev/prod.
- Gestão de resources do QBCore passa pela CLI (symlinks), nunca por edição manual dos vendorizados.
