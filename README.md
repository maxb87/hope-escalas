# Hope Escalas

Sistema para solicitação e registro de escalas psicométricas de pacientes da clínica médica Hope Neuropsiquiatria.

## Sumário

- Stack e versões
- Setup com mise (Ruby/Node) e inicialização
- Ambiente de desenvolvimento (PostgreSQL/Redis via Docker Compose)
- Execução
- Frontend (Vite/React/TypeScript/Tailwind CSS)
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
- Node.js: 20 LTS (recomendado: 20.19+ para Vite)
- Yarn: 4.x (gerenciador de pacotes)
- Vite: 7.x (bundler e dev server)
- React: 19.x (biblioteca de UI)
- TypeScript: 5.x (tipagem estática)
- Tailwind CSS: 3.x (framework CSS utilitário)
- shadcn/ui: componentes React reutilizáveis

Notas sobre banco de dados:

- Para paridade com produção e suporte a `jsonb`, use PostgreSQL também em desenvolvimento. SQLite não possui `jsonb` (apenas JSON1 como texto) e pode causar divergências de migrações/consultas.

## Setup com mise (Ruby/Node) e inicialização

No diretório do projeto:

```bash
cd /home/gilgamesh/code/hope/hope-escalas

# Plugins e versões
mise plugin add ruby || true
mise plugin add nodejs || true
printf "ruby 3.4.4\nnodejs 20.19.0\n" > .tool-versions
mise install

# Bundler e Rails
gem install bundler --no-document
gem install rails -v 8.0.2 --no-document

# Yarn (via Corepack - incluído no Node.js 16.10+)
corepack enable

# Instalar dependências do app (se já criado)
bundle install || true
yarn install
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

# 3) Instalar gems e dependências Node
bundle install
yarn install

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

# 4) Node/Yarn e dependências
corepack enable
yarn install

# 5) Compilação/Watch de assets (dev)
bin/dev  # (sobe web, js e css watchers)

# Alternativas pontuais
yarn build       # JS/TS
yarn build:css   # CSS
yarn type-check  # Verificação de tipos TypeScript
```

Notas de assets:

- Layout deve referenciar apenas `application`:
  - `<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>`
  - `<%= javascript_include_tag "application", "data-turbo-track": "reload", type: "module" %>`
  - `<%= vite_client_tag %>` e `<%= vite_javascript_tag 'application' %>` (para Vite)
- `config/initializers/assets.rb` precisa incluir `app/assets/builds` no load path (já configurado).

## Frontend (Vite/React/TypeScript/Tailwind CSS)

### Estrutura do Frontend

```
app/javascript/
├── application.tsx          # Entry point TypeScript
├── application.js           # Entry point JavaScript (legacy)
├── components/
│   ├── ui/                  # shadcn/ui components
│   │   ├── button.tsx
│   │   ├── input.tsx
│   │   ├── label.tsx
│   │   └── card.tsx
│   └── LoginForm.tsx        # Exemplo de componente React
├── lib/
│   └── utils.ts             # Utilitários (cn function)
└── controllers/             # Stimulus controllers
```

### Comandos Frontend

```bash
# Desenvolvimento
yarn dev                    # Vite dev server
yarn watch:css             # Watch Tailwind CSS
yarn type-check            # Verificação TypeScript

# Build
yarn build                 # Build completo (JS/TS + CSS)
yarn build:css             # Build apenas CSS

# Preview
yarn preview               # Preview do build
```

### Usando shadcn/ui Components

```tsx
// Em componentes React
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export const MyComponent = () => {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Título</CardTitle>
      </CardHeader>
      <CardContent>
        <Input placeholder="Digite algo..." />
        <Button>Clique aqui</Button>
      </CardContent>
    </Card>
  );
};
```

### Tailwind CSS em Views Rails

