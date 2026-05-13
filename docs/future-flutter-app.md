# Implementacao Futura: App Flutter

## Objetivo

Criar um app Flutter mobile/desktop como cliente do Laravel atual, sem duplicar regra de negocio. O Laravel continua sendo a fonte oficial para autenticacao, projetos, gravacoes, transcricao, resumo, chat e administracao.

## Escopo Inicial

- Login via `POST /api/auth/login` com token Sanctum.
- Listagem de projetos e gravacoes do usuario autenticado.
- Upload de audio para uma gravacao.
- Tela de detalhe com resumo, capitulos, highlights, action items, transcript e audio.
- Chat contextual usando `/api/recordings/{recording}/chat`.
- Modo offline apenas para fila local de uploads, nao para simular dados de negocio.

## Arquitetura Recomendada

- App Flutter em repositorio separado ou em projeto separado fora do runtime Laravel.
- Camadas simples:
  - `data`: cliente HTTP, DTOs e armazenamento seguro do token.
  - `domain`: modelos de tela e validacoes leves.
  - `ui`: telas e componentes.
  - `state`: controllers por fluxo, sem regra de negocio duplicada.
- Persistencia local apenas para:
  - token de sessao;
  - preferencias do usuario;
  - fila de uploads pendentes;
  - cache de leitura com TTL curto.

## Contratos Laravel

Usar somente a API publicada:

- `POST /api/auth/login`
- `GET /api/auth/me`
- `GET /api/projects`
- `GET /api/recordings`
- `POST /api/recordings`
- `POST /api/recordings/{recording}/upload`
- `GET /api/recordings/{recording}`
- `GET /api/recordings/{recording}/audio`
- `GET /api/recordings/{recording}/export/{format}`
- `GET /api/recordings/{recording}/chat`
- `POST /api/recordings/{recording}/chat`

Todas as chamadas autenticadas devem enviar:

```http
Authorization: Bearer <sanctum-token>
Accept: application/json
```

## UX Esperada

- Home com estado do projeto ativo e acao principal de gravar/enviar audio.
- Biblioteca com filtros por projeto, status e busca.
- Detalhe da gravacao com status claro para `uploaded`, `processing_transcript`, `processing_summary`, `ready` e `failed`.
- Chat bloqueado visualmente enquanto a gravacao ainda nao estiver pronta.
- Upload resiliente com retentativa manual e indicador de progresso.

## Fora de Escopo Inicial

- Admin mobile.
- Regras locais de transcricao/resumo.
- Sincronizacao bidirecional de dados.
- Dependencia direta de Supabase.
- Backend paralelo em TypeScript.

## Testes Minimos

- Testes de parsing dos DTOs da API Laravel.
- Testes de estados de upload: pendente, enviando, enviado e falhou.
- Testes de telas principais com mocks HTTP.
- Teste manual em Android e iOS para upload de arquivo grande.
