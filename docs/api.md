# API

Documentação prática da API HTTP do backend do GravAção.

Base URL de exemplo:

```text
https://<seu-backend>.up.railway.app
```

Artefatos de documentação quando o backend estiver no ar:

```text
/docs
/openapi.json
```

## Autenticação

Modo autenticado padrão:

```text
Authorization: Bearer <supabase_access_token>
```

Fallback apenas para desenvolvimento local sem auth configurada:

```text
x-user-id: demo-user
```

## Status de gravação

- `uploaded`
- `processing_transcript`
- `processing_summary`
- `indexing`
- `ready`
- `failed`

## Modelo principal: Recording

Exemplo resumido:

```json
{
  "id": "uuid",
  "userId": "auth-user-uuid",
  "createdByUserId": "auth-user-uuid",
  "projectId": null,
  "title": "Audio curto",
  "sourceType": "upload",
  "captureMetadata": null,
  "status": "processing_transcript",
  "createdAt": "2026-03-31T21:00:00.000Z",
  "updatedAt": "2026-03-31T21:00:05.000Z",
  "durationMs": 180000,
  "audioPath": "project-uuid/recording-uuid/audio-curto.m4a",
  "transcriptionProvider": "assemblyai",
  "transcriptionJobId": "assemblyai-job-id",
  "transcriptionStartedAt": "2026-03-31T21:00:05.000Z",
  "transcriptionCompletedAt": null,
  "transcriptSegments": [],
  "summary": null,
  "noteArtifact": null,
  "chatSession": {
    "id": "uuid",
    "recordingId": "uuid",
    "messages": []
  },
  "lastError": null
}
```

## Endpoints do app

### `GET /health`

Healthcheck simples do serviço.

Resposta `200`:

```json
{
  "ok": true,
  "service": "gravacao-backend"
}
```

### `GET /projects`

Lista os projetos do usuário autenticado.

Resposta `200`:

```json
{
  "data": [
    {
      "id": "project-uuid",
      "name": "Projeto demo",
      "slug": "projeto-demo",
      "status": "active"
    }
  ]
}
```

### `GET /projects/:id`

Busca um projeto específico ao qual o usuário pertence.

### `GET /recordings`

Lista as gravações do usuário atual.

Query params opcionais:

- `query`
- `tag`
- `projectId`
- `withoutProject`
- `_ts`

### `POST /recordings`

Cria uma gravação manualmente via JSON.

Body:

```json
{
  "title": "Nome da gravação",
  "projectId": null,
  "sourceType": "desktop_meeting",
  "captureMetadata": {
    "sourceApp": "teams",
    "platform": "windows",
    "captureMode": "system_and_mic",
    "helperVersion": "0.1.0",
    "windowTitle": "Daily sync"
  },
  "durationMs": 180000,
  "audioPath": "opcional"
}
```

### `POST /recordings/upload`

Endpoint principal para upload real de áudio.

Content-Type:

```text
multipart/form-data
```

Campos:

- `file` obrigatório
- `title` obrigatório
- `projectId` opcional
- `sourceType` opcional
- `captureMetadata` opcional em JSON stringificado
- `durationMs` opcional

### `GET /recordings/:id`

Busca uma gravação específica.

### `PATCH /recordings/:id`

Atualiza título e/ou vínculo opcional com projeto.

### `POST /recordings/:id/process`

Processa uma gravação a partir de `transcriptText`. Útil para testes internos, webhooks e reprocessamentos controlados.

### `POST /recordings/:id/chat`

Envia uma pergunta sobre a nota pronta.

Body:

```json
{
  "question": "Quais são os próximos passos?"
}
```

### `POST /recordings/:id/export`

Exporta a nota em `txt` ou `md`.

### `POST /webhooks/transcription`

Webhook genérico de transcrição.

### `POST /webhooks/assemblyai`

Webhook específico do AssemblyAI.

## Endpoints administrativos

Todos exigem:

- Bearer token Supabase válido
- usuário ativo em `public.users`
- perfil `admin` vinculado em `public.profiles`

Superfície atual:

- `GET /admin/me`
- `GET /admin/dashboard`
- `GET /admin/profiles`
- `POST /admin/profiles`
- `PATCH /admin/profiles/:id`
- `DELETE /admin/profiles/:id`
- `GET /admin/users`
- `POST /admin/users`
- `PATCH /admin/users/:id`
- `GET /admin/projects`
- `GET /admin/projects/:id`
- `POST /admin/projects`
- `PATCH /admin/projects/:id`
- `GET /admin/projects/:id/members`
- `POST /admin/projects/:id/members`
- `DELETE /admin/projects/:id/members/:userId`
- `GET /admin/recordings`
- `GET /admin/recordings/:id`
- `POST /admin/recordings/:id/reprocess`
- `GET /admin/jobs`
- `GET /admin/providers`
- `PATCH /admin/providers`

### Exemplo: criar projeto

```http
POST /admin/projects
Authorization: Bearer <token>
Content-Type: application/json
```

```json
{
  "name": "Projeto piloto comercial",
  "slug": "projeto-piloto-comercial"
}
```

### Exemplo: adicionar membro

```http
POST /admin/projects/{projectId}/members
Authorization: Bearer <token>
Content-Type: application/json
```

```json
{
  "userId": "b6c66a8d-2f30-40fd-bef5-1b75c31b86e3",
  "role": "member"
}
```

### Exemplo: detalhe admin de gravação

```http
GET /admin/recordings/{recordingId}
Authorization: Bearer <token>
```

Resposta típica:

```json
{
  "data": {
    "id": "recording-uuid",
    "projectId": null,
    "createdByUserId": "user-uuid",
    "sourceType": "desktop_meeting",
    "captureMetadata": {
      "sourceApp": "teams",
      "platform": "windows",
      "captureMode": "system_and_mic",
      "helperVersion": "0.1.0"
    },
    "status": "ready",
    "transcriptionProvider": "assemblyai",
    "transcriptionJobId": "job-123",
    "transcriptSegments": [],
    "summary": {
      "overview": "Resumo executivo"
    },
    "noteArtifact": {
      "highlights": ["Item 1"],
      "actionItems": ["Item 2"]
    },
    "lastError": null
  }
}
```

## Variáveis importantes

Backend:

```text
AI_PROVIDER=openai
OPENAI_API_KEY=...
TRANSCRIPTION_PROVIDER=assemblyai
ASSEMBLYAI_API_KEY=...
ASSEMBLYAI_SPEECH_MODEL=universal-2
SUPABASE_URL=...
SUPABASE_SERVICE_ROLE_KEY=...
SUPABASE_PERSISTENCE_MODE=supabase
SUPABASE_STORAGE_BUCKET=recordings
APP_BASE_URL=https://seu-backend.up.railway.app
```

Frontend admin:

```text
VITE_API_BASE_URL=...
VITE_SUPABASE_URL=...
VITE_SUPABASE_ANON_KEY=...
```

Flutter:

```text
--dart-define=BACKEND_BASE_URL=...
--dart-define=SUPABASE_URL=...
--dart-define=SUPABASE_ANON_KEY=...
```
