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
- superfícies operacionais para usuários, perfis, projetos, membros, gravações e jobs

## Meeting Capture Companion

- `Electron` com UI local mínima
- captura manual de áudio do sistema + microfone
- fila persistente de uploads para o backend
- tagging por `sourceApp` e `platform` para reuniões online

## Backend

- `Express` + `TypeScript`
- autenticação por Bearer token Supabase
- diretório de pessoas em `public.users`
- perfis de acesso em `public.profiles`
- repositório híbrido: memória para smoke/local, Supabase para persistência real
- `AiProvider` plugável: `mock` e `openai`

## Dados

Entidades centrais:

- `Project`
- `ProjectMember`
- `User`
- `Profile`
- `Recording`
- `CaptureMetadata`
- `TranscriptSegment`
- `Summary`
- `NoteArtifact`
- `ChatSession`
- `ChatMessage`

## Regras de acesso

- rotas do produto usam membership por projeto
- rotas `/admin/*` exigem token válido, usuário ativo em `public.users` e perfil `admin`
- admin tem visão global de projetos, membros, gravações e jobs

## Storage

- áudio persistido em `recordings/{projectId}/{recordingId}/{fileName}`
- metadados de transcrição ficam no topo do grafo da gravação
- reuniões online usam `sourceType=desktop_meeting` e `captureMetadata`

## Próximos passos naturais

- governança de perfis e trilha de auditoria para mudanças administrativas
- integração de testes E2E do admin-web
- observabilidade de pipeline e jobs
