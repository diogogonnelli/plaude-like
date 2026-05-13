# SPOTLIGHT — redesign editorial escuro

**Data:** 2026-05-13
**Autor:** Diogo Gonnelli (com Claude)
**Status:** Aprovado pelo usuário em todas as seções §1–§6 do brainstorming.

## Resumo

Redesign integral do shell web Laravel (`Plaude_like`) e do app Flutter (`sonora_flutter_app`) sob o conceito **SPOTLIGHT** — editorial escuro/luxo ancorado no Manual de Identidade Visual SPOT. A assinatura visual é o **círculo vermelho do logo** transformado em vocabulário de UI (status dots, pulse de gravação, marcadores editoriais, ornamentos de hero). Modo escuro como default com toggle para modo claro alinhado ao MIV institucional.

## Objetivo

Substituir o sistema visual atual (cards arredondados claros, sombras suaves, tema "soft-UI") por uma linguagem editorial escura, densa em tipografia e cirúrgica no vermelho, mantendo 100% de aderência ao MIV SPOT (cores, tipografias Roboto/Montserrat, grafismo circular).

## Princípios de design

1. **Editorial antes de aplicativo.** Cada tela começa com kicker → headline → copy, mesmo telas internas. A interface tem manchetes.
2. **O "O" é o sistema.** O círculo vermelho do logo é primitivo (`.dot`, `.dot-live`, `.dot-status`, `.ring`) e aparece em todo lugar onde a UI precisa de um marcador.
3. **Disciplina MIV.** Proporção 70/25/5 (surface escuro / texto / acento) reflete a 60/30/10 institucional invertida para o escuro. No claro, segue 60/30/10 literalmente.
4. **Sem gradientes, sem efeitos.** O MIV proíbe distorção, sombra e outline no logo — aplico o mesmo rigor ao sistema todo. Cores sólidas, bordas hairline, sombras mínimas só em hero/modal.
5. **Tipografia editorial.** Display gigante (Montserrat Black) + corpo refinado (Roboto). Hierarquia agressiva.

## §1 — Tokens de cor

### Escuro (default)

| Token | Hex | Uso |
|---|---|---|
| `--ink-void` | `#0B0B0C` | Canvas raiz |
| `--ink-base` | `#161514` | Surface elevation 0 |
| `--ink-rise` | `#1F1D1C` | Surface elevation 1 (cards) |
| `--ink-edge` | `#2A2826` | Surface elevation 2 (hover/focus) |
| `--ink-line` | `#3F3D3C` | Cinza Carvão MIV — borda hairline |
| `--ink-line-soft` | `rgba(63,61,60,.5)` | Divider sutil |
| `--ink-mute` | `#8C8988` | Cinza Amarronzado MIV — texto secundário |
| `--ink-loud` | `#F9F9F9` | Branco Neve MIV — texto primário |
| `--accent` | `#DE0C2F` | Vermelho SPOT |
| `--accent-deep` | `#A20A25` | Vermelho Escuro MIV — hover/pressed |
| `--accent-soft` | `#F05A6C` | Vermelho Suave MIV — chips, focus rings |
| `--accent-glow` | `rgba(222,12,47,.18)` | Halo do `.dot-live` |
| `--positive` | `#02B663` | Sucesso (MIV departamental) |
| `--warning` | `#FF6D37` | Atenção (MIV Logística) |
| `--info` | `#2934F1` | Info (MIV Tech) |

### Claro (toggle)

| Token | Hex |
|---|---|
| `--ink-void` | `#F9F9F9` |
| `--ink-base` | `#FFFFFF` |
| `--ink-rise` | `#FFFFFF` |
| `--ink-edge` | `#F0F4F8` |
| `--ink-line` | `#D8DADF` |
| `--ink-mute` | `#666362` |
| `--ink-loud` | `#1F252C` |
| `--accent`, `--accent-deep`, `--accent-soft` | mantidos |

## §2 — Tipografia, escala, espaço, raio, motion

### Famílias (Google Fonts)

