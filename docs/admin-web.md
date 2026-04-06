# Admin Web

Aplicação separada em `admin-web/`, com autenticação Supabase e rotas reais de backoffice para o GravAção Admin com endosso SPOT.

## Stack

- `React`
- `TypeScript`
- `Vite`
- `react-router-dom`
- `@supabase/supabase-js`

## Variáveis de ambiente

- `VITE_API_BASE_URL`
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

## Fluxo de autenticação

1. O usuário faz login com email e senha via Supabase Auth.
2. O `admin-web` envia `Authorization: Bearer <access_token>` para o backend.
3. O backend valida o token, carrega a linha de `public.users` e o perfil relacionado em `public.profiles`.
4. O acesso administrativo só é liberado quando o perfil efetivo da pessoa é `admin` e o cadastro está ativo.

## Rotas

- `/login`
- `/users`
- `/profiles`
- `/projects`
- `/projects/:id/members`
- `/recordings`
- `/recordings/:id`
- `/jobs`

## Superfícies operacionais

### Usuários

- listagem com filtro por busca, perfil e status
- criação e edição com email, nome, senha, perfil e ativação
- leitura direta do perfil vinculado à pessoa

### Perfis

- catálogo de papéis de acesso como `admin` e `user`
- criação, edição e remoção de perfis customizados
- proteção visual para perfis sistêmicos

### Projetos

- listagem com filtro por `query` e `status`
- criação por modal
- edição de `name`, `slug` e `status`
- CTA direto para membros por projeto

### Membros

- seletor de projeto por rota
- listagem de usuário, `role` e `createdAt`
- adição por usuário cadastrado e `role`
- remoção com confirmação visual

### Gravações

- filtros reais por `query`, `projectId`, `status` e `userId`
- clique na linha abre detalhe administrativo
- detalhe mostra metadados, transcript, summary, highlights, action items e `lastError`
- ação explícita de reprocessamento

### Jobs

- espelho operacional de `/admin/jobs`
- deep link para `/recordings/:id`
- filtros reaproveitados para diagnóstico rápido

## Observações

- a experiência visual segue a base institucional da SPOT: branco, cinza estrutural, vermelho SPOT e tipografia `Roboto`
- o uso de transparência fica restrito ao shell e aos painéis principais
- a aplicação prioriza densidade operacional, contraste e legibilidade sobre decoração
