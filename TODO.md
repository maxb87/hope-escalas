# Checklist atualizado

[x] Soft delete (Paranoia) para patients e professionals
[x] Migrações: deleted_at:datetime + índices em users, patients, professionals
[x] Modelos com acts_as_paranoid
[ ] UX de "Restaurar" item (opcional)
[x] Specs de soft delete/restore (models e requests)
[x] Endpoints de restore em patients e professionals
[x] Requests: index não lista deletados; show de deletado 404; restore funciona
[x] Autorização com Pundit
[x] Incluir Pundit::Authorization e callbacks no ApplicationController
[x] PatientPolicy, ProfessionalPolicy e DashboardsPolicy (+ Scope)
[x] Usar authorize/policy_scope nos controllers (Patients/Professionals/Dashboards)
[ ] Specs de policies/authorization
[x] Devise: primeiro login exige troca de senha
[x] users.force_password_reset:boolean, null:false, default:false
[x] Enforce redirect para edit_user_registration_path quando flag = true
[x] Users::RegistrationsController: troca sem senha atual no primeiro login, limpa flag, bypass_sign_in
[x] View registrations#edit: esconder e-mail e senha atual durante reset forçado
[x] I18n básico para mensagens
[x] Redirecionamento pós-login por perfil (admin/profissional → lista de pacientes; paciente → próprio perfil)
[ ] Opcional: habilitar :confirmable/:lockable
[x] Segurança de login (bloqueio após tentativas) - IMPLEMENTADO E FUNCIONANDO

- [x] Habilitar Devise `:lockable` no `User`
- [x] Adicionar colunas na migração create users (ou nova migração se já aplicado):
  - `failed_attempts:integer, default: 0, null: false`
  - `unlock_token:string`
  - `locked_at:datetime`
- [x] Configurar em `config/initializers/devise.rb`:
  - `config.lock_strategy = :failed_attempts`
  - `config.unlock_strategy = :time`
  - `config.maximum_attempts = 3`
  - `config.unlock_in = 5.minutes`
  - `config.last_attempt_warning = true`
- [x] UX: mensagens na tela de login para bloqueio e aviso na última tentativa
- [x] Specs: bloqueio após 3 erros e desbloqueio automático após 5 minutos
- [x] INVESTIGAR: Por que as mensagens personalizadas não aparecem na interface
  - [x] Verificar se o Devise está sobrescrevendo as mensagens
  - [x] Testar diferentes abordagens (controller vs view)
  - [x] Verificar configurações do Warden/failure_app
  - [x] Implementar fallback para mensagens genéricas
        [ ] API api/v1/users
        [ ] Controller index/show + Jbuilder
        [ ] Autenticação/autorização
        [ ] Specs de requests
        [ ] Magic link
        [ ] Model MagicLinkToken, service, mailer, rotas e controller de consumo
        [ ] Specs do ciclo (emitir/consumir/expirar)
        [~] Seeds/admin
        [x] Admin e exemplos Professional/Patient com User (dev)
        [ ] Revisar/ajustar dados finais conforme regras de autorização/magic link
        [ ] Testes
        [ ] Models (associações/validações)
        [ ] Requests (CRUD + Pundit)
        [ ] API e primeiro login
        [ ] Meta de cobertura
        [ ] Observabilidade
        [ ] Lograge em produção (e opcional em dev)
        [ ] Prometheus exporter simples

## 📊 IMPLEMENTAÇÃO DE ESCALAS PSICOMÉTRICAS

### Modelo de Domínio - Escalas Psicométricas

[ ] **Model `PsychometricScale`**

- `name:string, null: false` - Nome da escala (ex: "Inventário de Depressão de Beck")
- `code:string, null: false` - Código único (ex: "BDI")
- `description:text` - Descrição da escala
- `version:string` - Versão da escala
- `is_active:boolean, default: true` - Se está disponível para solicitação
- `deleted_at:datetime` - Soft delete
- Validações: name e code únicos, code em maiúsculas

[ ] **Model `ScaleRequest`**

- `patient:references, null: false` - Paciente solicitado
- `professional:references, null: false` - Profissional que solicitou
- `psychometric_scale:references, null: false` - Escala solicitada
- `status:integer, default: 0` - Status (pending, completed, expired, cancelled)
- `requested_at:datetime, null: false` - Data/hora da solicitação
- `completed_at:datetime` - Data/hora do preenchimento
- `expires_at:datetime` - Data/hora de expiração (MVP: desabilitado)
- `notes:text` - Observações do profissional
- `deleted_at:datetime` - Soft delete
- Validações: expires_at > requested_at, status válido (MVP: desabilitado)

[ ] **Model `ScaleResponse`**

- `scale_request:references, null: false` - Solicitação relacionada
- `patient:references, null: false` - Paciente que respondeu
- `psychometric_scale:references, null: false` - Escala respondida
- `answers:jsonb` - Respostas do paciente (estrutura específica por escala)
- `total_score:integer` - Pontuação total calculada
- `interpretation:string` - Interpretação baseada na pontuação
- `completed_at:datetime, null: false` - Data/hora do preenchimento
- `deleted_at:datetime` - Soft delete
- Validações: answers não vazio, total_score calculado

[ ] **Associações**

- `PsychometricScale` has_many `ScaleRequest`
- `PsychometricScale` has_many `ScaleResponse`
- `ScaleRequest` belongs_to `Patient`
- `ScaleRequest` belongs_to `Professional`
- `ScaleRequest` belongs_to `PsychometricScale`
- `ScaleRequest` has_one `ScaleResponse`
- `ScaleResponse` belongs_to `ScaleRequest`
- `ScaleResponse` belongs_to `Patient`
- `ScaleResponse` belongs_to `PsychometricScale`
- `Patient` has_many `ScaleRequest`
- `Patient` has_many `ScaleResponse`
- `Professional` has_many `ScaleRequest`

