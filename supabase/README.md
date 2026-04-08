# Supabase

Esta pasta versiona o schema da persistencia real do produto.

## Migrations

- `0001_init.sql`: tabelas base, vetores, RLS, storage bucket e trigger de `updated_at`
- `0002_recording_graph_rpc.sql`: RPCs para persistir e carregar o grafo completo da gravacao
- `0003_transcription_metadata.sql`: metadados adicionais do pipeline de transcricao
- `0004_projects_and_memberships.sql`: projetos, memberships, `project_id`, `created_by_user_id` e RLS por projeto
- `0005_admin_users.sql`: allowlist de admins globais
- `0007_users_and_profiles.sql`: diretorio de usuarios, perfis de acesso e migracao do modelo antigo de admins
- `0008_desktop_meeting_capture.sql`: `desktop_meeting`, `capture_metadata` e atualizacao das RPCs
- `0009_owner_based_recordings.sql`: `project_id` opcional e visibilidade owner-based para gravacoes

## Storage

Os arquivos de audio ficam em:

```text
{created-by-user-id}/{recording-id}/{file-name}
```

## Auth

- usuarios entram via Supabase Auth
- o diretorio de pessoas fica em `public.users`
- permissoes do backoffice sao lidas do vinculo de `public.users.profile_id` com `public.profiles`
- o backend usa o service role key para validar tokens e operar a superficie administrativa
