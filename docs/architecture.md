# Arquitetura v2

## App Flutter

- `Flutter` com `go_router` e `provider`
- shell mobile-first com `Home`, `Biblioteca` e `Ajustes`
- detalhe e chat contextual por gravação
- autenticação via `supabase_flutter` com email e senha
- fallback demo apenas quando o ambiente de auth/backend não estiver configurado para desenvolvimento

## Admin Web

- `React` + `TypeScript` + `Vite`
- `react-router-dom` para rotas reais
- `@supabase/supabase-js` para login e bootstrap de sessão
- superfícies operacionais para projetos, membros, gravações, jobs e providers

## Backend

- `Express` + `TypeScript`
- autenticação por Bearer token Supabase
- allowlist admin em `public.admin_users`
- repositório híbrido: memória para smoke/local, Supabase para persistência real
- `AiProvider` plugável: `mock` e `openai`

## Dados

Entidades centrais:

- `Project`
- `ProjectMember`
- `Recording`
- `TranscriptSegment`
- `Summary`
- `NoteArtifact`
- `ChatSession`
- `ChatMessage`

## Regras de acesso

- rotas do produto usam membership por projeto
- rotas `/admin/*` exigem token válido e presença em `admin_users`
- admin tem visão global de projetos, membros, gravações e jobs

## Storage

- áudio persistido em `recordings/{projectId}/{recordingId}/{fileName}`
- metadados de transcrição ficam no topo do grafo da gravação

## Próximos passos naturais

- provisionamento operacional de `admin_users`
- integração de testes E2E do admin-web
- observabilidade de pipeline e jobs