```erb
<!-- Em views ERB -->
<div class="flex min-h-screen items-center justify-center bg-gray-50">
  <div class="w-full max-w-md space-y-8">
    <h2 class="text-center text-3xl font-bold">Título</h2>
    <!-- Seu conteúdo -->
  </div>
</div>
```

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
  - `PsychometricScale` (escalas): catálogo de escalas disponíveis (ex: BDI - Inventário de Depressão de Beck).
  - `ScaleRequest` (solicitações): pedidos de preenchimento de escalas por profissionais para pacientes.
  - `ScaleResponse` (respostas): preenchimentos das escalas pelos pacientes com cálculo automático de pontuação.

- Autenticação (Devise):

  - Usuários cadastrados por administrador recebem login com senha inicial de uso único.
  - No primeiro login, devem redefinir a senha antes de continuar.

- Fluxo do profissional:

  1. Login → Dashboard com lista de pacientes
  2. Seleciona paciente → Perfil do paciente
  3. Clica "Solicitar preenchimento" → Lista de escalas disponíveis
  4. Seleciona escala (ex: BDI) → Cria solicitação
  5. Visualiza solicitações pendentes/completadas do paciente

- Fluxo do paciente:

  1. Login → Alerta sobre N solicitações pendentes
  2. Perfil mostra lista de escalas a preencher (nome + data solicitação)
  3. Clica em escala → Formulário de preenchimento
  4. Preenche todos os itens → Sistema calcula pontuação automaticamente
  5. Volta ao perfil → Tabela com escalas preenchidas (nome + data conclusão)

- Primeira escala implementada: **BDI (Inventário de Depressão de Beck)**
  - 21 itens com 4 opções cada (0-3 pontos)
  - Cálculo automático: 0-11 (Mínima), 12-19 (Leve), 20-27 (Moderada), 28-63 (Grave)

## Testes e qualidade

- Testes: RSpec + FactoryBot + Faker
- Cobertura: SimpleCov (meta ≥ 90%)
- Estilo: RuboCop (Rails/Performance), reek (opcional)
- Segurança: Brakeman, bundler-audit
- Frontend: TypeScript strict mode, ESLint (opcional)

Comandos úteis:

```bash
# Backend
bundle exec rspec
bundle exec rubocop
bundle exec brakeman -A -q
bundle exec bundler-audit check --update

# Frontend
yarn type-check
```

## Arquitetura de software (boas práticas)

- 12-Factor App, SOLID, DDD leve, Clean/Hexagonal
- Pastas sugeridas: `app/domains`, `app/services`, `app/queries`, `app/policies`, `app/serializers`, `app/presenters`/`view_models`, `app/jobs`, `app/adapters`, `lib`
- Persistência: índices/constraints/FKs como defesa em profundidade; migrações idempotentes
- I18n/TZ: `default_locale: 'pt-BR'`, `time_zone: 'UTC-3'`
- Performance: evitar N+1 (`includes`, bullet em dev), cache com chaves compostas
- ADRs em `docs/adr`
- Frontend: Componentes React reutilizáveis, TypeScript para type safety, Tailwind CSS para styling

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

## CI/CD

- CI (ex.: GitHub Actions): lint → segurança → testes → cobertura; cache do bundler e Yarn
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
  - Build: `yarn build && bundle exec rails assets:precompile`
  - Release: `bundle exec rails db:migrate`
  - Web: `bundle exec puma -C config/puma.rb`
- Opcional `Procfile`:
  - `web: bundle exec puma -C config/puma.rb`
  - `release: bundle exec rails db:migrate`

## Roadmap

- MVP com cadastro de pacientes, solicitação de escalas psicométricas e preenchimento
- Implementação do BDI (Inventário de Depressão de Beck) como primeira escala
- Painel do profissional: solicitações, status e visualização de resultados
- Painel do paciente: solicitações pendentes e histórico de escalas preenchidas
- Sistema de notificações para alertas e lembretes
- Expansão do catálogo de escalas psicométricas
- Melhorias de UI/UX com componentes React avançados
- PWA (Progressive Web App) para acesso mobile

## Licença

Definir licença (ex.: MIT) conforme necessidade do projeto.
