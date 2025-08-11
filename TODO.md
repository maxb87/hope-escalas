# TODO – MVP Hope Escalas

## Feito
- README reescrito com setup (mise, Docker Compose, .env versionado), arquitetura e deploy Railway
- Docker Compose com volumes nomeados (pgdata, redisdata)
- .env e .env.example criados; .gitignore permite versionar .env
- config/database.yml lendo DATABASE_URL ou variáveis PG*
- Gemfile: devise, pundit, paranoia, rspec-rails, factory_bot_rails, faker, simplecov, bundler-audit, lograge, prometheus_exporter, bullet, solargraph, brakeman, rubocop-rails-omakase
- Rota raiz e página placeholder: root "pages#index" com ‘Hello world’

## A fazer – MVP (ordem sugerida)
1) Preparar ambiente local
- mise install
- cp .env.example .env && source .env
- docker compose up -d
- bundle install
- bin/rails db:prepare

2) Devise – instalação e modelo User
- bin/rails generate devise:install
- bin/rails generate devise User
- Remover :registerable se o cadastro for só por admin (editar app/models/user.rb após gerar)
- Adicionar flag para troca de senha no primeiro acesso:
  - bin/rails g migration AddForcePasswordResetToUsers force_password_reset:boolean{default:true}
  - bin/rails db:migrate

3) Modelos de domínio: Professional e Patient
- Polimórfica (recomendado pelo README): User pertence a account polimórfico (Professional ou Patient)
- Gerar modelos com soft delete (paranoia):
  - bin/rails g model Professional full_name:string deleted_at:datetime:index
  - bin/rails g model Patient full_name:string email:string phone:string deleted_at:datetime:index
  - bin/rails g migration AddAccountToUsers account:references{polymorphic}
  - bin/rails db:migrate
- Ajustar models:
  - Professional/Patient: acts_as_paranoid, has_one :user, as: :account
  - User: belongs_to :account, polymorphic: true, optional: true

4) Pundit – autorização básica
- bin/rails generate pundit:install
- ApplicationController deve incluir Pundit::Authorization
- Gerar políticas base:
  - bin/rails g pundit:policy patient
  - bin/rails g pundit:policy professional

5) Paranoia – índices e unicidade ativa
- Garantir índices já gerados em deleted_at
- Para e-mails únicos apenas ativos (se necessário): índice parcial em users:
  - add_index :users, "LOWER(email)", unique: true, where: "deleted_at IS NULL", name: "index_users_on_email_unique_active"

6) Mailer de desenvolvimento
- Definir MAILER_URL_HOST no .env (ex.: localhost:3000)
- Em config/environments/development.rb:
  - config.action_mailer.default_url_options = { host: ENV.fetch("MAILER_URL_HOST", "localhost:3000") }

7) Seeds – Admin e dados mínimos
- Criar db/seeds.rb com:
  - Usuário admin (com force_password_reset: true)
  - 1–2 Patient de exemplo
- Rodar: bin/rails db:seed

8) Observabilidade e dev UX
- Lograge (produção): config.lograge.enabled = true
- Bullet (dev): habilitar em config/environments/development.rb
- Prometheus Exporter: criar initializer e expor métricas (posterior)

9) Testes
- bin/rails generate rspec:install
- Setup factory_bot_rails e faker
- Criar specs básicos (models e policies)

10) Próximos passos do domínio (depois da base)
- CRUD básico de Patient (somente acessível a Professional)
- Tela do profissional: listar pacientes, ver escalas preenchidas/pendentes (placeholder)
- Esqueleto de ‘solicitação de escala’ (modelo inicial e controller)

## Backlog (após MVP inicial)
- Magic link: modelo de token, mailer, controller de consumo, expiração e revogação
- Painel do paciente: pendências e histórico
- Integração de métricas com prometheus_exporter + dashboards
- CI: configurar pipeline (lint, segurança, testes, cobertura)
- Deploy Railway: release para rails db:migrate, variáveis de ambiente, healthchecks

## Notas rápidas
- PWA é opcional; manter desabilitado no MVP
- Redis opcional no início; necessário se usar Sidekiq/Action Cable
- .env é versionado; não guardar segredos – usar credenciais do Rails/RAILS_MASTER_KEY em produção
