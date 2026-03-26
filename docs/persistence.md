# Persistence And Deploy

## Target Setup

The backend now supports two persistence modes:

- `memory`: local development fallback
- `supabase`: real persistence using Supabase tables and RPC functions
- `auto`: uses Supabase when `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are present, otherwise falls back to memory

For test deployments, use `SUPABASE_PERSISTENCE_MODE=supabase`.

## Required Environment

Set these variables in the backend environment:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_PERSISTENCE_MODE=supabase`
- `SUPABASE_STORAGE_BUCKET=recordings`

Optional:

- `OPENAI_API_KEY`
- `AI_PROVIDER=openai`

## Database Bootstrap

Apply the migrations in order:

1. `supabase/migrations/0001_init.sql`
2. `supabase/migrations/0002_recording_graph_rpc.sql`

The first migration creates the tables, RLS policies, storage bucket and `updated_at` trigger.
The second migration adds RPC helpers used by the backend repository to persist and load a complete recording graph atomically.

## Storage Layout

Audio objects should be stored with a prefix that starts with the authenticated user id:

`{user-id}/{file-name}`

That keeps the storage policy aligned with the bucket rule in the migration.

## Deploy Test Flow

1. Create a Supabase project for test validation.
2. Apply both migrations.
3. Set the backend environment variables above.
4. Start the backend with Supabase mode enabled.
5. Use a real UUID as the request `x-user-id` if you want the Supabase rows to line up with auth-owned data.

## Notes

- The repository keeps the in-memory fallback for local smoke tests.
- The Supabase path is now the default when credentials are present and the mode is `auto`.
- The repository uses RPC helpers instead of ad hoc multi-table writes, so the full recording graph is persisted as one database operation.
