# Implementacao Futura: Companion Desktop

## Objetivo

Criar um companion desktop para capturar audio de reunioes online e enviar arquivos para o Laravel atual. O companion deve ser um cliente operacional leve; o processamento, autorizacao e dados finais continuam no Laravel.

## Escopo Inicial

- Login com token Sanctum usando credenciais do usuario.
- Captura manual de audio do microfone e, quando suportado pelo sistema, audio do sistema.
- Selecao opcional de projeto antes da captura.
- Criacao de gravacao com `source_type=desktop_meeting`.
- Upload do audio capturado para `/api/recordings/{recording}/upload`.
- Fila local persistente para uploads pendentes.
- Tela simples de status: autenticado, capturando, aguardando upload, enviando, enviado e falhou.

## Arquitetura Recomendada

- Implementacao desktop separada do Laravel, preferencialmente Electron ou Tauri.
- Modulos internos:
  - `AuthClient`: login, logout e renovacao manual de sessao quando necessario.
  - `RecordingClient`: cria gravacao, envia audio e consulta status.
  - `CaptureSession`: controla inicio/parada da captura.
  - `UploadQueue`: persiste tentativas pendentes em storage local.
  - `SystemIntegration`: detecta plataforma, source app e capacidades de audio.
- Nada de regra de negocio do Laravel no companion.

## Contratos Laravel

Fluxo recomendado:

1. `POST /api/auth/login`
2. `GET /api/projects`
3. `POST /api/recordings`
4. `POST /api/recordings/{recording}/upload`
5. `GET /api/recordings/{recording}`

Payload de criacao:

```json
{
  "title": "Reuniao capturada",
  "project_id": "uuid-ou-null",
  "source_type": "desktop_meeting",
  "capture_metadata": {
    "sourceApp": "teams",
    "platform": "windows",
    "captureMode": "system_and_mic",
    "helperVersion": "1.0.0",
    "windowTitle": "Daily"
  },
  "duration_ms": 1800000
}
```

`project_id` precisa ser de um projeto do usuario autenticado.

## Requisitos de Captura

- Windows: priorizar WASAPI loopback para audio do sistema e microfone separado quando viavel.
- macOS: documentar permissao de microfone e eventual dependencia de driver virtual para audio do sistema.
- Salvar audio temporario em diretorio local do usuario.
- Apagar arquivo local apos upload confirmado, exceto se o usuario escolher reter logs/diagnostico.

## Seguranca

- Armazenar token em keychain/credential vault da plataforma.
- Nunca gravar `APP_KEY`, `OPENAI_API_KEY`, `ASSEMBLYAI_API_KEY` ou credenciais de servidor.
- Logs nao devem conter token, caminho completo de arquivos sensiveis ou conteudo de transcricao.

## Fora de Escopo Inicial

- Transcricao local.
- Integracao direta com AssemblyAI, OpenAI ou Supabase.
- Admin desktop.
- Captura automatica sem confirmacao do usuario.

## Testes Minimos

- Testes unitarios da fila de upload.
- Testes de retry e recuperacao apos reiniciar o app.
- Testes de contrato HTTP contra mocks da API Laravel.
- Smoke manual em Windows e macOS para permissao de audio, captura, upload e consulta de status.
