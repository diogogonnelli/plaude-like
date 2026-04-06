# Meeting Capture Companion

Companion desktop para Windows/macOS que autentica no mesmo Supabase do produto, grava reuniões online localmente e envia o arquivo para o backend atual.

## Ambiente

Variáveis aceitas:

- `COMPANION_BACKEND_BASE_URL` ou `BACKEND_BASE_URL`
- `COMPANION_SUPABASE_URL` ou `SUPABASE_URL` ou `VITE_SUPABASE_URL`
- `COMPANION_SUPABASE_ANON_KEY` ou `SUPABASE_ANON_KEY` ou `VITE_SUPABASE_ANON_KEY`

## Rodando

```powershell
cd meeting-capture-companion
npm install
$env:COMPANION_BACKEND_BASE_URL="http://localhost:8787"
$env:COMPANION_SUPABASE_URL="https://<your-project>.supabase.co"
$env:COMPANION_SUPABASE_ANON_KEY="<anon-key>"
npm run dev
```

## Gerar instalador Windows

1. Preencha `meeting-capture-companion/.env.installer` com:

```env
COMPANION_BACKEND_BASE_URL=https://seu-backend.up.railway.app
COMPANION_SUPABASE_URL=https://seu-projeto.supabase.co
COMPANION_SUPABASE_ANON_KEY=sua_anon_key
```

2. Gere o instalador:

```powershell
cd meeting-capture-companion
npm install
npm run dist:win
```

3. O instalador NSIS será gerado em `meeting-capture-companion/dist/`.

O build embute `companion.env` dentro do pacote, então o usuário final não precisa configurar variáveis manualmente.

## Escopo do v1

- captura manual start/stop
- gravação local com áudio do sistema + microfone
- fila persistente de uploads
- retry automático ao abrir o app
- metadata de captura para Teams, Zoom, Meet ou áudio do sistema

## Limites atuais

- a captura depende do suporte de áudio do sistema exposto pelo stack Chromium/Electron do SO
- o fluxo está preparado para Windows/macOS, mas a validação local neste repositório foi feita em Windows
