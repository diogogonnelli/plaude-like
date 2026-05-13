# API

API HTTP servida pelo Laravel em `/api`.

## Autenticacao

Use token Sanctum retornado por `POST /api/auth/login`:

```http
Authorization: Bearer <token>
Accept: application/json
```

## Health

```http
GET /api/health
```

Resposta:

```json
{"status":"ok"}
```

## Auth

- `POST /api/auth/login`
- `POST /api/auth/logout`
- `GET /api/auth/me`

Payload de login:

```json
{
  "email": "usuario@empresa.com",
  "password": "secret",
  "device_name": "browser"
}
```

## Gravacoes

- `GET /api/recordings`
- `POST /api/recordings`
- `GET /api/recordings/{recording}`
- `PATCH /api/recordings/{recording}`
- `DELETE /api/recordings/{recording}`
- `POST /api/recordings/{recording}/upload`
- `GET /api/recordings/{recording}/audio`
- `POST /api/recordings/{recording}/process`
- `POST /api/recordings/{recording}/reprocess`
- `GET /api/recordings/{recording}/export/{txt|md}`

Criacao:

```json
{
  "title": "Reuniao semanal",
  "project_id": null,
  "source_type": "upload",
  "capture_metadata": null,
  "duration_ms": 120000
}
```

`project_id`, quando informado, precisa pertencer a um projeto do usuario autenticado.

## Projetos

- `GET /api/projects`
- `POST /api/projects`
- `GET /api/projects/{project}`
- `PATCH /api/projects/{project}`
- `GET /api/projects/{project}/members`
- `POST /api/projects/{project}/members`
- `DELETE /api/projects/{project}/members/{user}`

## Chat

- `GET /api/recordings/{recording}/chat`
- `POST /api/recordings/{recording}/chat`

Payload:

```json
{
  "message": "Quais foram os proximos passos?"
}
```

## Admin

Rotas sob `/api/admin/*` exigem token Sanctum de usuario com perfil `admin`.

- usuarios: `/api/admin/users`
- perfis: `/api/admin/profiles`
- projetos: `/api/admin/projects`
- gravacoes: `/api/admin/recordings`

## Webhook AssemblyAI

```http
POST /api/webhooks/assemblyai
X-AssemblyAI-Webhook-Secret: <ASSEMBLYAI_WEBHOOK_SECRET>
```

Se `ASSEMBLYAI_WEBHOOK_SECRET` estiver configurado, chamadas com segredo ausente ou invalido sao rejeitadas com 403.
