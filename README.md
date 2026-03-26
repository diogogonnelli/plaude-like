# Plaude Like

Aplicativo `PLAUD Note`-like com `Flutter` para web/mobile, backend `TypeScript` e infraestrutura preparada para `Supabase`.

## O que já está implementado

- App Flutter com:
  - biblioteca de notas de voz
  - gravação local em mobile/desktop
  - upload de arquivos de áudio
  - tela de detalhe com resumo, highlights, action items e transcript
  - chat contextual sobre a nota
  - exportação em markdown
  - fallback local em modo demo quando o backend não está disponível
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
- [`backend`](./backend): API HTTP e pipeline de processamento
- [`supabase`](./supabase): schema SQL e documentação da camada gerenciada
- [`docs`](./docs): arquitetura e decisões do v1

## Como rodar

### Backend

```bash
cd backend
copy .env.example .env
npm install
npm start
```

Por padrão ele sobe em `http://localhost:8787` e usa provider `mock`.

### App Flutter

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define=BACKEND_BASE_URL=http://localhost:8787
```

Se o backend não estiver rodando, o app entra automaticamente em `demo mode`.

## Deploy de teste com containers

```bash
cd C:\vscode_projects\Plaude_like
copy backend\.env.example backend\.env
docker compose up --build
```

Serviços:

- web em `http://localhost:8080`
- backend em `http://localhost:8787`

Mais detalhes em [`docs/deployment.md`](./docs/deployment.md).

## Scripts úteis no Windows

- subir backend + app web: `powershell -ExecutionPolicy Bypass -File .\scripts\start-local.ps1`
- checar health do backend: `powershell -ExecutionPolicy Bypass -File .\scripts\check-stack.ps1`

## Integrações reais

Para sair do modo mock:

1. Configure `OPENAI_API_KEY` em [`backend/.env.example`](./backend/.env.example).
2. Troque `AI_PROVIDER=mock` por `AI_PROVIDER=openai`.
3. Aponte `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` para seu projeto real.
4. Aplique a migration [`supabase/migrations/0001_init.sql`](./supabase/migrations/0001_init.sql).

## Validação local

- `cd app && flutter analyze`
- `cd app && flutter test`
- `cd backend && npm run typecheck`
- `cd backend && npm test`