- `--font-display`: Montserrat (pesos 800/900)
- `--font-body`: Roboto (400/500/700)
- `--font-mono`: Roboto Mono (500) — só timestamps e IDs

### Escala

| Token | Tamanho | Peso | Tracking | Uso |
|---|---|---|---|---|
| `--type-display` | `clamp(3rem, 8vw, 6.5rem)` | 900 Mont | -0.04em | Hero, auth |
| `--type-headline` | `clamp(2rem, 4.5vw, 3.5rem)` | 900 Mont | -0.03em | h1 |
| `--type-title` | `clamp(1.5rem, 2.2vw, 2rem)` | 800 Mont | -0.02em | h2 |
| `--type-section` | `1.125rem` | 700 Roboto | -0.005em | Cabeçalhos de card |
| `--type-body` | `0.9375rem` | 400 Roboto | 0 | Corpo |
| `--type-meta` | `0.8125rem` | 500 Roboto | 0.01em | Metadados |
| `--type-kicker` | `0.6875rem` | 700 Roboto | 0.18em UPPER | Eyebrows |
| `--type-mono` | `0.875rem` | 500 Mono | 0 | Tempo, IDs |

### Espaço (escala 4px)

`--sp-1: 4px` · `2: 8` · `3: 12` · `4: 16` · `5: 24` · `6: 32` · `7: 48` · `8: 72` · `9: 112`.

### Raio

`--rad-pill: 999px` · `--rad-sm: 4px` (campos) · `--rad-md: 10px` (cards) · `--rad-lg: 16px` (panels).

### Motion (curve `cubic-bezier(.2,.7,.2,1)`)

- `--mo-fast: 140ms` — hover, focus
- `--mo-med: 260ms` — menu, fade
- `--mo-slow: 540ms` — entrada de página com stagger 60ms
- `--mo-pulse: 1800ms` — loop `.dot-live`

### Sombras

Mínimas. Apenas hero/modal recebem `0 1px 0 rgba(255,255,255,.03) inset, 0 24px 60px rgba(0,0,0,.4)`.

## §3 — Vocabulário de componentes

### Primitivos do "O"

- **`.dot`** — `8px` círculo `--accent` sólido. Bullet, separador, decoração.
- **`.dot-live`** — `10px` com `box-shadow` pulsante `--accent-glow` em loop 1.8s. Gravação ativa, status processando.
- **`.dot-status`** — `6px`, cor herdada (positive/warning/info/mute/accent). Substitui pills coloridas.
- **`.ring`** — círculo vazado stroke 1.5px, tamanhos `sm: 80px` / `md: 160px` / `lg: 280px`. Decorativo absoluto.

### Componentes

- **`.btn-primary`** — bg `--accent`, raio pill, peso 700, padding `12px 22px`. Hover: `--accent-deep` + `translateY(-1px)`.
- **`.btn-ghost`** — borda `1px --ink-line`, transparente.
- **`.btn-quiet`** — só texto `--ink-mute`, underline no hover.
- **`.card`** — bg `--ink-rise`, borda hairline, raio md, padding `--sp-5`. Sem sombra.
- **`.panel`** — variante grande, raio lg, padding `--sp-6`, com `.ring-md` decorativo.
- **`.hero`** — full-bleed, com `.ring-lg` vazando.
- **`.field`** — borda inferior `1.5px` apenas. Foco: borda `--accent`.
- **`.chip`** — pill compacta `--ink-edge` / `--ink-mute`.
- **`.kicker`** — `--type-kicker` precedido de `.dot`.
- **`.divider-rule`** — hairline com `.dot` à esquerda.
- **Tabelas** — zebradas `--ink-base`/`--ink-rise`, header em `.kicker`, sem bordas externas.

## §4 — Shell e layout patterns

### Shell web

Grid `64px minmax(0,1fr)` — rail vertical estreito + main.

