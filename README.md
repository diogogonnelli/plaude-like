# GravAcao

Produto `GravAcao`, co-branded com `SPOT`, com app `Flutter` para web/mobile, backoffice `React` e backend `TypeScript` preparado para `Supabase`.

## O que ja esta implementado

- App Flutter com:
  - biblioteca de notas de voz
  - gravacao local em mobile/desktop
  - upload de arquivos de audio
  - projeto opcional no momento da gravacao ou do envio
  - leitura de reunioes online capturadas pelo companion desktop
  - tela de detalhe com resumo, highlights, action items e transcript
  - chat contextual sobre a nota
  - exportacao em markdown
  - fallback local em modo demo quando o backend nao esta disponivel
- Backend Express com:
  - `POST /recordings`
  - `POST /recordings/:id/process`
  - `GET /recordings`
  - `GET /recordings/:id`
  - `POST /recordings/:id/chat`
  - `POST /recordings/:id/export`
  - `POST /webhooks/transcription`
- Schema inicial de `Supabase` com `RLS`, `pgvector` e tabelas do pipeline.

## Estrutura

- [`app`](./app): cliente Flutter web/mobile
- [`admin-web`](./admin-web): web administrativo separado
- [`backend`](./backend): API HTTP e pipeline de processamento
- [`meeting-capture-companion`](./meeting-capture-companion): companion desktop para reunioes online em Windows/macOS
- [`supabase`](./supabase): schema SQL e documentacao da camada gerenciada
- [`docs`](./docs): arquitetura e decisoes do v1

## Como rodar

### Backend

```bash
cd backend
copy .env.example .env
npm install
npm start
```

Por padrao ele sobe em `http://localhost:8787` e usa provider `mock`.

### App Flutter

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define=BACKEND_BASE_URL=http://localhost:8787
```

Se o backend nao estiver rodando, o app entra automaticamente em `demo mode`.

### Admin Web

```powershell
cd admin-web
npm install
$env:VITE_API_BASE_URL="http://localhost:8787"
$env:VITE_SUPABASE_URL="https://seu-projeto.supabase.co"
$env:VITE_SUPABASE_ANON_KEY="sua_supabase_anon_key"
npm run dev -- --host 0.0.0.0
```

O Vite mostra a URL local no terminal, normalmente `http://localhost:5173`.

### Meeting Capture Companion

```bash
cd meeting-capture-companion
npm install
npm run dev
```

Variaveis principais:

- `COMPANION_BACKEND_BASE_URL`
- `COMPANION_SUPABASE_URL`
- `COMPANION_SUPABASE_ANON_KEY`

## Deploy

O fluxo de producao via Bitbucket Pipelines + host Linux esta em [`DEPLOY.md`](./DEPLOY.md).

## Deploy de teste com containers

```bash
cd C:\vscode_projects\Plaude_like
copy backend\.env.example backend\.env
docker compose up --build
```

Servicos:

- web em `http://localhost:8080`
- admin web em `http://localhost:8081`
- backend em `http://localhost:8787`

Mais detalhes em [`docs/deployment.md`](./docs/deployment.md).

## Scripts uteis no Windows

- subir backend + app web: `powershell -ExecutionPolicy Bypass -File .\scripts\start-local.ps1`
- checar health do backend: `powershell -ExecutionPolicy Bypass -File .\scripts\check-stack.ps1`

## Integracoes reais

Para sair do modo mock:

1. Configure `OPENAI_API_KEY` em [`backend/.env.example`](./backend/.env.example).
2. Troque `AI_PROVIDER=mock` por `AI_PROVIDER=openai`.
3. Para transcricao real de audio longo, configure `TRANSCRIPTION_PROVIDER=assemblyai` e `ASSEMBLYAI_API_KEY`.
4. Aponte `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` para seu projeto real.
5. Aplique as migrations em [`supabase/migrations`](./supabase/migrations).

## Validacao local

- `cd app && flutter analyze`
- `cd app && flutter test`
- `cd backend && npm run typecheck`
- `cd backend && npm test`

## Documentacao da API

- [`docs/api.md`](./docs/api.md)
- `GET /openapi.json`
- `GET /docs`
