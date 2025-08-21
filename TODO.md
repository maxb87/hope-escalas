# Checklist do Projeto (atualizado)

## Entregues

- Soft delete (Paranoia)

  - Migrações com `deleted_at` + índices (`users`, `patients`, `professionals`)
  - Models com `acts_as_paranoid`, endpoints de restore e specs
  - (UX opcional do botão “Restaurar” ainda pendente)

- Autorização (Pundit)

  - `ApplicationController` com Pundit e verificações
  - Policies: `Patient`, `Professional`, `ScaleRequest`, `ScaleResponse`, `Dashboards` (+ `Scope`)
  - Controllers usando `authorize`/`policy_scope`

- Autenticação (Devise)

  - Primeiro login exige troca de senha (`force_password_reset`)
  - `Users::RegistrationsController`: troca sem senha atual no primeiro login, limpa flag, `bypass_sign_in`
  - `:lockable` habilitado (3 tentativas, 5min) e UX de mensagens (I18n pt‑BR, incl. `registrations.updated`)
  - Redirecionamento pós‑login por perfil (admin/profissional → lista de pacientes; paciente → próprio perfil)

- Escalas (BDI – MVP)

  - Modelos: `PsychometricScale`, `PsychometricScaleItem`, `ScaleRequest`, `ScaleResponse`
  - Seeds: BDI com 21 itens (0–3)
  - Formulário `ScaleResponses#new` com exibição de erros (422)
  - `results:jsonb` em `ScaleResponse` (+ `results_schema_version`, `computed_at`, índices GIN)
  - Serviço `Scoring::BDI` e integração no model (preenche `results` e campos legados)
  - `show` exibe métricas/subescalas para profissional/admin; paciente não vê resultados

- Solicitações de escalas
  - `new/create`: associa profissional logado, redireciona ao perfil do paciente
  - Index com filtros (todas/pendentes/concluídas/canceladas) e ações (ver/cancelar)
  - Perfil do paciente: tabelas de pendentes e concluídas com informações detalhadas
- Visualização de escalas (Admin/Profissionais)
  - Interface moderna com navegação por abas (Turbo Frames)
  - Contadores precisos por status com badges coloridos
  - Tabela detalhada com avatar, status visual, resultados e ações
  - Página de detalhes da solicitação com layout card-based
  - Botão "Solicitar Preenchimento" posicionado no header

## Notas operacionais

- Usar `docker compose down` (sem `-v`) para não apagar o volume `pgdata`.
- Migração de `results` cria índices apenas se não existirem (`index_exists?`).

## Melhorias Técnicas Implementadas

- **Turbo Rails & UX Moderna**

  - Navegação por abas com carregamento dinâmico (Turbo Frames)
  - Actions que escapam do frame (`data: { turbo_frame: "_top" }`)
  - Interface responsiva com Bootstrap e ícones Bootstrap Icons
  - Estados visuais claros (badges, avatars, hover effects)

- **Validações e Segurança**

  - Políticas Pundit robustas com verificações múltiplas
  - Validações no modelo, controller e policy
  - Redirecionamentos inteligentes com `redirect_back_or_to`
  - Mensagens de erro contextuais e traduzidas

- **Performance e Dados**

  - Eager loading com `.includes()` para evitar N+1 queries
  - Método `interpretation_level` público para acesso aos resultados
  - Contadores eficientes com queries otimizadas
  - Estrutura `results:jsonb` para flexibilidade

- **Internacionalização**
  - Traduções completas em pt-BR para toda a interface
  - Mensagens de erro personalizadas e contextuais
  - Formatação de datas e pluralização adequadas

## Próximas etapas

### 🔥 PRIORIDADE 1 - Estabilidade e Testes (MVP Core)

- [x] **Menu Lateral**

  - [x] Implementar menu lateral esquerdo moderno e responsivo
  - [x] Substituir navbar atual por layout com sidebar
  - [x] Adicionar ícones e texto para cada item do menu
  - [x] Implementar toggle para mobile (hamburger menu)
  - [x] Manter funcionalidade de navegação intacta
  - [x] Design responsivo para desktop e mobile

- [ ] **Filtros e Busca de Pacientes**

  - [ ] Implementar filtros para exibição de pacientes:
    - [ ] Ordenação alfabética (A-Z, Z-A)
    - [ ] Ordenação por idade (mais novo, mais velho)
    - [ ] Ordenação por escalas pendentes (mais, menos)
  - [ ] Implementar busca dinâmica em tempo real:
    - [ ] Busca pelo nome do paciente
    - [ ] Interface responsiva com autocomplete
    - [ ] Debounce para otimizar performance
    - [ ] Filtros combinados (busca + ordenação)

