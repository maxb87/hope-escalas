Checklist atualizado
[x] Soft delete (Paranoia) para patients e professionals
[x] Migrações: deleted_at:datetime + índices em users, patients, professionals
[x] Modelos com acts_as_paranoid
[ ] UX de “Restaurar” item (opcional)
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
