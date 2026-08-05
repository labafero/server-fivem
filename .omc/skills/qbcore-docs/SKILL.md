---
name: qbcore-docs
description: Grounds any QBCore Lua work (exports, events, functions, database schema, jobs) and FXServer/txAdmin/native install setup in the real qbcore.net documentation instead of guessing from training memory. Trigger on QBCore, qb-core, export, RegisterNetEvent/RegisterServerEvent, native, item, job, txAdmin, FXServer install, or any Lua resource / server setup work in this project.
---

# QBCore Docs Grounding

Este projeto builda em cima do QBCore (ver `CLAUDE.md`/`PRD.md`). Nomes de export, eventos, funções e schema de banco do QBCore são fáceis de alucinar — mudam entre versões e há muita documentação desatualizada circulando. A doc oficial (`https://qbcore.net/docs/`) já foi indexada no `anchored` para consulta.

## Regra

Antes de escrever ou afirmar qualquer coisa sobre:

- um **export** do `qb-core` (ex.: `exports['qb-core']:GetCoreObject()`)
- um **evento** (`RegisterNetEvent`, `RegisterServerEvent`, `TriggerEvent`/`TriggerServerEvent` relacionados a QBCore)
- uma **function** de `QBCore.Functions.*` ou `QBCore.Shared.*`
- o **schema** de banco (`players`, `gangs`, `jobs`, etc.)
- estrutura de **jobs**/**items**
- passos de **instalação nativa** (Fase 0: FXServer Linux, txAdmin, script de setup do banco)

**consulte a base indexada primeiro** com `anchored_ctx_search`, nunca assuma a assinatura de memória. Se a busca não retornar nada relevante, isso é sinal de que a página não foi indexada ainda — use `anchored_fetch_and_index` na página correspondente de `qbcore.net/docs/` antes de prosseguir, em vez de inventar.

## Como consultar

```
anchored_ctx_search(queries: ["<o que você precisa saber>"], cwd: "<raiz do projeto>")
```

Fontes já indexadas (re-rodar `anchored_fetch_and_index` com `force: true` se suspeitar que estão desatualizadas):

- Client Events — `docs/api/client-events`
- Client Functions — `docs/api/client-functions`
- Server Events — `docs/api/server-events`
- Server Functions — `docs/api/server-functions`
- Commands — `docs/api/commands`
- Core Object — `docs/core/core-object`
- Core Events Reference — `docs/core/events`
- Core Functions Library — `docs/core/functions`
- Player Data — `docs/core/player-data`
- Core Database Schema — `docs/database/core-schema`
- Jobs — `docs/core-concepts/jobs`
- Linux Installation Tutorial (FXServer nativo + txAdmin) — `docs/installation/linux`
- Install QB-Core on Ubuntu/Debian — `docs/getting-started/linux-install`

Páginas ainda não indexadas (ex.: `advanced/*`, `guides/*`, `database/` além do core schema): busque com `anchored_ctx_search` primeiro; se vazio, faça `anchored_fetch_and_index` na URL específica em `qbcore.net/docs/...` antes de responder.

## O que NÃO fazer

- Não inventar nome de export/evento porque "parece certo" ou porque outro framework FiveM usa esse padrão.
- Não editar o Lua vendorizado do QBCore para "testar" uma assinatura — ver restrições em `CLAUDE.md` (override system via `labafero.json`, nunca hand-edit).
- Não sugerir Docker para o banco de dados nem tooling próprio no lugar do txAdmin — decisão já travada em `CLAUDE.md` (ver "Decisões de infraestrutura").