- [ ] **Cobertura de Testes (Meta: ≥90%)**

  - [ ] **Model Specs**: Adicionar/expandir validações, associações e regras de negócio.
    - [ ] `ScaleRequest`: Prevenção de duplicatas ativas.
    - [ ] `ScaleResponse`: Validação da estrutura `results`, itens obrigatórios.
    - [ ] `User`/`Patient`/`Professional`: Associações e `dependent` rules.
  - [ ] **Request Specs**: Garantir fluxos de CRUD, autorização e casos de falha.
    - [ ] `ScaleRequestsController`: Acesso restrito a profissionais/admins.
    - [ ] `ScaleResponsesController`: Acesso restrito a pacientes e validações de input.
  - [ ] **Policy Specs**: Cobertura completa das regras de Pundit para todos os papéis.
  - [ ] **Feature Specs**: Testar fluxos de ponta a ponta.
    - [ ] Fluxo principal: Profissional solicita → Paciente preenche → Profissional vê resultados.

- [ ] **Integridade de Dados (Nível Banco de Dados)**

  - [ ] Adicionar `foreign_key_constraints` e `null: false` onde aplicável.
  - [ ] Adicionar índice único composto parcial em `scale_requests` (`patient_id`, `psychometric_scale_id`, `status='pending'`) para garantir uma única solicitação ativa.
  - [ ] Implementar `CHECK constraint` para status em `scale_requests` e `scale_responses`.
  - [ ] Adicionar validação customizada para a estrutura do JSONB `results` no `ScaleResponse`.

- [ ] **Refatoração e Boas Práticas**
  - [ ] **Controllers**: Manter controllers "magros" (skinny).
    - [ ] Mover lógica de negócio para models/serviços.
    - [ ] Envolver `create`/`update` em transações (`ApplicationRecord.transaction`).
    - [ ] Auditar `strong_params` em todos os controllers.
  - [ ] **Models**: Centralizar regras de negócio.
    - [ ] Criar scopes (`.pending`, `.completed`) para consultas comuns.
    - [ ] Garantir que `Scoring::BDI` seja idempotente e totalmente testado.
    - [ ] Cálculo de `results` e `computed_at` deve ser atômico no `ScaleResponse`.
  - [ ] **Segurança**:
    - [ ] Auditar `before_action :authenticate_user!`, `policy_scope` e `authorize` em todos os controllers.
    - [ ] Revisar Content Security Policy (`config/initializers/content_security_policy.rb`).
    - [ ] Confirmar que Devise (`:lockable`, reset de senha) está configurado corretamente.

### 📈 Funcionalidades (Pós-MVP)

- [ ] **Fluxo para refazer uma solicitação de preenchimento**
  - [ ] Opção "Solicitar Novamente" que cancela a anterior automaticamente.
  - [ ] Manter histórico das solicitações canceladas.
- [ ] **Notificações para profissionais quando escalas são completadas**
  - [ ] Callback no `ScaleResponse` após criação para disparar notificação.
  - [ ] Sistema de notificações internas ou por email (a definir).

### 🔧 Melhorias Técnicas (Contínuas)

- [ ] **Performance**
  - [ ] Auditar e corrigir N+1 queries com `bullet` e `includes()`.
  - [ ] Adicionar índices em colunas usadas para filtros e ordenação.
- [ ] **Internacionalização (I18n)**
  - [ ] Auditar todas as strings da UI para garantir que estão no `pt-BR.yml`.
  - [ ] Unificar mensagens de flash e validação.
- [ ] **Tooling e Ambiente**
  - [ ] Sincronizar `README.md` com as versões de Node/Ruby/`mise` e comandos `yarn`.
  - [ ] Remover `package-lock.json` para forçar uso do `yarn.lock`.
  - [ ] Configurar linters para ignorar `README.md` e `TODO.md`.
- [ ] **Seeds**
  - [ ] Tornar seeds idempotentes (`find_or_create_by`) para evitar duplicatas.
- [ ] **Observabilidade**
  - [ ] Configurar `Lograge` para logs estruturados em produção.
  - [ ] Expor endpoint básico de métricas com `prometheus_exporter`.

## 📊 Estado Atual da Aplicação

### ✅ Core Funcional (100% Completo)

- **Domínio**: Modelos, migrações, associações e soft delete
- **BDI**: 21 itens, cálculo automático, interpretação visual
- **Autenticação**: Devise com lockable e primeiro login
- **Autorização**: Pundit com policies robustas
- **Solicitações**: CRUD completo com filtros e cancelamento
- **Escalas**: Preenchimento, validação e cálculo de resultados

### ✅ Interface Moderna (100% Completo)

- **Admin/Profissional**: Visualização completa com Turbo
- **Paciente**: Dashboard com notificações e cards
- **Responsividade**: Bootstrap com componentes modernos
- **UX**: Estados visuais, confirmações e feedback

### ✅ Regras de Negócio Críticas (90% Completo)

- **Duplicatas**: Prevenção de solicitações múltiplas ✅
- **Acesso**: Restrição de preenchimento por status ✅
- **Notificações**: Sistema completo para pacientes ✅

### 🎯 Próximas Prioridades

1. **Testes**: Cobertura completa das funcionalidades
2. **Fluxo Refazer**: Cancelar anterior + nova solicitação
3. **Notificações**: Sistema para profissionais
4. **Segunda Escala**: BAI (Ansiedade)
