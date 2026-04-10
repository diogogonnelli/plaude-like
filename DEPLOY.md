# Guia de Deploy (Bitbucket Pipelines + Linux + Nginx)

## Visao geral da arquitetura

- monorepo com `backend`, `app` e `admin-web`
- `backend` Node/Express como servico `systemd`
- `app` Flutter Web publicado como estatico em `dist-app/`
- `admin-web` React/Vite publicado como estatico em `dist-admin/`
- `nginx` servindo os dois frontends e fazendo proxy de `/api` para o backend

Layout esperado no servidor:

- `/storage-apps/www/sonora/current`
- `/storage-apps/www/sonora/dist-app`
- `/storage-apps/www/sonora/dist-admin`
- `/storage-apps/www/sonora/shared/backend.env`
- `/storage-apps/www/sonora/shared/uploads`
- `/storage-apps/www/sonora/shared/logs`

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

- `SSH_KEY_webrun01`: chave privada em base64 usada pelo pipeline para conectar no host
- `DEPLOY_APP_PATH`: caminho base do projeto no host. Ex.: `/storage-apps/www/sonora`
- `DEPLOY_BACKEND_SERVICE`: opcional. Default `plaude-like-backend`
- `DEPLOY_BACKEND_PORT`: opcional. Default `8787`
- `DEPLOY_APP_DOMAIN`: opcional. Se informado, o deploy atualiza `APP_BASE_URL=https://<dominio>/api` no backend
- `DEPLOY_ADMIN_DOMAIN`: opcional. Usado apenas para log e documentacao operacional

Itens fixos no pipeline, no mesmo estilo do projeto `anotacoes`:

- host SSH: `172.18.0.86`
- usuario SSH: `spotti`
- repositorio sincronizado no host: `git@bitbucket.org:spotpromo/sonora.git`

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
git ls-remote git@bitbucket.org:spotpromo/sonora.git
sudo systemctl restart plaude-like-backend
sudo systemctl reload nginx
```

Bootstrap recomendado antes do primeiro deploy:

```bash
sudo mkdir -p /storage-apps/www/sonora
sudo chown -R spotti:spotti /storage-apps/www/sonora
```

## 4. Como o pipeline faz o deploy

Na `main`, o pipeline:

1. valida `backend`, `app` e `admin-web`
2. gera os artefatos `app/build/web` e `admin-web/dist`
3. envia dois `.tar.gz` para o host
4. executa `scripts/deploy-linux-host.sh` por SSH
5. no host, o script:
   - sincroniza `current/` com `origin/main`
   - usa por padrao o repo SSH `git@bitbucket.org:spotpromo/sonora.git` ou o valor de `DEPLOY_REPO_URL`
   - cria ou preserva `shared/backend.env`
   - fixa `HOST=127.0.0.1`, `PORT` e `TRUST_PROXY=true`
   - se `DEPLOY_APP_DOMAIN` estiver definido, atualiza `APP_BASE_URL=https://<dominio>/api`
   - se `DEPLOY_APP_DOMAIN` nao estiver definido, preserva o `APP_BASE_URL` ja existente em `shared/backend.env`
   - roda `npm ci`, `npm run build` e `npm prune --omit=dev` no backend
   - publica os dois frontends
   - reinicia o backend
   - recarrega o `nginx`
   - valida `http://127.0.0.1:<porta>/health`

## 5. Backend `.env`

O arquivo persistente fica em:

```bash
/storage-apps/www/sonora/shared/backend.env
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
cd /storage-apps/www/sonora/current
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
