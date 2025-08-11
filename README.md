# Hope Escalas

Sistema para solicitação e registro de escalas psicométricas de pacientes da clínica médica Hope Neuropsiquiatria.

## Sumário

- Stack e versões
- Setup com mise (Ruby/Node) e inicialização
- Ambiente de desenvolvimento (PostgreSQL/Redis via Docker Compose)
- Execução
- Domínio e fluxos (Professionals/Patients, Devise e magic link)
- Testes e qualidade
- Arquitetura de software (boas práticas)
- Segurança (master key, magic link)
- Observabilidade
- CI/CD
- Deploy (Railway)
- Roadmap
- Licença

## Stack e versões

- Ruby: 3.4.x (recomendado: 3.4.4)
- Rails: 8.0.x (recomendado: 8.0.2)
- Banco de dados: PostgreSQL 17.x
- Redis: 7.x (opcional no início; necessário para Sidekiq/Action Cable/Cache centralizado)
- Node.js: 20 LTS (se usar jsbundling), opcional com `importmap-rails`

Notas sobre banco de dados:

- Para paridade com produção e suporte a `jsonb`, use PostgreSQL também em desenvolvimento. SQLite não possui `jsonb` (apenas JSON1 como texto) e pode causar divergências de migrações/consultas.

## Setup com mise (Ruby/Node) e inicialização

No diretório do projeto:

```bash
cd /home/gilgamesh/code/hope/hope-escalas

# Plugins e versões
mise plugin add ruby || true
mise plugin add nodejs || true
printf "ruby 3.4.4\nnodejs 20.15.0\n" > .tool-versions
mise install

# Bundler e Rails
gem install bundler --no-document
gem install rails -v 8.0.2 --no-document

# Instalar dependências do app (se já criado)
bundle install || true
```

Inicialização de app Rails (se ainda não existir esqueleto):

```bash
rails _8.0.2_ new . -d postgresql --force --skip-git
```

Nota sobre .env versionado:

- O arquivo `.env` é versionado para padronizar o setup entre máquinas dos desenvolvedores.
- Não armazene segredos no `.env`. Use credenciais criptografadas do Rails (`rails credentials:edit`) ou variáveis seguras na Railway.
- Arquivos de chave em texto plano não são commitados (`config/master.key`, `config/credentials/*.key`). Em produção, defina `RAILS_MASTER_KEY` nas variáveis da Railway.

## Ambiente de desenvolvimento (Docker Compose)

Arquivo sugerido `docker-compose.yml`:

```yaml
version: "3.9"
services:
  postgres:
    image: postgres:17
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: hope_escalas_development
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: ["redis-server", "--appendonly", "yes"]
    volumes:
      - redisdata:/data

volumes:
  pgdata:
  redisdata:
```

Subir serviços e configurar variáveis locais:

```bash
docker compose up -d
export DATABASE_URL=postgres://postgres:postgres@localhost:5432/hope_escalas_development
export REDIS_URL=redis://localhost:6379/0 # opcional no MVP
```

Como rodar o ambiente local passo a passo:

```bash
# 1) Instalar runtimes
mise install

# 2) Criar .env local a partir do exemplo (ou exportar as variáveis manualmente)
cp .env.example .env
source .env

# 3) Subir Postgres e Redis
docker compose up -d
docker compose ps

# 4) Preparar o banco
bin/rails db:prepare

# 5) Rodar a aplicação
bin/rails s

# (Opcional) Rodar Sidekiq se for usar jobs/redis
# bundle exec sidekiq

# Parar serviços Docker quando terminar
docker compose down
```

## Execução

```bash
bin/rails db:prepare
bin/rails s
```

Observações:

- O Rails usará `DATABASE_URL` se definida; caso contrário, `config/database.yml` lê `PGHOST/PGPORT/PGUSER/PGPASSWORD/PGDATABASE` do ambiente (carregadas via `source .env`).

Jobs em desenvolvimento (opcional): configure Sidekiq e rode `bundle exec sidekiq`.

## Domínio e fluxos

- Entidades principais:
  - `Professional` (profissionais médicos): acessam autenticados, gerenciam pacientes e solicitam preenchimento de escalas psicométricas.
  - `Patient` (pacientes): acessam via login direto ou magic link e veem apenas as escalas solicitadas por um médico.
  - `User` (Devise): conta autenticável associada a um `Professional` ou `Patient`. Conta provisionada por administrador.
