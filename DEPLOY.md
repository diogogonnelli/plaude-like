# Guia de Deploy (Bitbucket Pipelines + Linux + Nginx)

## Visao geral da arquitetura

- monorepo com `backend`, `app` e `admin-web`
- `backend` Node/Express como servico `systemd`
- `app` Flutter Web publicado como estatico em `dist-app/`
- `admin-web` React/Vite publicado como estatico em `dist-admin/`
- `nginx` servindo os dois frontends e fazendo proxy de `/api` para o backend

Layout esperado no servidor:

- `/srv/plaude-like/current`
- `/srv/plaude-like/dist-app`
- `/srv/plaude-like/dist-admin`
- `/srv/plaude-like/shared/backend.env`
- `/srv/plaude-like/shared/uploads`
- `/srv/plaude-like/shared/logs`

## 1. Pre-requisitos do host

- Linux com `nginx`
- Node.js 20+ e `npm`
- `git`
- `curl`
- `systemd`
- usuario de deploy com acesso SSH
- usuario de deploy com permissao para `sudo systemctl restart plaude-like-backend` e `sudo systemctl reload nginx`
- acesso SSH do host ao repositorio Bitbucket para `git clone` e `git fetch`

## 2. Variaveis do Bitbucket

Defina no repositorio ou em `Deployments > Production`, no minimo:

- `SSH_KEY_LINUX_HOST`: chave privada em base64 usada pelo pipeline para conectar no host
  - compatibilidade: se sua workspace ja usa a variavel legada `SSH_KEY_webrun01`, o pipeline tambem aceita esse nome
- `DEPLOY_HOST`: IP ou hostname do servidor
- `DEPLOY_USER`: usuario SSH do servidor
- `DEPLOY_APP_PATH`: caminho base do projeto no host. Ex.: `/srv/plaude-like`
- `DEPLOY_APP_DOMAIN`: dominio principal. Ex.: `seudominio.com`
- `DEPLOY_ADMIN_DOMAIN`: subdominio do admin. Ex.: `admin.seudominio.com`
- `DEPLOY_BACKEND_SERVICE`: opcional. Default `plaude-like-backend`
- `DEPLOY_BACKEND_PORT`: opcional. Default `8787`
- `DEPLOY_KNOWN_HOST`: opcional. Linha pronta de `known_hosts` para evitar `ssh-keyscan`

Variaveis de build dos frontends:

- `APP_BACKEND_BASE_URL=https://seudominio.com/api`
- `APP_SUPABASE_URL`
- `APP_SUPABASE_ANON_KEY`
- `APP_FIREBASE_API_KEY`
- `APP_FIREBASE_PROJECT_ID`
- `APP_FIREBASE_MESSAGING_SENDER_ID`
- `APP_FIREBASE_ANDROID_APP_ID`
- `APP_FIREBASE_IOS_APP_ID`
- `APP_FIREBASE_STORAGE_BUCKET`
- `ADMIN_API_BASE_URL=https://seudominio.com/api`
- `ADMIN_VITE_SUPABASE_URL`
- `ADMIN_VITE_SUPABASE_ANON_KEY`

## 3. Primeiro deploy no host

1. Copie e ajuste o unit file em `deploy/systemd/plaude-like-backend.service.example`.
2. Instale o servico:

```bash
sudo cp deploy/systemd/plaude-like-backend.service.example /etc/systemd/system/plaude-like-backend.service
sudo systemctl daemon-reload
sudo systemctl enable plaude-like-backend
```

3. Copie e ajuste os arquivos de `nginx`:

- `deploy/nginx/plaude-like-app.conf.example`
- `deploy/nginx/plaude-like-admin.conf.example`

4. Ative os sites e valide:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

5. Garanta que o usuario do servidor consegue executar:

```bash
git ls-remote git@bitbucket.org:workspace/repositorio.git
sudo systemctl restart plaude-like-backend
sudo systemctl reload nginx
```

## 4. Como o pipeline faz o deploy

Na `main`, o pipeline:

1. valida `backend`, `app` e `admin-web`
2. gera os artefatos `app/build/web` e `admin-web/dist`
3. envia dois `.tar.gz` para o host
4. executa `scripts/deploy-linux-host.sh` por SSH
5. no host, o script:
   - sincroniza `current/` com `origin/main`
   - cria ou preserva `shared/backend.env`
   - fixa `HOST=127.0.0.1`, `PORT`, `APP_BASE_URL=https://<dominio>/api` e `TRUST_PROXY=true`
   - roda `npm ci`, `npm run build` e `npm prune --omit=dev` no backend
   - publica os dois frontends
   - reinicia o backend
   - recarrega o `nginx`
   - valida `http://127.0.0.1:<porta>/health`

## 5. Backend `.env`

O arquivo persistente fica em:

```bash
/srv/plaude-like/shared/backend.env
```

No primeiro deploy, ele e criado a partir de `backend/.env.example`. Depois disso, o pipeline preserva o arquivo e atualiza somente:

- `HOST`
- `PORT`
- `APP_BASE_URL`
- `TRUST_PROXY`

As demais chaves devem ser mantidas manualmente no host, como:

- `OPENAI_API_KEY`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- credenciais do Firebase

## 6. Rollback basico

1. No host, volte o repositorio para o commit desejado em `current/`.
2. Republique os artefatos estaticos correspondentes, se necessario.
3. Reinicie o backend e recarregue o `nginx`.

Exemplo:

```bash
cd /srv/plaude-like/current
git checkout <sha>
cd backend
npm ci
npm run build
npm prune --omit=dev
sudo systemctl restart plaude-like-backend
sudo systemctl reload nginx
```

## 7. Checklist pos-deploy

- `curl -f http://127.0.0.1:8787/health`
- `https://seudominio.com` entrega o app Flutter
- `https://admin.seudominio.com` entrega o admin
- `https://seudominio.com/api/health` responde externamente
- `shared/backend.env` preserva os segredos esperados
- `dist-app/index.html` e `dist-admin/index.html` existem no host
