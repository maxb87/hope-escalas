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
  - Index com filtros (todas/pendentes/concluídas/canceladas) e botão “Cancelar”
  - Perfil do paciente: tabelas de pendentes e concluídas

## Notas operacionais

- Usar `docker compose down` (sem `-v`) para não apagar o volume `pgdata`.
- Migração de `results` cria índices apenas se não existirem (`index_exists?`).

## Próximas etapas

### Testes

- [ ] Model: validações de `ScaleResponse` (estrutura/itens faltantes), cálculo/`results`, policies
- [ ] Requests: `ScaleRequest` (criar/cancelar/filtrar) e `ScaleResponse` (criar/permissões)
- [ ] Feature: profissional (solicitar → paciente preenche → visualizar), paciente (pendentes → preencher)

### Regras de negócio

- [ ] Impedir múltiplas solicitações ativas da mesma escala por paciente
- [ ] (Opcional) expiração automática de solicitações antigas

### Notificações

- [ ] Alerta de pendências no login do paciente; notificar profissional na conclusão

### API / Integrações

- [ ] `api/v1/users` (index/show + autorização)
- [ ] Magic link (modelo/token, mailer, consumo)

### Observabilidade

- [ ] Lograge em produção (opcional em dev)
- [ ] `prometheus_exporter` simples

### UX / I18n

- [ ] UX de restore (opcional)
- [ ] Revisão final de textos pt‑BR

### Seeds / Dados

- [ ] Garantir que os seeds não sobrescrevem senhas existentes

## 📊 Implementação de Escalas (histórico)

- Modelo de domínio + migrações e associações concluídos
- Implementação BDI (itens, cálculo e `results:jsonb`)
- Controllers básicos + autorização ok
- Views e formulários de preenchimento em andamento
