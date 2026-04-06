# Supabase

Esta pasta versiona o schema da persistência real do produto.

## Migrations

- `0001_init.sql`: tabelas base, vetores, RLS, storage bucket e trigger de `updated_at`
- `0002_recording_graph_rpc.sql`: RPCs para persistir e carregar o grafo completo da gravação
- `0003_transcription_metadata.sql`: metadados adicionais do pipeline de transcrição
- `0004_projects_and_memberships.sql`: projetos, memberships, `project_id`, `created_by_user_id` e RLS por projeto
- `0005_admin_users.sql`: allowlist de admins globais
- `0007_users_and_profiles.sql`: diretório de usuários, perfis de acesso e migração do modelo antigo de admins

## Storage

Os arquivos de áudio ficam em:

```text
{project-id}/{recording-id}/{file-name}
```

## Auth

- usuários entram via Supabase Auth
- o diretório de pessoas fica em `public.users`
- permissões do backoffice são lidas do vínculo de `public.users.profile_id` com `public.profiles`
- o backend usa o service role key para validar tokens e operar a superfície administrativa
