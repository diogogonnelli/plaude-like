# Guia de Deploy (Laravel pela raiz do repositorio)

## Visao geral

O deploy de producao do Sonora segue o mesmo molde operacional do `assinatura-web`:

- o dominio publico aponta para a **raiz do checkout** em `/storage-apps/www/sonora`
- o `index.php` na raiz encaminha para `backend-laravel/public/index.php`
- os assets do Laravel continuam fisicamente em `backend-laravel/public/build`
- o pipeline gera `public/build` no CI e publica esse artefato no host
- o pipeline **nao** altera configuracao de `nginx` no servidor

Layout esperado no host:

- `/storage-apps/www/sonora/index.php`
- `/storage-apps/www/sonora/backend-laravel`
- `/storage-apps/www/sonora/backend-laravel/public/build`

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

- `root /storage-apps/www/sonora;`
- `try_files $uri $uri/ /index.php?$query_string;`

Isso permite que o `nginx` sirva diretamente:

- `/index.php` na raiz do checkout
- `/backend-laravel/public/build/*`
- `/backend-laravel/public/storage/*`

Exemplo de validacao:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

O arquivo `deploy/nginx/sonora-app.conf.example` agora e apenas legado. Ele documenta o fluxo antigo do Flutter Web estatico e nao deve ser usado como raiz publica principal.

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

1. gera `backend-laravel/public/build` em uma etapa `node:20`
2. publica esse build como artefato do CI
3. envia o artefato `.tar.gz` para o host
4. por SSH, sincroniza o checkout com `origin/main`
5. preserva ou cria `backend-laravel/.env`
6. fixa:
   - `APP_ENV=production`
   - `APP_DEBUG=false`
   - `PUBLIC_PREFIX=/backend-laravel/public`
   - `APP_URL=https://<dominio>` quando `DEPLOY_APP_DOMAIN` estiver definido
7. executa `composer install`
8. atualiza `backend-laravel/public/build` com o artefato do CI
9. roda `storage:link`, migrations, caches e seed de perfis
10. reinicia o `php-fpm` ou executa `post-deploy.sh`
11. executa smoke checks obrigatorios:
   - `/` precisa redirecionar para `/login`
   - `/login` precisa responder `200`
   - `/api/health` precisa responder `200`

## Backend `.env`

O arquivo persistente continua em:

```bash
/storage-apps/www/sonora/backend-laravel/.env
```

No primeiro deploy, ele e criado a partir de `backend-laravel/.env.example`. Depois disso, o pipeline preserva o arquivo e atualiza apenas as chaves operacionais do deploy.

A nova chave relevante para publicacao pela raiz e:

```bash
PUBLIC_PREFIX=/backend-laravel/public
```

Ela controla as URLs geradas para:

- assets do Vite em producao
- disco `public` do Laravel (`/storage`)

## Checklist pos-deploy

- `https://sonora.spotpromo.com.br/` redireciona para `/login`
- `https://sonora.spotpromo.com.br/login` responde `200`
- `https://sonora.spotpromo.com.br/api/health` responde `200`
- `backend-laravel/public/build/manifest.json` existe no host
- `backend-laravel/public/storage` existe ou foi recriado por `storage:link`
