# Guia de Deploy (Laravel com docroot em `public/`)

## Visao geral

O deploy de producao do Sonora agora publica o Laravel diretamente pela pasta `public/` do checkout:

- o dominio publico deve apontar para `/storage-apps/www/sonora/public`
- o `index.php` publico fica em `/storage-apps/www/sonora/public/index.php`
- os assets do Laravel ficam em `/storage-apps/www/sonora/public/build`
- o pipeline gera `public/build` no CI e publica esse artefato no host
- o pipeline tenta reconciliar a configuracao do `nginx` para o layout novo quando o usuario de deploy tem privilegio suficiente

Layout esperado no host:

- `/storage-apps/www/sonora/.env`
- `/storage-apps/www/sonora/public/index.php`
- `/storage-apps/www/sonora/public/build`

## Pre-requisitos do host

- Linux com `nginx`
- `git`
- `curl`
- `systemd`
- `php` e `composer`
- usuario de deploy com acesso SSH
- usuario de deploy com permissao para reiniciar o `php-fpm` ou executar um `post-deploy.sh`
- acesso SSH do host ao repositorio Bitbucket para `git clone` e `git fetch`

## Variaveis do Bitbucket

Defina no repositorio ou em `Deployments > Production`, no minimo:

- `SSH_KEY_webrun01`: chave privada em base64 usada pelo pipeline para conectar no host
- `DEPLOY_APP_DOMAIN`: opcional. Se informado, o deploy atualiza `APP_URL=https://<dominio>`

Itens fixos no pipeline:

- host SSH: `172.18.0.86`
- usuario SSH: `spotti`
- repositorio sincronizado no host: `git@bitbucket.org:spotpromo/sonora.git`
- caminho do app no host: `/storage-apps/www/sonora`

## Configuracao do nginx

Use `deploy/nginx/sonora-laravel.conf.example` como base. O ponto importante e:

- `root /storage-apps/www/sonora/public;`
- `try_files $uri $uri/ /index.php?$query_string;`

Isso permite que o `nginx` sirva diretamente:

- `/index.php` pela pasta `public/`
- `/build/*`
- `/storage/*`

Exemplo de validacao:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Se o host ainda estiver apontando para a raiz do repositorio ou para `/public` como subpasta URL, o sintoma esperado e `403` em `/` ou assets servidos em `/public/build/*`. Esse estado e legado e deve ser removido.

## Primeiro deploy no host

Bootstrap recomendado antes do primeiro deploy:

```bash
sudo mkdir -p /storage-apps/www/sonora
sudo chown -R spotti:spotti /storage-apps/www/sonora
```

Se quiser manter um hook no mesmo estilo do `assinatura-web`:

```bash
cat >/home/spotti/post-deploy.sh <<'BASH'
#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${1:-/storage-apps/www/sonora}"
sudo /bin/systemctl restart php8.2-fpm
BASH

chmod +x /home/spotti/post-deploy.sh
```

Se o deploy rodar como `spotti`, libere ao menos:

```bash
sudo visudo
```

Adicione algo como:

```text
spotti ALL=NOPASSWD: /bin/systemctl restart php8.2-fpm
```

## Como o pipeline faz o deploy

Na `main`, o pipeline:

1. gera `public/build` em uma etapa `node:20`
2. publica esse build como artefato do CI
3. envia o artefato `.tar.gz` para o host
4. por SSH, sincroniza o checkout com `origin/main`
5. preserva `/.env`, ou migra automaticamente `backend-laravel/.env` legado para `/.env` quando necessario
6. fixa:
   - `APP_ENV=production`
   - `APP_DEBUG=false`
   - `PUBLIC_PREFIX=` (vazio)
   - `APP_URL=https://<dominio>` quando `DEPLOY_APP_DOMAIN` estiver definido
7. executa `composer install`
8. atualiza `public/build` com o artefato do CI
9. roda `storage:link`, migrations, caches e seed de perfis
10. tenta reconciliar a configuracao do `nginx` para `root /storage-apps/www/sonora/public`
11. reinicia o `php-fpm` ou executa `post-deploy.sh`
12. executa smoke checks obrigatorios:
   - `/` precisa redirecionar para `/login`
   - `/login` precisa responder `200`
   - `/api/health` precisa responder `200`

## Runtime `.env`

O arquivo persistente agora vive em:

```bash
/storage-apps/www/sonora/.env
```

No primeiro deploy, ele e criado a partir de `.env.example`. Se o host ainda tiver apenas `backend-laravel/.env`, o pipeline copia esse arquivo para a raiz antes de rodar o Laravel.

A chave relevante para o layout atual e:

```bash
PUBLIC_PREFIX=
```

## Checklist pos-deploy

- `https://sonora.spotpromo.com.br/` redireciona para `/login`
- `https://sonora.spotpromo.com.br/login` responde `200`
- `https://sonora.spotpromo.com.br/api/health` responde `200`
- `public/build/manifest.json` existe no host
- `public/storage` existe ou foi recriado por `storage:link`
