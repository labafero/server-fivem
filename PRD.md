# Product Requirements Document (PRD): Labafero Roleplay

## 1. Visão do Produto

O **Labafero Roleplay** é um servidor de GTA V (FiveM) focado em imersão, performance e design de alto nível. O projeto visa entregar uma experiência de _roleplay_ fluida e visualmente coesa, substituindo interfaces genéricas por sistemas front-end modernos e integrando mecânicas exclusivas de interação. O servidor utilizará uma arquitetura interna robusta (Monorepo/CLI customizada) para manter a base oficial do QBCore sempre atualizada, garantindo estabilidade sem sacrificar a personalização avançada de UI/UX e _sound design_.

---

## 2. Objetivos e Sucesso

- **Fase v1 (Fundação e Identidade):** Subir o servidor base com QBCore, garantindo economia funcional e estabilidade. Estabelecer a primeira impressão do jogador com uma tela de _loading_ imersiva, utilizando trilha e efeitos sonoro.
- **Fase v2 (Revolução UI/UX):** Substituir gradualmente os painéis nativos do QBCore (inventário, banco, concessionária) por interfaces modernas construídas em Vue 3, mantendo alta performance de renderização no Chromium embutido.
- **Fase v3 (Sistemas Únicos e Addons):** Expandir as opções de _roleplay_ com sistemas proprietários. O grande marco será o desenvolvimento de mecânicas exclusivas, integrando regras de negócio complexas no _backend_ com interfaces reativas no _frontend_ para suportar as dinâmicas do servidor.

---

## 3. Infraestrutura e Tooling Interno

O desenvolvimento do servidor seguirá um padrão. Ele será gerido por um ecossistema interno construído para máxima produtividade.

- **Ambiente de Desenvolvimento:** 100% isolado no Ubuntu via WSL (ext4), garantindo I/O rápido para o motor do jogo (FXServer Linux).
- **Arquitetura Monorepo:** Gerenciado via pnpm e Turborepo, unificando o servidor, pacotes de interface e ferramentas de linha de comando.
- **Labafero CLI (Gerenciador Interno):** Uma ferramenta Node.js privada que gerencia as dependências do QBCore e aplica _symlinks_ no diretório de _resources_.
- **Sistema de Override Explícito:** Utilização de um manifesto (`labafero.json`) com um dicionário de rotas explícito. A CLI compila os componentes locais em Vue e substitui os arquivos `.html/.js` nativos do QBCore no momento do _build_, preservando a lógica Lua intacta para futuras atualizações _upstream_.

---

## 4. Padrões de Interface e Mocking (NUI)

- **Stack Visual:** Vue 3 puro, Vite e Tailwind CSS, aplicando boas práticas de separação de componentes.
- **Comunicação Limpa:** Isolamento da lógica de comunicação NUI. O código _frontend_ não conterá condicionais de ambiente (`if dev`).
- **Mocking de Rede:** Utilização do Mock Service Worker (MSW) para interceptar rotas virtuais do jogo durante o desenvolvimento no navegador, permitindo estilizar e testar os painéis customizados sem precisar abrir o GTA V.

---

## 5. Road Map de Desenvolvimento

### Fase 0: Setup do Motor e Ambiente

- Configurar o diretório do monorepo no sistema de arquivos do Linux (WSL).
- Inicializar o Turborepo com regras globais de ESLint e Prettier.
- Baixar o artefato do FXServer (Linux) e instalar o **txAdmin** para gerenciamento do servidor.
- Configurar o banco de dados **MySQL/MariaDB nativo** (sem Docker) via **script de setup** próprio, para instalação repetível.

### Fase 1: O Servidor Base e Atmosfera

- Instalar e configurar os repositórios _core_ do QBCore manualmente para validar chaves de licença e conexão.
- Criar a interface de introdução/loading, aplicando _sound design_ autoral.
- Validar a entrada de jogadores e o consumo de recursos (resmon) com o servidor "cru".

> **Desvio registrado (2026-08-05):** a interface de loading não foi construída como resource separado. Em vez disso, o núcleo mínimo da Fase 2 (`packages/cli` + sistema de override via `labafero.json`) foi adiantado e validado diretamente no `qb-loading` do QBCore — resource sem nenhum arquivo `.lua`, portanto de baixo risco pra provar o pipeline de override antes de aplicá-lo em resources com lógica Lua (Fase 3). Detalhes: `.omc/plans/2026-08-05-fase1-loading-override.md` e `CLAUDE.md`.

### Fase 2: Automação Interna (CLI)

- Construir os pacotes `packages/cli` e `packages/nui-core`.
- Criar o dicionário de rotas no `labafero.json`.
- Migrar a gestão dos _resources_ do QBCore para a CLI, automatizando as atualizações e a geração de _symlinks_.

> Núcleo mínimo (`packages/cli` com comando `override:build`, `labafero.json`) já adiantado na Fase 1. Falta: automação completa de dependências do QBCore + geração de symlinks, e `packages/nui-core` compartilhado (hoje há só `packages/ui-loading-screen`, autônomo).

### Fase 3: Overrides e UI/UX

- Criar o primeiro projeto Vue 3 no monorepo para substituir uma interface nativa (ex: Banco ou Concessionária).
- Configurar o MSW para simular o _backend_ em Lua durante o desenvolvimento no Chrome.
- Rodar o _build_ via CLI, injetar no QBCore e atestar a substituição _in-game_.

### Fase 4: Sistemas Exclusivos (O Diferencial)

- Desenvolver o _backend_ (Lua) e _frontend_ (Vue) de sistemas e locais de ações exclusivas do servidor.
- Criar mecânicas de _roleplay_ interativas atreladas a esses sistemas, utilizando todo o ecossistema de comunicação testado nas fases anteriores.
- Refinar performance web e _resmon_ de todos os módulos ativos.