### Migrações

[ ] `create_psychometric_scales` migration
[ ] `create_scale_requests` migration
[ ] `create_scale_responses` migration
[ ] Índices para performance (status, dates, patient_id, professional_id)

### Controllers e Views

[ ] **PsychometricScalesController**

- `index` - Lista escalas disponíveis (apenas admin/profissionais)
- `show` - Detalhes da escala
- CRUD básico (apenas admin)

[ ] **ScaleRequestsController**

- `index` - Lista solicitações (filtros por status, paciente, profissional)
- `show` - Detalhes da solicitação
- `new` - Formulário para solicitar preenchimento
- `create` - Criar nova solicitação
- `destroy` - Cancelar solicitação

[ ] **ScaleResponsesController**

- `new` - Formulário de preenchimento da escala
- `create` - Salvar respostas e calcular pontuação
- `show` - Visualizar resposta preenchida

### Autorização (Pundit)

[ ] **PsychometricScalePolicy**

- Admin pode gerenciar todas as escalas
- Profissionais podem visualizar escalas ativas
- Pacientes não têm acesso

[ ] **ScaleRequestPolicy**

- Profissionais podem criar solicitações para seus pacientes
- Profissionais podem ver solicitações que criaram
- Pacientes podem ver apenas suas próprias solicitações
- Admin pode gerenciar todas as solicitações

[ ] **ScaleResponsePolicy**

- Pacientes podem criar respostas para suas solicitações
- Profissionais podem ver respostas de seus pacientes
- Admin pode ver todas as respostas

### Views

[ ] **Escalas Psicométricas**

- `index.html.erb` - Lista de escalas disponíveis
- `show.html.erb` - Detalhes da escala

[ ] **Solicitações**

- `index.html.erb` - Lista de solicitações com filtros
- `show.html.erb` - Detalhes da solicitação
- `new.html.erb` - Formulário de nova solicitação
- `_request.html.erb` - Partial para item da lista

[ ] **Respostas**

- `new.html.erb` - Formulário de preenchimento da escala
- `show.html.erb` - Visualização da resposta preenchida

### Funcionalidades Especiais

[ ] **Implementação BDI (Inventário de Depressão de Beck)**

- 21 itens com 4 opções cada (0-3 pontos)
- Cálculo automático da pontuação total
- Interpretação baseada na pontuação:
  - 0-11: Mínima
  - 12-19: Leve
  - 20-27: Moderada
  - 28-63: Grave

[ ] **Sistema de Notificações**

- Alertar paciente sobre solicitações pendentes no login
- Notificar profissional quando escala for preenchida
- Lembretes de expiração de solicitações (MVP: desabilitado)

[ ] **Validações de Negócio**

- Não permitir múltiplas solicitações ativas da mesma escala para o mesmo paciente
- Expiração automática de solicitações antigas (MVP: desabilitado)
- Validação de respostas obrigatórias

### Testes

[ ] **Model Specs**

- Validações de `PsychometricScale`, `ScaleRequest`, `ScaleResponse`
- Cálculo de pontuação BDI
- Interpretação de resultados
- Expiração automática de solicitações (MVP: desabilitado)

[ ] **Request Specs**

- CRUD de solicitações e respostas
- Autorização com Pundit
- Fluxo completo de solicitação → preenchimento

[ ] **Feature Specs**

- Fluxo profissional: solicitar → paciente preenche → visualizar resultado
- Fluxo paciente: login → ver solicitações → preencher → confirmar

### Próximos Passos Sugeridos

1. **Prioridade 1**: Modelo de domínio (PsychometricScale + ScaleRequest + ScaleResponse)
2. **Prioridade 2**: Migrações e associações
3. **Prioridade 3**: Implementação BDI (estrutura de itens e cálculo)
4. **Prioridade 4**: Controllers básicos + autorização
5. **Prioridade 5**: Views e formulários de preenchimento

---

Próximos passos sugeridos
Prioridade 1: Magic link
Prioridade 2: API api/v1/users

Implementado: Pundit (policies + controllers), fluxo de primeiro login (migr., controller, view, i18n), soft delete com endpoints e specs, sistema de lockout completo e funcionando.

À fazer MVP: magic link

✅ CHECKPOINT: Sistema de lockout completamente implementado e funcionando. Todas as funcionalidades solicitadas foram entregues com sucesso.

DETALHES TÉCNICOS DO LOCKOUT:

- ✅ Devise :lockable habilitado no User
- ✅ Configuração: 3 tentativas, 5 minutos de bloqueio
- ✅ Controller personalizado: Users::SessionsController
- ✅ View personalizada com lógica de mensagens
- ✅ Traduções i18n implementadas
- ✅ PROBLEMA RESOLVIDO: Mensagens personalizadas agora aparecem corretamente
- ✅ SOLUÇÃO: Lógica implementada na view com fallback para mensagens genéricas
- ✅ CORREÇÃO: Removida duplicação de mensagens no layout application.html.erb
- ✅ FUNCIONALIDADES ENTREGUES:
  - Exibir número de tentativas restantes
  - Avisar sobre última tentativa antes do bloqueio
  - Informar tempo de bloqueio quando conta está bloqueada
  - Mensagens em português brasileiro
  - Interface limpa sem duplicação