- Autenticação (Devise):
  - Usuários cadastrados por administrador recebem login com senha inicial de uso único.
  - No primeiro login, devem redefinir a senha antes de continuar.
- Fluxo do profissional:
  - Login → seleciona/cadastra paciente → visualiza escalas preenchidas/pendentes → solicita preenchimento de escala específica.
  - Ao solicitar, o sistema envia um magic link ao e-mail do paciente (possibilidade de reenvio).
- Fluxo do paciente (magic link):
  - Clica no magic link → realiza login (ou primeiro login com troca de senha) → redirecionado para sua página de perfil → vê somente as escalas solicitadas.
  - Magic link: uso único e expiração curta.

## Testes e qualidade

- Testes: RSpec + FactoryBot + Faker
- Cobertura: SimpleCov (meta ≥ 90%)
- Estilo: RuboCop (Rails/Performance), reek (opcional)
- Segurança: Brakeman, bundler-audit

Comandos úteis:

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman -A -q
bundle exec bundler-audit check --update
```

## Arquitetura de software (boas práticas)

- 12-Factor App, SOLID, DDD leve, Clean/Hexagonal
- Pastas sugeridas: `app/domains`, `app/services`, `app/queries`, `app/policies`, `app/serializers`, `app/presenters`/`view_models`, `app/jobs`, `app/adapters`, `lib`
- Persistência: índices/constraints/FKs como defesa em profundidade; migrações idempotentes
- I18n/TZ: `default_locale: 'pt-BR'`, `time_zone: 'UTC-3'`
- Performance: evitar N+1 (`includes`, bullet em dev), cache com chaves compostas
- ADRs em `docs/adr`

Subdomínio de escalas psicométricas (alto nível):

- Catálogo de escalas, versões e itens mantidos por administradores
- Solicitação de escala vinculando `Patient` e tipo de escala (estados: pendente, preenchida, expirada)
- Tokens de magic link vinculados à solicitação (escopo: paciente + escala + expiração + uso único)

## Segurança (master key, magic link)

- Credenciais Rails:
  - Arquivo criptografado: `config/credentials.yml.enc` (ou `config/credentials/production.yml.enc`)
  - Chave (NÃO commitar): `config/master.key` (ou `config/credentials/production.key`)
  - Em produção (Railway), defina `RAILS_MASTER_KEY` nas variáveis do projeto
- Magic link:
  - Token assinado, escopo a paciente e à escala solicitada, uso único, expiração curta
  - Revogação após uso/expiração; auditoria de emissão/consumo
  - Após login, redirecionar para o perfil do paciente com filtro de escalas solicitadas

## Observabilidade

- Logs estruturados (JSON) com Lograge
- Correlation ID (Request-Id) propagado
- Erros: Sentry/Bugsnag
- Métricas: `prometheus_exporter` (HTTP/DB/Sidekiq)
- Healthchecks: `/up`, `/healthz`, `/readyz`

## CI/CD

- CI (ex.: GitHub Actions): lint → segurança → testes → cobertura; cache do bundler
- CD: migrations com `db:prepare`; feature flags para mudanças arriscadas
- Railway: configure um comando de `release` para `rails db:migrate` a cada deploy
- Versionamento: Conventional Commits + CHANGELOG; tags semânticas

## Deploy (Railway)

- Commitar: `config/credentials/production.yml.enc`
- Railway (Settings → Variables):
  - `RAILS_ENV=production`
  - `RAILS_MASTER_KEY` (conteúdo da sua `production.key`)
  - `RAILS_LOG_TO_STDOUT=1`, `RAILS_SERVE_STATIC_FILES=1`
  - `DATABASE_URL` (do Postgres da Railway)
  - `REDIS_URL` (se usar Sidekiq/Action Cable)
  - `MAILER_URL_HOST`, `MAILER_FROM`
- Build/Release/Start:
  - Build: `bundle exec rails assets:precompile`
  - Release: `bundle exec rails db:migrate`
  - Web: `bundle exec puma -C config/puma.rb`
- Opcional `Procfile`:
  - `web: bundle exec puma -C config/puma.rb`
  - `release: bundle exec rails db:migrate`

## Roadmap

- MVP com cadastro de pacientes, solicitação de escalas e magic link
- Painel do profissional: solicitações e status
- Painel do paciente: solicitações pendentes e escalas preenchidas

## Licença

Definir licença (ex.: MIT) conforme necessidade do projeto.
