# Admin Web

Aplicacao separada em `admin-web/`, com autenticacao Supabase e rotas reais de backoffice para o GravAcao Admin com endosso SPOT.

## Stack

- `React`
- `TypeScript`
- `Vite`
- `react-router-dom`
- `@supabase/supabase-js`

## Variaveis de ambiente

- `VITE_API_BASE_URL`
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

Em producao, o `admin-web` deve ser publicado em subdominio dedicado, por exemplo `https://admin.seudominio.com`, consumindo a API por `https://seudominio.com/api`.

## Fluxo de autenticacao

1. O usuario faz login com email e senha via Supabase Auth.
2. O `admin-web` envia `Authorization: Bearer <access_token>` para o backend.
3. O backend valida o token, carrega a linha de `public.users` e o perfil relacionado em `public.profiles`.
4. O acesso administrativo so e liberado quando o perfil efetivo da pessoa e `admin` e o cadastro esta ativo.

## Rotas

- `/login`
- `/users`
- `/profiles`
- `/projects`
- `/projects/:id/members`
- `/recordings`
- `/recordings/:id`
- `/jobs`

## Superficies operacionais

### Usuarios

- listagem com filtro por busca, perfil e status
- criacao e edicao com email, nome, senha, perfil e ativacao
- leitura direta do perfil vinculado a pessoa

### Perfis

- catalogo de papeis de acesso como `admin` e `user`
- criacao, edicao e remocao de perfis customizados
- protecao visual para perfis sistemicos

### Projetos

- listagem com filtro por `query` e `status`
- criacao por modal
- edicao de `name`, `slug` e `status`
- CTA direto para membros por projeto

### Membros

- seletor de projeto por rota
- listagem de usuario, `role` e `createdAt`
- adicao por usuario cadastrado e `role`
- remocao com confirmacao visual

### Gravacoes

- filtros reais por `query`, `projectId`, `withoutProject`, `status` e `userId`
- clique na linha abre detalhe administrativo
- detalhe mostra metadados, transcript, summary, highlights, action items, `lastError` e edicao do vinculo opcional com projeto
- acao explicita de reprocessamento

### Jobs

- espelho operacional de `/admin/jobs`
- deep link para `/recordings/:id`
- filtros reaproveitados para diagnostico rapido

## Observacoes

- a experiencia visual segue a base institucional da SPOT: branco, cinza estrutural, vermelho SPOT e tipografia `Roboto`
- o uso de transparencia fica restrito ao shell e aos paineis principais
- a aplicacao prioriza densidade operacional, contraste e legibilidade sobre decoracao
