# Deploy para testes

## Objetivo

Subir uma primeira versão testável do produto com:

- backend HTTP em `Node`
- frontend Flutter Web servido por `nginx`
- integração por `BACKEND_BASE_URL`

## Pré-requisitos

- Docker com Compose
- arquivo `backend/.env` criado a partir de `backend/.env.example`

## Subida local com containers

```bash
cd C:\vscode_projects\Plaude_like
copy backend\.env.example backend\.env
docker compose up --build
```

Endpoints esperados:

- app web: `http://localhost:8080`
- backend: `http://localhost:8787/health`

## Modo de teste recomendado

### Modo mínimo

- `AI_PROVIDER=mock`
- sem chaves reais
- fluxo completo de UI e API já exercitável

### Modo semi-real

- `AI_PROVIDER=openai`
- `OPENAI_API_KEY` preenchida
- `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` preenchidos quando a camada de persistência real estiver conectada

## Observações

- o build web é estático; qualquer mudança em `BACKEND_BASE_URL` exige rebuild da imagem do frontend
- o backend já expõe `/health`, o que permite smoke checks simples em deploy
- o compose atual é voltado a testes de produto, não a produção endurecida
