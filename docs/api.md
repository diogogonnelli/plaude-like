# API

Documentacao pratica da API HTTP do backend `Plaude Like`.

Base URL de exemplo:

```text
https://plaude-like-production.up.railway.app
```

Documentacao navegavel quando o backend estiver no ar:

```text
/docs
```

Schema OpenAPI bruto:

```text
/openapi.json
```

## Convencoes gerais

- Content-Type padrao para endpoints JSON: `application/json`
- Header de identificacao do usuario:

```text
x-user-id: demo-user
```

- Resposta de erro padrao:

```json
{
  "error": "Mensagem do erro",
  "code": "error_code",
  "details": {}
}
```

## Status da gravacao

Valores possiveis de `status`:

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
  "userId": "demo-user",
  "createdByUserId": "demo-user",
  "projectId": "project-demo",
  "title": "Audio curto",
  "sourceType": "upload",
  "status": "processing_transcript",
  "createdAt": "2026-03-31T21:00:00.000Z",
  "updatedAt": "2026-03-31T21:00:05.000Z",
  "durationMs": 180000,
  "audioPath": "uuid/recording-id/audio-curto-3min.m4a",
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

## Endpoints

### `GET /projects`

Lista os projetos do usuario atual.

Resposta `200`:

```json
{
  "data": [
    {
      "id": "project-demo",
      "name": "Projeto demo",
      "slug": "projeto-demo",
      "status": "active"
    }
  ]
}
```

### `GET /projects/:id`

Busca um projeto especifico ao qual o usuario pertence.

### `GET /health`

Healthcheck simples do servico.

Resposta `200`:

```json
{
  "ok": true,
  "service": "plaude-like-backend"
}
```

### `GET /recordings`

Lista as gravacoes do usuario atual.

Query params:

- `query` opcional
- `tag` opcional
- `_ts` opcional, usado para cache-busting no frontend

Exemplo:

```http
GET /recordings?query=reuniao
x-user-id: demo-user
```

Resposta `200`:

```json
{
  "data": [
    {
      "id": "uuid",
      "title": "Audio curto",
      "status": "ready"
    }
  ]
}
```

### `POST /recordings`

Cria uma gravacao manualmente via JSON. Esse endpoint existe por compatibilidade e por fluxos internos; para upload real de audio use `POST /recordings/upload`.

Body:

```json
{
  "title": "Nome da gravacao",
  "projectId": "project-demo",
  "sourceType": "upload",
  "durationMs": 180000,
  "audioPath": "opcional"
}
```

Resposta `201`:

```json
{
  "data": { "id": "uuid", "status": "uploaded" },
  "upload": {
    "bucket": "recordings",
    "objectPath": "uuid.m4a"
  }
}
```

### `POST /recordings/upload`

Endpoint principal para upload real de audio.

Content-Type:

```text
multipart/form-data
```

Campos:

- `file` obrigatorio
- `title` obrigatorio
- `projectId` obrigatorio
- `sourceType` opcional, `upload` ou `microphone`
- `durationMs` opcional

Exemplo de resposta `201`:

```json
{
  "data": {
    "id": "uuid",
    "title": "audio-curto-3min.m4a",
    "status": "processing_transcript",
    "transcriptionProvider": "assemblyai"
  }
}
```

Comportamento:

- cria a gravacao
- persiste o audio original
- envia o arquivo para o provider de transcricao
- retorna imediatamente com status assincrono

### `GET /recordings/:id`

Busca uma gravacao especifica.

Resposta `200`:

```json
{
  "data": {
    "id": "uuid",
    "status": "ready",
    "transcriptSegments": [],
    "summary": {},
    "noteArtifact": {}
  }
}
```

Resposta `404`:

```json
{
  "error": "Recording not found",
  "code": "recording_not_found"
}
```

### `POST /recordings/:id/process`

Processa uma gravacao a partir de `transcriptText`. Hoje esse endpoint e mais util para testes internos e webhooks do que para o fluxo de upload real.

Body:

```json
{
  "transcriptText": "Speaker 1: ...\nSpeaker 2: ..."
}
```

Resposta `200`:

```json
{
  "data": {
    "id": "uuid",
    "status": "ready"
  }
}
```

### `POST /recordings/:id/chat`

Envia uma pergunta sobre a nota.

Body:

```json
{
  "question": "Quais sao os proximos passos?"
}
```

Resposta `200`:

```json
{
  "recordingId": "uuid",
  "answer": {
    "id": "uuid",
    "role": "assistant",
    "content": "Resposta do assistente",
    "createdAt": "2026-03-31T21:10:00.000Z",
    "citations": [
      {
        "segmentId": "uuid",
        "startMs": 0,
        "endMs": 12000,
        "quote": "Trecho citado"
      }
    ]
  },
  "session": {
    "id": "uuid",
    "recordingId": "uuid",
    "messages": []
  }
}
```

### `POST /recordings/:id/export`

Gera exportacao textual da nota.

Body:

```json
{
  "format": "md"
}
```

Formatos aceitos:

- `txt`
- `md`

Resposta `200`:

```json
{
  "data": {
    "format": "md",
    "fileName": "uuid.md",
    "contentType": "text/markdown",
    "body": "# Titulo da nota\n..."
  }
}
```

### `POST /webhooks/transcription`

Webhook generico de transcricao, mantido para integracoes e testes.

Body:

```json
{
  "provider": "generic",
  "event": "transcript.completed",
  "recordingId": "uuid",
  "userId": "demo-user",
  "transcriptText": "Speaker 1: ...",
  "segments": [],
  "isFinal": true,
  "status": "completed",
  "requestId": "opcional"
}
```

Resposta `202`:

```json
{
  "accepted": true,
  "provider": "generic",
  "event": "transcript.completed",
  "requestId": "opcional",
  "data": {
    "id": "uuid",
    "status": "ready"
  }
}
```

### `POST /webhooks/assemblyai`

Webhook especifico do AssemblyAI.

Query params obrigatorios:

- `recordingId`
- `userId`

Body minimo esperado:

```json
{
  "transcript_id": "assemblyai-transcript-id",
  "status": "completed"
}
```

Comportamento:

- quando `status=completed`, o backend busca a transcricao final no AssemblyAI
- quando `status=error`, marca a gravacao como `failed`

Resposta `202`:

```json
{
  "accepted": true,
  "provider": "assemblyai",
  "status": "completed"
}
```

## Variaveis importantes para os endpoints reais

No backend:

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

## Endpoints administrativos

Superficie administrativa atual:

- `GET /admin/dashboard`
- `GET /admin/projects`
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

Esses endpoints foram pensados para o `admin-web/`.

## Observacoes

- `POST /recordings/upload` e o endpoint recomendado para audio real.
- O frontend atual faz polling de `GET /recordings/:id` ate a nota ficar `ready` ou `failed`.
- `POST /recordings` e `POST /recordings/:id/process` ainda existem para compatibilidade, testes e fluxos internos.
