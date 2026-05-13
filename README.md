# Sonora

Aplicacao Laravel 12 unica para o produto Sonora/GravAcao, co-branded com SPOT.

O repositorio deixou de operar como monorepo. A superficie oficial agora fica no Laravel da raiz, com web, API e admin no mesmo runtime.

## Estrutura

- `app/Modules`: modulos de dominio da aplicacao principal.
  - `Identity`: usuarios, perfis, autenticacao e middleware de admin.
  - `Projects`: projetos e membros.
  - `Recordings`: gravacoes, transcript, notas e workspace web.
  - `Ai`: transcricao AssemblyAI e resumo OpenAI.
  - `Chat`: chat contextual de gravacoes.
  - `Admin`: superficies administrativas web e API.
  - `Integrations`: webhooks e importacao Supabase para SQL Server.
- `routes`: pontos unicos de rotas web, API e console.
- `resources`: views Blade e assets Vite.
- `database`: migrations, factories e seeders.
- `docs/future-flutter-app.md`: especificacao para uma implementacao futura do app Flutter.
- `docs/future-meeting-companion.md`: especificacao para uma implementacao futura do companion desktop.

## Como Rodar Localmente

```powershell
composer install
npm install
copy .env.example .env
php artisan key:generate
php artisan migrate
npm run build
php artisan serve
```

URLs principais:

- web: `http://localhost:8000/`
- API health: `http://localhost:8000/api/health`
- admin web: `http://localhost:8000/admin`

## Variaveis Principais

- `DB_CONNECTION=sqlsrv`: SQL Server e o banco oficial.
- `OPENAI_API_KEY`: necessario para resumo e chat reais.
- `ASSEMBLYAI_API_KEY`: necessario para transcricao real.
- `ASSEMBLYAI_WEBHOOK_SECRET`: segredo enviado e validado no webhook AssemblyAI.
- `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY`: usados apenas pelo importador temporario `data:sync-supabase`.

## Deploy

O nginx de producao deve apontar diretamente para `public/index.php`.

Assets Vite sao publicados em `public/build` no disco e acessados por URL como `/build/manifest.json` e `/build/assets/...`.

Detalhes operacionais estao em [`DEPLOY.md`](./DEPLOY.md).

## Validacao

```powershell
composer test
npm run build
```

## Aplicativos Futuros

O app Flutter e o companion desktop nao fazem parte do runtime atual. As diretrizes para reimplementacao futura estao em [`docs/future-flutter-app.md`](./docs/future-flutter-app.md) e [`docs/future-meeting-companion.md`](./docs/future-meeting-companion.md).
