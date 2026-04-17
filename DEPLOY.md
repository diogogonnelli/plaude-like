# Guia de Deploy (Laravel pela raiz do repositorio)

## Visao geral

O deploy de producao do Sonora deve seguir o mesmo modelo operacional do `assinatura-web`:

- o dominio publico aponta para a raiz do checkout em `/storage-apps/www/sonora`
- o `index.php` na raiz encaminha para `public/index.php`
- os assets do Laravel ficam em `/storage-apps/www/sonora/public/build`
- o pipeline gera `public/build` no CI e publica esse artefato no host
- o pipeline nao tenta alterar `nginx`; ele assume o mesmo contrato de host do `assinatura-web`

Layout esperado no host:

- `/storage-apps/www/sonora/.env`
- `/storage-apps/www/sonora/index.php`
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

- `root /storage-apps/www/sonora;`
- `try_files $uri $uri/ /index.php?$query_string;`

Isso permite que o `nginx` sirva diretamente:

- `/index.php` na raiz do checkout
- `/public/build/*`
- `/public/storage/*`

Exemplo de validacao:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Se o host ja estiver no mesmo modelo do `assinatura-web`, `https://<dominio>/public/build/manifest.json` deve responder `200` e `/` deve ser atendido pelo `index.php` da raiz.

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
   - `PUBLIC_PREFIX=public`
   - `APP_URL=https://<dominio>` quando `DEPLOY_APP_DOMAIN` estiver definido
7. executa `composer install`
8. atualiza `public/build` com o artefato do CI
9. roda `storage:link`, migrations, caches e seed de perfis
10. reinicia o `php-fpm` ou executa `post-deploy.sh`
11. executa smoke checks obrigatorios:
   - `/` precisa redirecionar para `/login`
   - `/login` precisa responder `200`
   - `/login` precisa referenciar assets em `/public/build/`
   - `/api/health` precisa responder `200`
   - `/public/build/manifest.json` precisa responder `200`

## Runtime `.env`

O arquivo persistente agora vive em:

```bash
/storage-apps/www/sonora/.env
```

No primeiro deploy, ele e criado a partir de `.env.example`. Se o host ainda tiver apenas `backend-laravel/.env`, o pipeline copia esse arquivo para a raiz antes de rodar o Laravel.

A chave relevante para o layout atual e:

```bash
PUBLIC_PREFIX=public
```

## Checklist pos-deploy

- `https://sonora.spotpromo.com.br/` redireciona para `/login`
- `https://sonora.spotpromo.com.br/login` responde `200`
- `https://sonora.spotpromo.com.br/api/health` responde `200`
- `index.php` existe na raiz
- `public/index.php` existe no host
- `public/build/manifest.json` existe no host
- `public/storage` existe ou foi recriado por `storage:link`
