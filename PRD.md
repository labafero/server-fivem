# Product Requirements Document (PRD): Labafero Roleplay

## 1. Visão do Produto
O **Labafero Roleplay** é um servidor de GTA V (FiveM) focado em imersão, performance e design de alto nível. O projeto visa entregar uma experiência de *roleplay* fluida e visualmente coesa, substituindo interfaces genéricas por sistemas front-end modernos e integrando mecânicas exclusivas de interação. O servidor utilizará uma arquitetura interna robusta (Monorepo/CLI customizada) para manter a base oficial do QBCore sempre atualizada, garantindo estabilidade sem sacrificar a personalização avançada de UI/UX e *sound design*.

---

## 2. Objetivos e Sucesso
*   **Fase v1 (Fundação e Identidade):** Subir o servidor base com QBCore, garantindo economia funcional e estabilidade. Estabelecer a primeira impressão do jogador com uma tela de *loading* imersiva, utilizando trilha e efeitos sonoro.
*   **Fase v2 (Revolução UI/UX):** Substituir gradualmente os painéis nativos do QBCore (inventário, banco, concessionária) por interfaces modernas construídas em Vue 3, mantendo alta performance de renderização no Chromium embutido.
*   **Fase v3 (Sistemas Únicos e Addons):** Expandir as opções de *roleplay* com sistemas proprietários. O grande marco será o desenvolvimento de mecânicas exclusivas, integrando regras de negócio complexas no *backend* com interfaces reativas no *frontend* para suportar as dinâmicas do servidor.

---

## 3. Infraestrutura e Tooling Interno
O desenvolvimento do servidor seguirá um padrão. Ele será gerido por um ecossistema interno construído para máxima produtividade.

*   **Ambiente de Desenvolvimento:** 100% isolado no Ubuntu via WSL (ext4), garantindo I/O rápido para o motor do jogo (FXServer Linux).
*   **Arquitetura Monorepo:** Gerenciado via pnpm e Turborepo, unificando o servidor, pacotes de interface e ferramentas de linha de comando.
*   **Labafero CLI (Gerenciador Interno):** Uma ferramenta Node.js privada que gerencia as dependências do QBCore e aplica *symlinks* no diretório de *resources*.
*   **Sistema de Override Explícito:** Utilização de um manifesto (`labafero.json`) com um dicionário de rotas explícito. A CLI compila os componentes locais em Vue e substitui os arquivos `.html/.js` nativos do QBCore no momento do *build*, preservando a lógica Lua intacta para futuras atualizações *upstream*.

---

## 4. Padrões de Interface e Mocking (NUI)
*   **Stack Visual:** Vue 3 puro, Vite e Tailwind CSS, aplicando boas práticas de separação de componentes.
*   **Comunicação Limpa:** Isolamento da lógica de comunicação NUI. O código *frontend* não conterá condicionais de ambiente (`if dev`). 
*   **Mocking de Rede:** Utilização do Mock Service Worker (MSW) para interceptar rotas virtuais do jogo durante o desenvolvimento no navegador, permitindo estilizar e testar os painéis customizados sem precisar abrir o GTA V.

---

## 5. Road Map de Desenvolvimento

### Fase 0: Setup do Motor e Ambiente
*   Configurar o diretório do monorepo no sistema de arquivos do Linux (WSL).
*   Inicializar o Turborepo com regras globais de ESLint e Prettier.
*   Baixar o artefato do FXServer (Linux) e configurar o banco de dados local.

### Fase 1: O Servidor Base e Atmosfera
*   Instalar e configurar os repositórios *core* do QBCore manualmente para validar chaves de licença e conexão.
*   Criar a interface de introdução/loading, aplicando *sound design* autoral.
*   Validar a entrada de jogadores e o consumo de recursos (resmon) com o servidor "cru".

### Fase 2: Automação Interna (CLI)
*   Construir os pacotes `packages/cli` e `packages/nui-core`.
*   Criar o dicionário de rotas no `labafero.json`.
*   Migrar a gestão dos *resources* do QBCore para a CLI, automatizando as atualizações e a geração de *symlinks*.

### Fase 3: Overrides e UI/UX
*   Criar o primeiro projeto Vue 3 no monorepo para substituir uma interface nativa (ex: Banco ou Concessionária).
*   Configurar o MSW para simular o *backend* em Lua durante o desenvolvimento no Chrome.
*   Rodar o *build* via CLI, injetar no QBCore e atestar a substituição *in-game*.

### Fase 4: Sistemas Exclusivos (O Diferencial)
*   Desenvolver o *backend* (Lua) e *frontend* (Vue) de sistemas e locais de ações exclusivas do servidor.
*   Criar mecânicas de *roleplay* interativas atreladas a esses sistemas, utilizando todo o ecossistema de comunicação testado nas fases anteriores.
*   Refinar performance web e *resmon* de todos os módulos ativos.