- **Rail (64px)**: mark `SP•` no topo, ícones empilhados (Home, Library, Settings, Admin condicional), avatar no rodapé. Ativo: filete vertical `2px --accent` à esquerda + ícone em `--ink-loud`. Tooltip lateral no hover.
- **Topbar (56px)**: projeto ativo à esquerda (selector inline `.dot`); à direita: badge live (se gravando), toggle de tema (◐), botão de logout.
- **Main**: max-width `1280px`, padding `--sp-7` lateral / `--sp-6` topo.

### Padrões editoriais

1. **Above-the-fold**: kicker → headline → copy (`56ch`) → action row → divider rule. Cada tela tem manchete.
2. **Coluna editorial assimétrica** (`2fr 1fr`): main em texto grande + lateral em metadados kicker/valor.
3. **Listas tipo índice de revista**: `01 / 02 / 03` em mono à esquerda + título + meta. Hover preenche `--ink-rise`.
4. **Hero de gravação**: panel com `.ring-lg` vazando do canto. Mic 120px circular com `.dot-live`.
5. **Empty states editoriais**: kicker + headline curta + copy + CTA. Sem dashed boxes.

### Breakpoints

- `>=1180px` — shell completo
- `860–1179px` — rail vira drawer
- `<860px` — bottom-nav, headlines clampam

## §5 — Tratamento por tela (web)

| Tela | Tratamento |
|---|---|
| **Auth/login** | Split 50/50. Esquerda `--ink-void` com `.ring-lg` central + manchete `--type-display` `ONDE A ESTRATÉGIA ENCONTRA A EXECUÇÃO` (ENCONTRA em `--accent`). Direita: card mínimo com mark + form. |
| **Home** | Hero panel (kicker + headline `Grave agora. Execute depois.`) → linha de 3 métricas gigantes em `--type-display` reduzido, separadas por hairlines verticais → 2 panels lado a lado (upload / mic). Mic 120px circular. |
| **Library** | Substitui Kanban de 3 colunas por **índice editorial vertical**: chip row de filtros + lista `01 · título — projeto — duração — dot status`. Paginação editorial `← ANTERIOR · 1/12 · PRÓXIMA →`. |
| **Recording show** | 2 colunas `1.6fr 1fr`. Esquerda: headline + waveform + tabs editoriais. Direita: meta-stack sem cards. |
| **Recording chat** | User à direita em `--ink-rise` bubble; assistente à esquerda **sem bubble** em coluna `65ch` precedido de `.dot`. Composer fixo: textarea `.field` + botão circular envio. |
| **Settings** | 2 colunas: TOC editorial (numerais romanos mono) + conteúdo da seção. |
| **Admin (dashboard, users, projects, profiles, recordings, jobs)** | Mantém densidade. Tabelas zebradas + filtros chip row. Headers seguem padrão kicker+headline. Métricas como números gigantes inline. |

## §6 — Flutter parity

### Estrutura

`lib/ui/theme/`:

- `spot_tokens.dart` — `SpotColors`, `SpotType`, `SpotSpacing`, `SpotRadius`, `SpotMotion` espelhando exatos hex/escalas do CSS.
- `spot_theme.dart` — `ThemeData darkTheme` + `ThemeData lightTheme` com `ColorScheme` mapeado.
- `spot_widgets.dart` — `SpotDot`, `SpotDotLive` (AnimationController loop 1.8s), `SpotRing`, `SpotKicker`, `SpotChip`, `SpotField`, `SpotButtonPrimary/Ghost/Quiet`, `SpotPanel`, `SpotDivider`.

### Tipografia

`google_fonts` package. `TextTheme`:
- `displayLarge` ← Montserrat 900 → `--type-display`
- `headlineLarge` ← Montserrat 900 → `--type-headline`
- `titleLarge` ← Montserrat 800 → `--type-title`
- `titleMedium` ← Roboto 700 → `--type-section`
- `bodyMedium` ← Roboto 400 → `--type-body`
- `bodySmall` ← Roboto 500 → `--type-meta`
- `labelSmall` ← Roboto 700 spaced → `--type-kicker`

### Telas

