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

# Yarn (via Corepack - incluído no Node.js 16.10+)
corepack enable

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
cp .env.example .env   # se ainda não existir
source .env
docker compose up -d
```

Notas:

- Volumes nomeados `pgdata` e `redisdata` persistem os dados localmente. Para reset total (cuidado, apaga dados): `docker compose down -v`.

Como rodar o ambiente local passo a passo:

```bash
# 1) Instalar runtimes
mise install

# 2) Criar .env local a partir do exemplo (ou exportar as variáveis manualmente)
cp .env.example .env
source .env

# 3) Instalar gems
bundle install

# 4) Subir Postgres e Redis
docker compose up -d
docker compose ps

# 5) Preparar o banco
bin/rails db:prepare

# 6) Rodar a aplicação
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

### Setup após git pull em outra máquina

Siga esta sequência para evitar erros de assets e watchers:

```bash
cd /home/gilgamesh/code/hope/hope-escalas

# 1) Runtimes e gems
mise install
bundle install

# 2) Variáveis de ambiente
cp .env.example .env  # se ainda não existir
source .env

# 3) Serviços locais
docker compose up -d

# 4) Node/Yarn e dependências (o projeto usa Yarn via Corepack)
corepack enable
yarn install

# Se o bin/dev acusar 'command not found: nodemon' ou falhas de Sass/PostCSS, rode:
# yarn add -D nodemon sass postcss postcss-cli autoprefixer

# 5) Compilação/Watch de assets (dev)
bin/dev  # (sobe web, js e css watchers)

# Alternativas pontuais
yarn build       # JS
yarn build:css   # CSS
```

Notas de assets:

- Layout deve referenciar apenas `application`:
  - `<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>`
  - `<%= javascript_include_tag "application", "data-turbo-track": "reload", type: "module" %>`
- `config/initializers/assets.rb` precisa incluir `app/assets/builds` no load path (já configurado).

### Pós-setup (Devise, Pundit, RSpec e Solargraph)

```bash
# Devise (autenticação)
bin/rails generate devise:install

# Pundit (autorização)
bin/rails generate pundit:install

# RSpec (testes)
bin/rails generate rspec:install

# Solargraph (LSP para editores)
bundle exec solargraph config
bundle exec solargraph scan
```

### Soft delete (Paranoia) — rápido

```bash
# Exemplo para Patients (repita para outras tabelas quando necessário)
bin/rails generate migration AddDeletedAtToPatients deleted_at:datetime:index
bin/rails db:migrate
```

```ruby
# app/models/patient.rb
class Patient < ApplicationRecord
  acts_as_paranoid
end
```

## Domínio e fluxos

- Entidades principais:

  - `Professional` (profissionais médicos): acessam autenticados, gerenciam pacientes e solicitam preenchimento de escalas psicométricas.
  - `Patient` (pacientes): acessam via login direto e veem apenas as escalas solicitadas por um médico.
  - `User` (Devise): conta autenticável associada a um `Professional` ou `Patient`. Conta provisionada por administrador.
  - `PsychometricScale` (escalas): catálogo de escalas disponíveis (ex: SRS-2 - Social Responsiveness Scale).
  - `ScaleRequest` (solicitações): pedidos de preenchimento de escalas por profissionais para pacientes.
  - `ScaleResponse` (respostas): preenchimentos das escalas pelos pacientes com cálculo automático de pontuação.

- Autenticação (Devise):

  - Usuários cadastrados por administrador recebem login com senha inicial de uso único.
  - No primeiro login, devem redefinir a senha antes de continuar.

- Fluxo do profissional:

  1. Login → Dashboard com lista de pacientes
  2. Seleciona paciente → Perfil do paciente
  3. Clica "Solicitar preenchimento" → Lista de escalas disponíveis
  4. Seleciona escala (ex: SRS-2) → Cria solicitação
  5. Visualiza solicitações pendentes/completadas do paciente

- Fluxo do paciente:

  1. Login → Alerta sobre N solicitações pendentes
  2. Perfil mostra lista de escalas a preencher (nome + data solicitação)
  3. Clica em escala → Formulário de preenchimento
  4. Preenche todos os itens → Sistema calcula pontuação automaticamente
  5. Volta ao perfil → Tabela com escalas preenchidas (nome + data conclusão)

- Primeira escala implementada: **SRS-2 (Social Responsiveness Scale)**
  - Escala de avaliação para transtornos do espectro autista
  - Cálculo automático de pontuações e interpretação dos resultados

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

- Catálogo de escalas psicométricas mantido por administradores
- Solicitação de escala vinculando `Patient`, `Professional` e `PsychometricScale` (estados: pendente, completada, expirada, cancelada)
- Preenchimento de escalas pelos pacientes com cálculo automático de pontuação e interpretação
- Sistema de notificações para alertar sobre solicitações pendentes e conclusões

## Segurança (master key, magic link)

- Credenciais Rails:
  - Arquivo criptografado: `config/credentials.yml.enc` (ou `config/credentials/production.yml.enc`)
  - Chave (NÃO commitar): `config/master.key` (ou `config/credentials/production.key`)
  - Em produção (Railway), defina `RAILS_MASTER_KEY` nas variáveis do projeto
- Segurança de dados:
  - Respostas de escalas armazenadas em JSONB com validação de estrutura
  - Pontuações calculadas automaticamente para evitar manipulação
  - Auditoria completa de solicitações e preenchimentos
  - Expiração automática de solicitações antigas

## Observabilidade

- Logs estruturados (JSON) com Lograge
- Correlation ID (Request-Id) propagado
- Erros: Sentry/Bugsnag
- Métricas: `prometheus_exporter` (HTTP/DB/Sidekiq)
- Healthchecks: `/up`, `/healthz`, `/readyz`

## Deploy (Railway)

### Pré-requisitos

- Instalar Railway CLI: `curl -fsSL https://railway.app/install.sh | sh`
- Login: `railway login`

### Configuração Inicial

```bash
# Inicializar projeto Railway
railway init

# Adicionar banco de dados PostgreSQL
railway add postgresql

# Adicionar Redis (opcional)
railway add redis
```

### Variáveis de Ambiente

Configure as seguintes variáveis no Railway:

```bash
railway variables set RAILS_ENV=production
railway variables set RAILS_MASTER_KEY=$(cat config/master.key)
railway variables set RAILS_LOG_TO_STDOUT=true
railway variables set RAILS_SERVE_STATIC_FILES=true
railway variables set DATABASE_URL='${{Postgres.DATABASE_URL}}'
railway variables set REDIS_URL='${{Redis.REDIS_URL}}'
railway variables set MAILER_URL_HOST=your-app.railway.app
railway variables set MAILER_FROM=noreply@hopeneuro.com.br
```

### Deploy

```bash
# Deploy da aplicação
railway up

# Verificar logs
railway logs

# Abrir aplicação no browser
railway open
```

### Procfile (Opcional)

Criar arquivo `Procfile` na raiz do projeto:

```
web: bundle exec puma -C config/puma.rb
release: bundle exec rails db:migrate
```

## Roadmap

- MVP com cadastro de pacientes, solicitação de escalas psicométricas e preenchimento
- Implementação do SRS-2 (Social Responsiveness Scale) como primeira escala
- Painel do profissional: solicitações, status e visualização de resultados
- Painel do paciente: solicitações pendentes e histórico de escalas preenchidas
- Sistema de notificações para alertas e lembretes
- Expansão do catálogo de escalas psicométricas

## Licença

Definir licença (ex.: MIT) conforme necessidade do projeto.
