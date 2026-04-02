# Admin Web

Aplicacao web separada para backoffice em `admin-web/`.

Objetivos do scaffold inicial:

- dashboard operacional
- CRUD de projetos
- visualizacao de membros por projeto
- listagem de gravacoes
- listagem de jobs de transcricao
- base desktop-first para evolucao do backoffice

Stack inicial:

- `React`
- `TypeScript`
- `Vite`

Pontos de integracao planejados:

- `GET /admin/dashboard`
- `GET /admin/projects`
- `POST /admin/projects`
- `PATCH /admin/projects/:id`
- `GET /admin/projects/:id/members`
- `POST /admin/projects/:id/members`
- `DELETE /admin/projects/:id/members/:userId`
- `GET /admin/recordings`
- `GET /admin/recordings/:id`
- `POST /admin/recordings/:id/reprocess`
- `GET /admin/jobs`
- `GET /admin/providers`
- `PATCH /admin/providers`
