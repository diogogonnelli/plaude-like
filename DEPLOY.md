# Guia de Deploy

## Visao Geral

O Sonora roda como uma aplicacao Laravel unica. Em producao, o nginx deve apontar diretamente para:

```text
/storage-apps/www/sonora/public/index.php
```

O repositorio no host continua em `/storage-apps/www/sonora`, mas o document root publico deve ser `/storage-apps/www/sonora/public`.

## Layout Esperado

- `/storage-apps/www/sonora/.env`
- `/storage-apps/www/sonora/artisan`
- `/storage-apps/www/sonora/public/index.php`
- `/storage-apps/www/sonora/public/build/manifest.json`
- `/storage-apps/www/sonora/storage`
- `/storage-apps/www/sonora/bootstrap/cache`

## Variaveis de Producao

Obrigatorias ou esperadas:

- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_URL=https://<dominio>`
- `DB_CONNECTION=sqlsrv`
- `OPENAI_API_KEY`
- `ASSEMBLYAI_API_KEY`
- `ASSEMBLYAI_WEBHOOK_SECRET`

Nao use `PUBLIC_PREFIX`; assets devem responder em `/build/...`.

## Pipeline

Na branch `main`, o Bitbucket Pipelines:

1. instala dependencias Node;
2. roda `npm run build`;
3. publica `public/build` como artefato;
4. sincroniza o checkout no host;
5. preserva o `.env` existente ou cria a partir de `.env.example`;
6. fixa `APP_ENV=production`, `APP_DEBUG=false` e `APP_MAINTENANCE_DRIVER=file`;
7. roda `composer install --no-dev`;
8. atualiza `public/build`;
9. prepara permissao de `storage` e `bootstrap/cache`;
10. roda migrations, caches e `ProfileSeeder`;
11. reinicia PHP-FPM ou executa `/home/spotti/post-deploy.sh`;
12. valida `/`, `/build/manifest.json` e referencias a `/build/`.

## Checklist Pos-Deploy

- `https://<dominio>/` responde 200.
- `https://<dominio>/login` usa as rotas Laravel normais.
- `https://<dominio>/admin` exige usuario autenticado com perfil admin.
- `https://<dominio>/api/health` responde JSON `{"status":"ok"}`.
- `https://<dominio>/build/manifest.json` responde 200.
- O HTML renderizado referencia assets em `/build/assets/...`.
