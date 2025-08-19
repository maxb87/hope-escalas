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
  - Redirecionamento pós‑login por perfil (admin/profissional → pacientes; paciente → próprio perfil)

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

### ✅ CONCLUÍDO - Regras de Negócio Críticas

- [x] **Impedir múltiplas solicitações ativas da mesma escala por paciente**

  - ✅ Validação no modelo `ScaleRequest` com método `unique_active_request_per_patient_and_scale`
  - ✅ Verificação antes de criar nova solicitação
  - ✅ Mensagem de erro personalizada na UI em pt-BR

- [x] **Permitir paciente preencher escala somente quando solicitação estiver em aberto**

  - ✅ Validação na policy `ScaleRequestPolicy#respond?`
  - ✅ Validação dupla no controller `ScaleResponsesController` (new/create)
  - ✅ Redirecionamento com mensagens de erro claras
  - ✅ Interface adaptativa (botões condicionais)

- [x] **Alertas de pendências no login do paciente**
  - ✅ Contador visual no dashboard com badge de status
  - ✅ Notificação destacada após login (alert dismissível)
  - ✅ Badge na navbar com contagem de pendentes
  - ✅ Layout modernizado com cards para escalas

### 🔥 PRIORIDADE 1 - Funcionalidades Restantes

- [ ] **Fluxo para refazer uma solicitação de preenchimento**

  - Opção "Solicitar Novamente" que cancela a anterior automaticamente
  - Quando profissional solicita escala já pendente, oferece substituir
  - Manter histórico das solicitações canceladas

- [ ] **Notificações para profissionais quando escalas são completadas**
  - Callback no `ScaleResponse` após criação
  - Sistema de notificações internas ou email
  - Dashboard do profissional com indicadores

### 🧪 Testes (Prioridade Alta)

- [ ] **Model Tests**: Validações de `ScaleResponse` (estrutura/itens faltantes), `ScaleRequest` (duplicatas)
- [ ] **Request Tests**: CRUD completo de `ScaleRequest` e `ScaleResponse` com autorização
- [ ] **Feature Tests**: Fluxos completos (profissional → paciente → resultados)
- [ ] **Policy Tests**: Cobertura completa das regras de autorização

### 📈 Funcionalidades Avançadas (Futuro)

- [ ] **Segunda Escala Psicométrica**

  - Implementar BAI (Inventário de Ansiedade de Beck)
  - Serviço `Scoring::BAI` com interpretação
  - Selector de escala na interface

- [ ] **Relatórios e Analytics**

  - Dashboard com estatísticas de uso
  - Relatórios por período e profissional
  - Exportação em PDF/Excel

- [ ] **Notificações por Email**
  - Templates responsivos para pacientes
  - Lembretes automáticos de escalas pendentes
  - Confirmações de preenchimento

### 🔧 Melhorias Técnicas (Secundárias)

- [ ] **Regras de Negócio**

  - Expiração automática de solicitações antigas
  - Histórico detalhado de alterações
  - Soft delete com restore UI

- [ ] **API REST**

  - Endpoints `api/v1/scale_requests` e `api/v1/scale_responses`
  - Autenticação via token
  - Documentação com Swagger

- [ ] **Observabilidade**

  - Lograge em produção
  - Métricas com Prometheus
  - Health checks detalhados

- [ ] **Polimentos**
  - Revisão final de textos pt-BR
  - Seeds que não sobrescrevem dados existentes
  - Otimizações de performance

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
- **Refazer**: Fluxo para nova solicitação (pendente)
- **Profissionais**: Alertas de conclusão (pendente)

### 🎯 Próximas Prioridades

1. **Testes**: Cobertura completa das funcionalidades
2. **Fluxo Refazer**: Cancelar anterior + nova solicitação
3. **Notificações**: Sistema para profissionais
4. **Segunda Escala**: BAI (Ansiedade)
