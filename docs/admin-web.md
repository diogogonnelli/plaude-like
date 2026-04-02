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
3. O backend valida o token e verifica se o `user_id` existe em `public.admin_users`.
4. Se a conta não estiver allowlisted, a UI mostra tela de acesso negado.

## Rotas

- `/login`
- `/projects`
- `/projects/:id/members`
- `/recordings`
- `/recordings/:id`
- `/jobs`
- `/providers`

## Superfícies operacionais

### Projetos

- listagem com filtro por `query` e `status`
- criação por modal
- edição de `name`, `slug` e `status`
- CTA direto para membros por projeto

### Membros

- seletor de projeto por rota
- listagem de `userId`, `role` e `createdAt`
- adição por `userId` bruto e `role`
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

### Providers

- leitura da configuração exposta pelo backend
- útil para validação de ambiente em operação

## Observações

- a experiência visual segue a base institucional da SPOT: branco, cinza estrutural, vermelho SPOT e tipografia `Roboto`
- o uso de transparência fica restrito ao shell e aos painéis principais
- a aplicação prioriza densidade operacional, contraste e legibilidade sobre decoração