- **`login_screen.dart`** — split editorial; em mobile vira stack vertical (top 40% manchete + ring, bottom 60% form).
- **`workspace_screen.dart`** — `Scaffold` com:
  - `AppBar` 56px transparente (projeto à esquerda, badge live + theme toggle à direita)
  - `BottomNavigationBar` custom (Home/Library/Settings/Admin) com filete superior `2px --accent` no ativo + `SpotDot`
  - `IndexedStack` de views: `HomeView`, `LibraryView`, `SettingsView`, `AdminView`

### Views novas

- **`HomeView`** — `ListView`: hero + métricas em row + 2 cards de captação. Mic 120dp.
- **`LibraryView`** — `SliverAppBar` colapsável com filtros + `SliverList` no padrão índice editorial.
- **`RecordingDetailView`** — push route com headline + waveform + tabs.
- **`ChatView`** — chat editorial (user com bubble, assistente em texto largo).
- **`SettingsView`** — TOC editorial.

### Estado

Mantém `AppSession` atual. Adiciona `ThemeNotifier` (`ChangeNotifier`) persistindo em `SharedPreferences('theme_mode')` para toggle dark/light. `SonoraApp` envolve `MaterialApp` com `themeMode` lido do notifier.

### Áudio / API

Sem mudanças — só substituir telas e widgets de apresentação. Pipeline `SonoraApi` preservado.

## Arquitetura de implementação

### Web (Laravel)

- Reescrever `resources/css/app.css` integralmente com os tokens. Manter import Tailwind (`@import 'tailwindcss'`) mas usar majoritariamente CSS custom — Tailwind fica como fallback utilitário.
- Atualizar `resources/views/layouts/base.blade.php` para incluir fonts (`<link>` para Google Fonts Montserrat + Roboto + Roboto Mono) e atributo `data-theme` no `<html>`.
- Reescrever `resources/views/layouts/app-shell.blade.php` com novo grid rail+main.
- Atualizar `resources/views/layouts/admin-shell.blade.php` para mesmo shell (admin é variante do main).
- Substituir cada `resources/views/web/**/*.blade.php` com a nova linguagem editorial.
- Atualizar `resources/views/web/partials/{wordmark,recording-card,status-pill,empty-state,flash}.blade.php` com novos primitivos.
- Adicionar `resources/js/theme-toggle.js` (toggle `data-theme` no `<html>` + persiste em `localStorage`).

### Flutter

- Adicionar `google_fonts: ^6.x` ao `pubspec.yaml`.
- Criar `lib/ui/theme/` (3 arquivos).
- Refatorar `login_screen.dart` e `workspace_screen.dart`.
- Criar `lib/ui/views/{home,library,recording_detail,chat,settings}_view.dart`.
- Adicionar `lib/state/theme_notifier.dart`.
- Atualizar `lib/ui/sonora_app.dart` para usar `ThemeNotifier` + `MaterialApp(themeMode:)`.

## Riscos / decisões em aberto

- **Logo SPOT oficial:** o MIV menciona arquivo na "Central de Documentos". O projeto atual usa um wordmark custom — vamos manter o wordmark proprietário com mark `SP•` (ponto vermelho como o "O") até o asset oficial chegar. Documentado para revisão futura.
- **Waveform real vs decorativo:** começamos com waveform CSS/SVG estilizado. Decoder real de áudio para waveform precisa de lib (`wavesurfer.js`) — adiar para iteração 2.
- **Tabelas admin densas:** podem ficar visualmente desconfortáveis no escuro em telas com 20+ colunas. Plano: revisar caso a caso, oferecer `data-density="compact"` opcional.

## Critério de aceitação

1. Todas as telas web renderizam no novo sistema sem regressão funcional (formulários submetem, navegação funciona, admin acessível).
2. Toggle de tema persiste entre sessões via `localStorage` (web) e `SharedPreferences` (Flutter).
3. Tipografia Montserrat + Roboto carregada via Google Fonts em ambos.
4. Paleta exata MIV respeitada (hex idênticos).
5. App Flutter inicializa em modo escuro, renderiza login + workspace + 5 views com tema novo.
6. Testes existentes continuam passando (`phpunit`, `flutter test`).
