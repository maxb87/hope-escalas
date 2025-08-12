Checklist atualizado
[x] Soft delete (Paranoia) para patients e professionals
[x] Migrações: deleted_at:datetime + índices em users, patients, professionals
[x] Modelos com acts_as_paranoid
[ ] UX de “Restaurar” item (opcional)
[ ] Specs de soft delete/restore
[ ] Autorização com Pundit
[ ] Incluir Pundit::Authorization e callbacks no ApplicationController
[ ] PatientPolicy e ProfessionalPolicy (+ Scope)
[ ] Usar authorize/policy_scope nos controllers
[ ] Specs de policies/authorization
[x] Devise: primeiro login exige troca de senha
[x] users.force_password_reset:boolean, null:false, default:false
[x] Enforce redirect para edit_user_registration_path quando flag = true
[x] Users::RegistrationsController: troca sem senha atual no primeiro login, limpa flag, bypass_sign_in
[x] View registrations#edit: esconder e-mail e senha atual durante reset forçado
[x] I18n básico para mensagens
[ ] Opcional: habilitar :confirmable/:lockable
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
Prioridade 1: Pundit (políticas e aplicação nos controllers).
Prioridade 2: API api/v1/users ou iniciar o fluxo de magic link (conforme sua prioridade).
Implementado: fluxo de primeiro login (migr., controller, view, i18n) e índices de soft delete.
A fazer: Pundit, API, magic link, testes e observabilidade.
