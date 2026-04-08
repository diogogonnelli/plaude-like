# Deploy

O fluxo de producao via Bitbucket Pipelines + host Linux esta documentado em `DEPLOY.md`.

Para validacao local rapida com containers, o `compose.yaml` continua disponivel:

```bash
cd C:\vscode_projects\Plaude_like
copy backend\.env.example backend\.env
docker compose up --build
```

Endpoints locais esperados:

- app web: `http://localhost:8080`
- admin web: `http://localhost:8081`
- backend: `http://localhost:8787/health`
