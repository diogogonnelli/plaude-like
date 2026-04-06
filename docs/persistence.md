# Persistence And Deploy

## Target setup

Modos de persistência do backend:

- `memory`: fallback local
- `supabase`: persistência real
- `auto`: usa Supabase quando `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` estão presentes

Para validar a stack real, use:

```text
SUPABASE_PERSISTENCE_MODE=supabase
```

## Variáveis obrigatórias

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_PERSISTENCE_MODE=supabase`
- `SUPABASE_STORAGE_BUCKET=recordings`

## Bootstrap do banco

Aplicar as migrations em ordem:

1. `supabase/migrations/0001_init.sql`
2. `supabase/migrations/0002_recording_graph_rpc.sql`
3. `supabase/migrations/0003_transcription_metadata.sql`
4. `supabase/migrations/0004_projects_and_memberships.sql`
5. `supabase/migrations/0005_admin_users.sql`
6. `supabase/migrations/0007_users_and_profiles.sql`
7. `supabase/migrations/0008_desktop_meeting_capture.sql`
8. `supabase/migrations/0009_owner_based_recordings.sql`

## Storage layout

Os objetos de áudio ficam em:

```text
{created-by-user-id}/{recording-id}/{file-name}
```

Isso mantém o storage alinhado com o dono da gravação, mesmo quando não houver projeto vinculado.

## Auth e admin

- usuários finais entram via Supabase Auth
- o backend valida Bearer JWT nas rotas do produto e do admin
- `public.users` guarda o cadastro de pessoas autenticadas
- `public.profiles` guarda os papéis de acesso
- o perfil `admin` define acesso ao backoffice

## Fluxo recomendado de deploy

1. Criar projeto Supabase.
2. Aplicar as migrations.
3. Provisionar usuários no Auth.
4. Garantir que os usuários estejam sincronizados em `public.users` e atribuir o perfil correto.
5. Subir backend com `SUPABASE_PERSISTENCE_MODE=supabase`.
6. Configurar `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` e `VITE_API_BASE_URL` no `admin-web`.
7. Configurar `BACKEND_BASE_URL`, `SUPABASE_URL` e `SUPABASE_ANON_KEY` no app Flutter.
