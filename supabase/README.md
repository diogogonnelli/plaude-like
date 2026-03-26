# Supabase

Esta pasta versiona o schema inicial do produto e o caminho de deploy real para teste.

- `migrations/0001_init.sql`: tabelas, enum de status, vetores, RLS, storage bucket e trigger de `updated_at`
- `migrations/0002_recording_graph_rpc.sql`: RPCs para persistir e carregar o grafo completo de uma gravação
- Bucket esperado: `recordings`

Para bootstrap de teste, leia [`docs/persistence.md`](../docs/persistence.md).
