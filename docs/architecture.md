# Arquitetura v1

## App

- `Flutter` com `go_router` e `provider`
- fallback local para manter UX funcional sem backend
- gravação por `record`, playback local por `just_audio` e upload por `file_picker`

## Backend

- `Express` + `TypeScript`
- repositório com fallback em memória, mas com caminho real para `Supabase` via RPC
- `AiProvider` plugável: `mock` e `openai`
- exportação estruturada em `txt` e `md`

## Dados

Entidades centrais:

- `Recording`
- `TranscriptSegment`
- `Summary`
- `NoteArtifact`
- `ChatSession`
- `ChatMessage`
- `recording_chunks` para retrieval com `pgvector`

## Próximos passos naturais

- conectar webhook real de STT/diarização
- implementar upload binário para bucket assinado
- adicionar auth real no app via `supabase_flutter`
- persistir embeddings e retrieval híbrido real no chat
