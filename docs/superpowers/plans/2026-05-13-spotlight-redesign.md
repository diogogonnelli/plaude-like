# SPOTLIGHT Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reescrever a camada visual do web Laravel (`C:\vscode_projects\Plaude_like`) e do app Flutter (`C:\vscode_projects\sonora_flutter_app`) sob a linguagem editorial escura SPOTLIGHT, com toggle para modo claro, sem alterar lógica de domínio nem rotas.

**Architecture:** CSS-first no web (`resources/css/app.css` reescrito com tokens, Tailwind como utilitário residual; novo `app-shell.blade.php` em grid rail+main; views refatoradas com primitivos editoriais). Flutter ganha pacote de tema em `lib/ui/theme/` com tokens, ThemeData dark+light, e widgets SPOT (Dot, DotLive, Ring, Kicker, Chip, Field, Button, Panel, Divider). Estado global de tema via `ThemeNotifier` + `SharedPreferences`.

**Tech Stack:** Laravel 11 (Blade), Tailwind v4, Vite, PHP 8.3, PHPUnit. Flutter 3.9+, Dart, `google_fonts`, `shared_preferences`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-05-13-spotlight-redesign-design.md`

**Branch:** crie `feat/spotlight-redesign` antes de começar.

---

## Phase A — Web foundation: tokens, fonts, shell

### Task A1: Branch e snapshot

**Files:** nenhum modificado.

- [ ] **Step 1: Criar branch a partir de main**

```bash
cd C:/vscode_projects/Plaude_like
git checkout main
git pull --ff-only
git checkout -b feat/spotlight-redesign
```

- [ ] **Step 2: Verificar que testes atuais passam (baseline)**

```bash
php artisan test
```

Expected: PASS (todos os testes existentes verdes). Se algum estiver falhando antes do começo, anote o teste e siga — a tarefa não deve corrigir testes pré-existentes.

- [ ] **Step 3: Commit do estado inicial (vazio, marcador de branch)**

```bash
git commit --allow-empty -m "chore: inicia branch SPOTLIGHT redesign"
```

---

### Task A2: Atualizar base.blade.php com fontes e atributo data-theme

**Files:**
- Modify: `resources/views/layouts/base.blade.php`

- [ ] **Step 1: Substituir conteúdo do `base.blade.php`**

Conteúdo completo do arquivo:

```blade
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" data-theme="dark">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>@yield('title', config('app.name', 'Sonora'))</title>

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@800;900&family=Roboto:wght@400;500;700&family=Roboto+Mono:wght@500&display=swap" rel="stylesheet">

    <script>
        (function () {
            try {
                var saved = localStorage.getItem('spot-theme');
                if (saved === 'light' || saved === 'dark') {
                    document.documentElement.setAttribute('data-theme', saved);
                }
            } catch (e) {}
        })();
    </script>

    @include('layouts.partials.vite-assets')
</head>
<body>
    @yield('body')
</body>
</html>
```

O script inline lê o tema salvo **antes** do CSS carregar, evitando flash de tema errado. Removido o `class="bg-canvas ..."` antigo — o novo CSS aplica via `data-theme`.

- [ ] **Step 2: Commit**

```bash
git add resources/views/layouts/base.blade.php
git commit -m "feat(web): base.blade.php com fontes SPOT e bootstrap de tema"
```

---

### Task A3: Reescrever app.css com tokens SPOTLIGHT

**Files:**
- Modify (rewrite): `resources/css/app.css`

- [ ] **Step 1: Substituir integralmente `resources/css/app.css`**

```css
@import 'tailwindcss';

@source '../../vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php';
@source '../../storage/framework/views/*.php';
@source '../**/*.blade.php';
@source '../**/*.js';

/* =========================================================
   SPOTLIGHT — Tokens
   ========================================================= */
:root[data-theme="dark"] {
    --ink-void: #0B0B0C;
    --ink-base: #161514;
    --ink-rise: #1F1D1C;
    --ink-edge: #2A2826;
    --ink-line: #3F3D3C;
    --ink-line-soft: rgba(63, 61, 60, 0.5);
    --ink-mute: #8C8988;
    --ink-loud: #F9F9F9;
    --accent: #DE0C2F;
    --accent-deep: #A20A25;
    --accent-soft: #F05A6C;
    --accent-glow: rgba(222, 12, 47, 0.18);
    --positive: #02B663;
    --warning: #FF6D37;
    --info: #2934F1;
    color-scheme: dark;
}

:root[data-theme="light"] {
    --ink-void: #F9F9F9;
    --ink-base: #FFFFFF;
    --ink-rise: #FFFFFF;
    --ink-edge: #F0F4F8;
    --ink-line: #D8DADF;
    --ink-line-soft: rgba(216, 218, 223, 0.6);
    --ink-mute: #666362;
    --ink-loud: #1F252C;
    --accent: #DE0C2F;
    --accent-deep: #A20A25;
    --accent-soft: #F05A6C;
    --accent-glow: rgba(222, 12, 47, 0.12);
    --positive: #02B663;
    --warning: #FF6D37;
    --info: #2934F1;
    color-scheme: light;
}

:root {
    --font-display: 'Montserrat', ui-sans-serif, system-ui, sans-serif;
    --font-body: 'Roboto', ui-sans-serif, system-ui, sans-serif;
    --font-mono: 'Roboto Mono', ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;

    --sp-1: 4px;  --sp-2: 8px;  --sp-3: 12px; --sp-4: 16px;
    --sp-5: 24px; --sp-6: 32px; --sp-7: 48px; --sp-8: 72px; --sp-9: 112px;

    --rad-pill: 999px;
    --rad-sm: 4px;
    --rad-md: 10px;
    --rad-lg: 16px;

    --mo-curve: cubic-bezier(.2, .7, .2, 1);
    --mo-fast: 140ms;
    --mo-med: 260ms;
    --mo-slow: 540ms;
}

/* =========================================================
   Reset + base
   ========================================================= */
* { box-sizing: border-box; }

html, body { min-height: 100%; }

body {
    margin: 0;
    background: var(--ink-void);
    color: var(--ink-loud);
    font-family: var(--font-body);
    font-size: 0.9375rem;
    line-height: 1.55;
    -webkit-font-smoothing: antialiased;
    text-rendering: optimizeLegibility;
}

button, input, select, textarea { font: inherit; color: inherit; }
a { color: inherit; text-decoration: none; }

::selection { background: var(--accent); color: #fff; }

/* =========================================================
   Typography
   ========================================================= */
.type-display {
    font-family: var(--font-display);
    font-weight: 900;
    font-size: clamp(3rem, 8vw, 6.5rem);
    line-height: 0.95;
    letter-spacing: -0.04em;
}

.type-headline {
    font-family: var(--font-display);
    font-weight: 900;
    font-size: clamp(2rem, 4.5vw, 3.5rem);
    line-height: 1;
    letter-spacing: -0.03em;
}

.type-title {
    font-family: var(--font-display);
    font-weight: 800;
    font-size: clamp(1.5rem, 2.2vw, 2rem);
    line-height: 1.05;
    letter-spacing: -0.02em;
}

.type-section {
    font-family: var(--font-body);
    font-weight: 700;
    font-size: 1.125rem;
    line-height: 1.3;
    letter-spacing: -0.005em;
}

.type-body { font-size: 0.9375rem; line-height: 1.55; }

.type-meta {
    font-size: 0.8125rem;
    font-weight: 500;
    color: var(--ink-mute);
    letter-spacing: 0.01em;
    line-height: 1.5;
}

.type-kicker {
    font-family: var(--font-body);
    font-weight: 700;
    font-size: 0.6875rem;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--ink-mute);
    display: inline-flex;
    align-items: center;
    gap: var(--sp-2);
}

.type-mono {
    font-family: var(--font-mono);
    font-weight: 500;
    font-size: 0.875rem;
}

/* =========================================================
   Dot system — o "O" virou vocabulário
   ========================================================= */
.dot {
    display: inline-block;
    width: 8px;
    height: 8px;
    border-radius: 999px;
    background: var(--accent);
    flex-shrink: 0;
}

.dot-live {
    display: inline-block;
    width: 10px;
    height: 10px;
    border-radius: 999px;
    background: var(--accent);
    box-shadow: 0 0 0 0 var(--accent-glow);
    animation: spot-pulse 1.8s var(--mo-curve) infinite;
    flex-shrink: 0;
}

@keyframes spot-pulse {
    0%   { box-shadow: 0 0 0 0 var(--accent-glow); }
    70%  { box-shadow: 0 0 0 14px rgba(222, 12, 47, 0); }
    100% { box-shadow: 0 0 0 0 rgba(222, 12, 47, 0); }
}

.dot-status {
    display: inline-block;
    width: 6px;
    height: 6px;
    border-radius: 999px;
    background: currentColor;
    flex-shrink: 0;
}

.dot-status--positive { color: var(--positive); }
.dot-status--warning  { color: var(--warning); }
.dot-status--info     { color: var(--info); }
.dot-status--accent   { color: var(--accent); }
.dot-status--mute     { color: var(--ink-mute); }

.ring {
    position: absolute;
    border: 1.5px solid var(--ink-line);
    border-radius: 50%;
    pointer-events: none;
    opacity: 0.65;
}

.ring--sm { width: 80px;  height: 80px; }
.ring--md { width: 160px; height: 160px; }
.ring--lg { width: 280px; height: 280px; }
.ring--accent { border-color: var(--accent); opacity: 0.4; }

/* =========================================================
   Shell — rail + main
   ========================================================= */
.app-shell {
    display: grid;
    grid-template-columns: 64px minmax(0, 1fr);
    min-height: 100vh;
}

.rail {
    position: sticky;
    top: 0;
    height: 100vh;
    border-right: 1px solid var(--ink-line);
    background: var(--ink-base);
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: var(--sp-4) 0;
    gap: var(--sp-3);
}

.rail-brand {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    font-family: var(--font-display);
    font-weight: 900;
    font-size: 0.95rem;
    color: var(--ink-loud);
    margin-bottom: var(--sp-2);
}

.rail-brand .dot { margin-left: 1px; }

.rail-link {
    position: relative;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    border-radius: var(--rad-sm);
    color: var(--ink-mute);
    transition: color var(--mo-fast) var(--mo-curve), background var(--mo-fast) var(--mo-curve);
}

.rail-link svg { width: 20px; height: 20px; }

.rail-link:hover { color: var(--ink-loud); background: var(--ink-rise); }

.rail-link.is-active { color: var(--ink-loud); }

.rail-link.is-active::before {
    content: '';
    position: absolute;
    left: -16px;
    top: 50%;
    transform: translateY(-50%);
    width: 2px;
    height: 24px;
    background: var(--accent);
    border-radius: 2px;
}

.rail-link[data-tooltip]:hover::after {
    content: attr(data-tooltip);
    position: absolute;
    left: calc(100% + 12px);
    top: 50%;
    transform: translateY(-50%);
    background: var(--ink-edge);
    color: var(--ink-loud);
    padding: 6px 10px;
    border-radius: var(--rad-sm);
    font-size: 0.75rem;
    white-space: nowrap;
    z-index: 10;
    border: 1px solid var(--ink-line);
}

.rail-spacer { flex: 1; }

.rail-avatar {
    width: 36px;
    height: 36px;
    border-radius: 999px;
    background: var(--ink-rise);
    border: 1px solid var(--ink-line);
    display: inline-flex;
    align-items: center;
    justify-content: center;
    color: var(--ink-loud);
    font-weight: 700;
    font-size: 0.8rem;
}

.shell-main {
    min-width: 0;
    display: flex;
    flex-direction: column;
}

.shell-topbar {
    height: 56px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: var(--sp-4);
    padding: 0 var(--sp-7);
    border-bottom: 1px solid var(--ink-line);
    background: var(--ink-void);
    position: sticky;
    top: 0;
    z-index: 5;
}

.topbar-left, .topbar-right {
    display: flex;
    align-items: center;
    gap: var(--sp-4);
}

.topbar-project-form select {
    background: transparent;
    border: none;
    color: var(--ink-loud);
    font-weight: 700;
    cursor: pointer;
    appearance: none;
    -webkit-appearance: none;
}

.topbar-project-form select:focus { outline: none; }

.topbar-live {
    display: inline-flex;
    align-items: center;
    gap: var(--sp-2);
    color: var(--ink-loud);
    font-size: 0.8125rem;
    font-weight: 700;
    letter-spacing: 0.1em;
    text-transform: uppercase;
}

.theme-toggle {
    background: transparent;
    border: 1px solid var(--ink-line);
    color: var(--ink-mute);
    width: 32px;
    height: 32px;
    border-radius: 999px;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    transition: color var(--mo-fast), border-color var(--mo-fast);
}

.theme-toggle:hover { color: var(--ink-loud); border-color: var(--ink-edge); }

.shell-content {
    max-width: 1280px;
    width: 100%;
    margin: 0 auto;
    padding: var(--sp-6) var(--sp-7) var(--sp-8);
    display: flex;
    flex-direction: column;
    gap: var(--sp-6);
}

/* =========================================================
   Editorial primitives — kicker row, divider, hero
   ========================================================= */
.kicker-row {
    display: inline-flex;
    align-items: center;
    gap: var(--sp-2);
    margin-bottom: var(--sp-3);
}

.divider-rule {
    display: flex;
    align-items: center;
    gap: var(--sp-3);
    margin: var(--sp-5) 0;
}

.divider-rule::after {
    content: '';
    flex: 1;
    height: 1px;
    background: var(--ink-line);
}

.headline-stack {
    display: flex;
    flex-direction: column;
    gap: var(--sp-3);
}

.headline-stack > p {
    max-width: 56ch;
    color: var(--ink-mute);
    margin: 0;
}

/* =========================================================
   Buttons
   ========================================================= */
.btn-primary,
.btn-ghost,
.btn-quiet {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: var(--sp-2);
    min-height: 44px;
    padding: 0 22px;
    border-radius: var(--rad-pill);
    font-family: var(--font-body);
    font-weight: 700;
    font-size: 0.875rem;
    border: 1px solid transparent;
    cursor: pointer;
    transition: background var(--mo-fast) var(--mo-curve),
                color var(--mo-fast) var(--mo-curve),
                border-color var(--mo-fast) var(--mo-curve),
                transform var(--mo-fast) var(--mo-curve);
    text-align: center;
}

.btn-primary {
    background: var(--accent);
    color: #fff;
}
.btn-primary:hover { background: var(--accent-deep); transform: translateY(-1px); }
.btn-primary:active { transform: translateY(0); }

.btn-ghost {
    background: transparent;
    color: var(--ink-loud);
    border-color: var(--ink-line);
}
.btn-ghost:hover { background: var(--ink-rise); border-color: var(--ink-edge); }

.btn-quiet {
    background: transparent;
    color: var(--ink-mute);
    padding: 0 12px;
    min-height: 36px;
}
.btn-quiet:hover { color: var(--ink-loud); }
.btn-quiet:hover { text-decoration: underline; text-decoration-thickness: 1px; text-underline-offset: 4px; }

.btn-wide { width: 100%; }

.btn-mic {
    width: 120px;
    height: 120px;
    border-radius: 999px;
    border: 1.5px solid var(--ink-line);
    background: var(--ink-rise);
    color: var(--ink-loud);
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    flex-direction: column;
    gap: 6px;
    font-size: 0.75rem;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    transition: border-color var(--mo-fast), background var(--mo-fast);
}
.btn-mic:hover { border-color: var(--accent); }
.btn-mic.is-recording { border-color: var(--accent); background: var(--ink-base); }

/* =========================================================
   Fields (editorial — só borda inferior)
   ========================================================= */
.field-grid {
    display: flex;
    flex-direction: column;
    gap: 6px;
}

.field-grid label,
.field-label {
    font-family: var(--font-body);
    font-weight: 700;
    font-size: 0.6875rem;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--ink-mute);
}

.field-input,
.field-select,
.field-textarea {
    background: transparent;
    border: none;
    border-bottom: 1.5px solid var(--ink-line);
    border-radius: 0;
    padding: 10px 0;
    color: var(--ink-loud);
    font-size: 1rem;
    width: 100%;
    transition: border-color var(--mo-fast);
}

.field-input:focus,
.field-select:focus,
.field-textarea:focus {
    outline: none;
    border-bottom-color: var(--accent);
}

.field-textarea { min-height: 96px; resize: vertical; }

.field-select { appearance: none; -webkit-appearance: none; cursor: pointer; padding-right: 24px; background-image: linear-gradient(45deg, transparent 50%, var(--ink-mute) 50%), linear-gradient(135deg, var(--ink-mute) 50%, transparent 50%); background-position: calc(100% - 14px) center, calc(100% - 8px) center; background-size: 6px 6px; background-repeat: no-repeat; }

/* =========================================================
   Cards, panels, hero
   ========================================================= */
.card {
    background: var(--ink-rise);
    border: 1px solid var(--ink-line);
    border-radius: var(--rad-md);
    padding: var(--sp-5);
    transition: border-color var(--mo-fast), transform var(--mo-fast);
}

.card:hover { border-color: var(--ink-edge); }

.panel {
    position: relative;
    overflow: hidden;
    background: var(--ink-rise);
    border: 1px solid var(--ink-line);
    border-radius: var(--rad-lg);
    padding: var(--sp-6);
}

.hero {
    position: relative;
    overflow: hidden;
    background: var(--ink-base);
    border: 1px solid var(--ink-line);
    border-radius: var(--rad-lg);
    padding: var(--sp-7);
}

.hero .ring--lg { right: -120px; top: -120px; }

/* =========================================================
   Chips
   ========================================================= */
.chip {
    display: inline-flex;
    align-items: center;
    gap: var(--sp-2);
    height: 28px;
    padding: 0 12px;
    border-radius: var(--rad-pill);
    background: var(--ink-edge);
    color: var(--ink-mute);
    font-size: 0.75rem;
    font-weight: 600;
    border: 1px solid var(--ink-line);
}

.chip--accent { background: rgba(222, 12, 47, 0.12); color: var(--accent-soft); border-color: rgba(222, 12, 47, 0.3); }

.chip-row { display: flex; flex-wrap: wrap; gap: var(--sp-2); }

/* =========================================================
   Metrics — números gigantes inline
   ========================================================= */
.metric-row {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 0;
    border-top: 1px solid var(--ink-line);
    border-bottom: 1px solid var(--ink-line);
    padding: var(--sp-5) 0;
}

.metric-cell {
    padding: 0 var(--sp-5);
    border-right: 1px solid var(--ink-line);
}
.metric-cell:last-child { border-right: none; }

.metric-cell .metric-label {
    font-family: var(--font-body);
    font-weight: 700;
    font-size: 0.6875rem;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--ink-mute);
    margin-bottom: var(--sp-2);
}

.metric-cell .metric-value {
    font-family: var(--font-display);
    font-weight: 900;
    font-size: clamp(2rem, 4vw, 3.25rem);
    line-height: 1;
    letter-spacing: -0.03em;
    color: var(--ink-loud);
}

/* =========================================================
   Editorial index — listas tipo "01 · título"
   ========================================================= */
.index-list { list-style: none; margin: 0; padding: 0; border-top: 1px solid var(--ink-line); }

.index-item {
    display: grid;
    grid-template-columns: 48px minmax(0, 1fr) auto;
    gap: var(--sp-4);
    align-items: center;
    padding: var(--sp-4) var(--sp-3);
    border-bottom: 1px solid var(--ink-line);
    transition: background var(--mo-fast);
}

.index-item:hover { background: var(--ink-rise); }

.index-num {
    font-family: var(--font-mono);
    color: var(--ink-mute);
    font-size: 0.8125rem;
}

.index-title {
    font-family: var(--font-body);
    font-weight: 700;
    font-size: 1rem;
    color: var(--ink-loud);
    margin: 0;
}

.index-meta {
    color: var(--ink-mute);
    font-size: 0.8125rem;
    margin-top: 2px;
    display: flex;
    gap: var(--sp-3);
    flex-wrap: wrap;
}

.index-status {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    font-size: 0.75rem;
    color: var(--ink-mute);
    text-transform: uppercase;
    letter-spacing: 0.1em;
}

/* =========================================================
   Tables — zebradas editoriais
   ========================================================= */
.table-wrap { overflow-x: auto; }

.table {
    width: 100%;
    border-collapse: collapse;
    border-top: 1px solid var(--ink-line);
}

.table thead th {
    text-align: left;
    padding: var(--sp-3) var(--sp-4);
    font-family: var(--font-body);
    font-weight: 700;
    font-size: 0.6875rem;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--ink-mute);
    background: var(--ink-base);
    border-bottom: 1px solid var(--ink-line);
}

.table tbody td {
    padding: var(--sp-4);
    border-bottom: 1px solid var(--ink-line-soft);
    color: var(--ink-loud);
    font-size: 0.875rem;
    vertical-align: top;
}

.table tbody tr:nth-child(even) { background: var(--ink-rise); }
.table tbody tr:hover { background: var(--ink-edge); }

/* =========================================================
   Flash messages, empty states
   ========================================================= */
.flash {
    border: 1px solid var(--ink-line);
    border-left: 3px solid var(--accent);
    background: var(--ink-rise);
    padding: var(--sp-3) var(--sp-4);
    border-radius: var(--rad-sm);
    color: var(--ink-loud);
    margin-bottom: var(--sp-4);
}

.flash--success { border-left-color: var(--positive); }
.flash--error   { border-left-color: var(--warning); }

.empty-state {
    padding: var(--sp-7) var(--sp-5);
    text-align: left;
    border-top: 1px solid var(--ink-line);
}

.empty-state .type-kicker { margin-bottom: var(--sp-3); }
.empty-state h3 { margin: 0 0 var(--sp-3); }
.empty-state p { color: var(--ink-mute); margin: 0 0 var(--sp-4); max-width: 56ch; }

/* =========================================================
   Auth shell — split editorial
   ========================================================= */
.auth-shell {
    min-height: 100vh;
    display: grid;
    grid-template-columns: 1fr 1fr;
}

.auth-story {
    position: relative;
    overflow: hidden;
    background: var(--ink-void);
    padding: var(--sp-8) var(--sp-7);
    display: flex;
    flex-direction: column;
    justify-content: center;
}

.auth-story .ring--lg { right: -40px; bottom: -80px; }

.auth-story-headline {
    max-width: 12ch;
}

.auth-story-headline em {
    font-style: normal;
    color: var(--accent);
}

.auth-card {
    background: var(--ink-base);
    border-left: 1px solid var(--ink-line);
    padding: var(--sp-8) var(--sp-7);
    display: flex;
    flex-direction: column;
    justify-content: center;
}

.auth-form { display: flex; flex-direction: column; gap: var(--sp-4); max-width: 360px; }

/* =========================================================
   Chat editorial
   ========================================================= */
.chat-thread {
    display: flex;
    flex-direction: column;
    gap: var(--sp-5);
    max-width: 800px;
    margin: 0 auto;
}

.chat-msg-user {
    align-self: flex-end;
    max-width: 60%;
    background: var(--ink-rise);
    border: 1px solid var(--ink-line);
    border-radius: var(--rad-md);
    padding: var(--sp-3) var(--sp-4);
    color: var(--ink-loud);
}

.chat-msg-assistant {
    align-self: stretch;
    max-width: 65ch;
    display: flex;
    gap: var(--sp-3);
    align-items: flex-start;
    padding: 0 var(--sp-3);
}

.chat-msg-assistant > .dot { margin-top: 8px; }

.chat-msg-assistant p { margin: 0 0 var(--sp-3); line-height: 1.65; }

.chat-composer {
    position: sticky;
    bottom: 0;
    background: var(--ink-void);
    border-top: 1px solid var(--ink-line);
    padding: var(--sp-4) var(--sp-7);
    display: flex;
    gap: var(--sp-3);
    align-items: flex-end;
}

.chat-composer textarea {
    flex: 1;
    background: transparent;
    border: 1px solid var(--ink-line);
    border-radius: var(--rad-md);
    padding: var(--sp-3);
    color: var(--ink-loud);
    resize: none;
    min-height: 44px;
    max-height: 200px;
}

/* =========================================================
   Detail grid (recording show)
   ========================================================= */
.detail-grid {
    display: grid;
    grid-template-columns: 1.6fr 1fr;
    gap: var(--sp-7);
}

.meta-stack { display: flex; flex-direction: column; gap: var(--sp-5); }

.meta-stack > div { display: flex; flex-direction: column; gap: 4px; padding-bottom: var(--sp-4); border-bottom: 1px solid var(--ink-line-soft); }

.meta-stack > div:last-child { border-bottom: none; }

.meta-stack > div > span:first-child {
    font-family: var(--font-body);
    font-weight: 700;
    font-size: 0.6875rem;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--ink-mute);
}

.meta-stack > div > strong {
    font-family: var(--font-body);
    font-weight: 500;
    color: var(--ink-loud);
    font-size: 1rem;
}

.waveform {
    height: 80px;
    width: 100%;
    border: 1px solid var(--ink-line);
    border-radius: var(--rad-md);
    background: var(--ink-rise);
    background-image: repeating-linear-gradient(
        90deg,
        transparent 0,
        transparent 6px,
        var(--ink-line) 6px,
        var(--ink-line) 7px
    );
    position: relative;
}

.waveform::before {
    content: '';
    position: absolute;
    left: 8px;
    right: 8px;
    top: 50%;
    height: 2px;
    background: linear-gradient(90deg, var(--accent) 0%, var(--accent) 30%, var(--ink-mute) 30%, var(--ink-mute) 100%);
    transform: translateY(-50%);
}

audio { width: 100%; margin-top: var(--sp-3); }

/* =========================================================
   Tabs editoriais
   ========================================================= */
.tabs {
    display: flex;
    gap: var(--sp-5);
    border-bottom: 1px solid var(--ink-line);
    margin-bottom: var(--sp-4);
}

.tab {
    background: none;
    border: none;
    padding: var(--sp-3) 0;
    color: var(--ink-mute);
    font-weight: 700;
    font-size: 0.875rem;
    cursor: pointer;
    position: relative;
    display: inline-flex;
    align-items: center;
    gap: var(--sp-2);
}

.tab.is-active { color: var(--ink-loud); }
.tab.is-active::after {
    content: '';
    position: absolute;
    left: 0;
    right: 0;
    bottom: -1px;
    height: 2px;
    background: var(--accent);
}

/* =========================================================
   Pagination
   ========================================================= */
.pager {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: var(--sp-5);
    padding: var(--sp-5) 0;
    font-family: var(--font-body);
    font-weight: 700;
    font-size: 0.75rem;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--ink-mute);
}

.pager a { color: var(--ink-loud); }
.pager a:hover { color: var(--accent); }

/* =========================================================
   Responsive
   ========================================================= */
@media (max-width: 1180px) {
    .detail-grid { grid-template-columns: 1fr; }
}

@media (max-width: 860px) {
    .app-shell { grid-template-columns: 1fr; }
    .rail { position: fixed; bottom: 0; top: auto; height: 56px; width: 100%; flex-direction: row; border-right: none; border-top: 1px solid var(--ink-line); justify-content: space-around; padding: 0; z-index: 50; }
    .rail-brand, .rail-spacer, .rail-avatar { display: none; }
    .rail-link.is-active::before { left: 50%; top: -1px; bottom: auto; transform: translateX(-50%); width: 24px; height: 2px; }
    .shell-main { padding-bottom: 64px; }
    .shell-content { padding: var(--sp-5) var(--sp-4) var(--sp-7); }
    .shell-topbar { padding: 0 var(--sp-4); }
    .auth-shell { grid-template-columns: 1fr; }
    .auth-story { padding: var(--sp-7) var(--sp-5); min-height: 320px; }
    .auth-card { border-left: none; border-top: 1px solid var(--ink-line); padding: var(--sp-7) var(--sp-5); }
    .metric-cell { border-right: none; border-bottom: 1px solid var(--ink-line-soft); padding: var(--sp-4) 0; }
    .metric-cell:last-child { border-bottom: none; }
}

/* Page entry stagger */
.shell-content > * { animation: spot-rise var(--mo-slow) var(--mo-curve) both; }
.shell-content > *:nth-child(1) { animation-delay: 0ms; }
.shell-content > *:nth-child(2) { animation-delay: 60ms; }
.shell-content > *:nth-child(3) { animation-delay: 120ms; }
.shell-content > *:nth-child(4) { animation-delay: 180ms; }
.shell-content > *:nth-child(5) { animation-delay: 240ms; }
.shell-content > *:nth-child(n+6) { animation-delay: 300ms; }

@keyframes spot-rise {
    from { opacity: 0; transform: translateY(12px); }
    to   { opacity: 1; transform: translateY(0); }
}
```

- [ ] **Step 2: Rodar build do vite e abrir uma rota qualquer**

```bash
npm run build
```

Expected: build sem erros. (Se `npm` não estiver disponível, use `npx vite build`.)

- [ ] **Step 3: Commit**

```bash
git add resources/css/app.css
git commit -m "feat(web): app.css com tokens, primitivos do O e shell rail+main"
```

---

### Task A4: Theme toggle JS

**Files:**
- Create: `resources/js/theme-toggle.js`
- Modify: `resources/js/app.js`

- [ ] **Step 1: Criar `resources/js/theme-toggle.js`**

```javascript
function applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    try { localStorage.setItem('spot-theme', theme); } catch (e) {}
    document.querySelectorAll('[data-theme-toggle]').forEach(function (btn) {
        btn.setAttribute('aria-pressed', String(theme === 'light'));
        btn.textContent = theme === 'dark' ? '☾' : '☀';
    });
}

function currentTheme() {
    return document.documentElement.getAttribute('data-theme') || 'dark';
}

document.addEventListener('click', function (event) {
    var trigger = event.target.closest('[data-theme-toggle]');
    if (!trigger) return;
    event.preventDefault();
    applyTheme(currentTheme() === 'dark' ? 'light' : 'dark');
});

document.addEventListener('DOMContentLoaded', function () {
    applyTheme(currentTheme());
});
```

- [ ] **Step 2: Importar em `resources/js/app.js`**

Conteúdo final do `app.js` (mantém o que existir e adiciona o import):

```javascript
import './bootstrap';
import './theme-toggle';
```

(Se o `app.js` atual tiver outras importações, mantenha-as e adicione `import './theme-toggle';` no final.)

- [ ] **Step 3: Commit**

```bash
git add resources/js/theme-toggle.js resources/js/app.js
git commit -m "feat(web): toggle de tema persistente em localStorage"
```

---

### Task A5: Reescrever app-shell.blade.php

**Files:**
- Modify (rewrite): `resources/views/layouts/app-shell.blade.php`

- [ ] **Step 1: Substituir conteúdo do shell**

```blade
@extends('layouts.base')

@section('body')
    <div class="app-shell">
        <aside class="rail" aria-label="Navegacao principal">
            <a class="rail-brand" href="{{ route('workspace.home') }}" aria-label="SPOT Sonora">
                SP<span class="dot" aria-hidden="true"></span>
            </a>

            <a class="rail-link {{ request()->routeIs('workspace.home') ? 'is-active' : '' }}"
               href="{{ route('workspace.home') }}" data-tooltip="Home">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
                    <path d="M3 11l9-8 9 8v10a1 1 0 0 1-1 1h-5v-7h-6v7H4a1 1 0 0 1-1-1V11z"/>
                </svg>
            </a>

            <a class="rail-link {{ request()->routeIs('workspace.library') || request()->routeIs('workspace.recordings.*') ? 'is-active' : '' }}"
               href="{{ route('workspace.library') }}" data-tooltip="Library">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
                    <rect x="3" y="4" width="4" height="16" rx="1"/>
                    <rect x="10" y="4" width="4" height="16" rx="1"/>
                    <path d="M18 6l3 1-3 14-3-1z"/>
                </svg>
            </a>

            <a class="rail-link {{ request()->routeIs('workspace.settings') ? 'is-active' : '' }}"
               href="{{ route('workspace.settings') }}" data-tooltip="Settings">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
                    <circle cx="12" cy="12" r="3"/>
                    <path d="M19 12a7 7 0 0 0-.1-1.2l2-1.5-2-3.4-2.4.9a7 7 0 0 0-2-1.2L14 3h-4l-.4 2.6a7 7 0 0 0-2 1.2l-2.4-.9-2 3.4 2 1.5A7 7 0 0 0 5 12c0 .4 0 .8.1 1.2l-2 1.5 2 3.4 2.4-.9a7 7 0 0 0 2 1.2L10 21h4l.4-2.6a7 7 0 0 0 2-1.2l2.4.9 2-3.4-2-1.5c.1-.4.1-.8.1-1.2z"/>
                </svg>
            </a>

            @if ($showAdminNav)
                <a class="rail-link {{ request()->routeIs('workspace.admin.*') ? 'is-active' : '' }}"
                   href="{{ route('workspace.admin.dashboard') }}" data-tooltip="Admin">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
                        <rect x="3" y="3" width="8" height="8" rx="1"/>
                        <rect x="13" y="3" width="8" height="5" rx="1"/>
                        <rect x="13" y="10" width="8" height="11" rx="1"/>
                        <rect x="3" y="13" width="8" height="8" rx="1"/>
                    </svg>
                </a>
            @endif

            <div class="rail-spacer"></div>

            <form method="POST" action="{{ route('logout') }}">
                @csrf
                <button class="rail-avatar" type="submit" title="Sair de {{ $user->full_name ?? $user->email }}">
                    {{ strtoupper(mb_substr($user->full_name ?? $user->email, 0, 1)) }}
                </button>
            </form>
        </aside>

        <main class="shell-main">
            <header class="shell-topbar">
                <div class="topbar-left">
                    <form class="topbar-project-form" method="POST" action="{{ route('workspace.projects.active') }}">
                        @csrf
                        <span class="type-kicker"><span class="dot"></span> PROJETO</span>
                        <select name="project_id" onchange="this.form.submit()" aria-label="Projeto ativo">
                            <option value="">Sem projeto</option>
                            @foreach ($projects as $projectOption)
                                <option value="{{ $projectOption->id }}" @selected(optional($activeProject)->id === $projectOption->id)>
                                    {{ $projectOption->name }}
                                </option>
                            @endforeach
                        </select>
                    </form>
                </div>

                <div class="topbar-right">
                    @yield('topbar-actions')
                    <button type="button" class="theme-toggle" data-theme-toggle aria-label="Alternar tema" aria-pressed="false">☾</button>
                </div>
            </header>

            <div class="shell-content">
                <div>
                    <div class="kicker-row"><span class="dot"></span><span class="type-kicker">{{ $pageEyebrow ?? 'Fluxo SPOT' }}</span></div>
                    <h1 class="type-headline">{{ $pageTitle ?? 'Workspace' }}</h1>
                    @if (!empty($pageSubtitle))
                        <p class="type-body" style="color: var(--ink-mute); max-width: 56ch; margin-top: var(--sp-3);">{{ $pageSubtitle }}</p>
                    @endif
                </div>

                @include('web.partials.flash')
                @yield('content')
            </div>
        </main>
    </div>
@endsection
```

- [ ] **Step 2: Verificar que o controller injeta `$pageEyebrow` se quiser usar — caso contrário fallback default funciona**

```bash
grep -rn "pageEyebrow\|pageTitle\|pageSubtitle" "C:/vscode_projects/Plaude_like/app" 2>/dev/null
```

Sem ação obrigatória — a view tem fallback `'Fluxo SPOT'`.

- [ ] **Step 3: Commit**

```bash
git add resources/views/layouts/app-shell.blade.php
git commit -m "feat(web): novo app-shell editorial rail+main com toggle de tema"
```

---

### Task A6: Reescrever admin-shell para usar o mesmo shell

**Files:**
- Modify: `resources/views/layouts/admin-shell.blade.php`

- [ ] **Step 1: Ler o admin-shell atual para preservar variáveis específicas**

```bash
cat "C:/vscode_projects/Plaude_like/resources/views/layouts/admin-shell.blade.php"
```

- [ ] **Step 2: Substituir por composição sobre o app-shell**

```blade
@extends('layouts.app-shell', [
    'pageEyebrow' => $pageEyebrow ?? 'Admin SPOT',
    'pageTitle' => $pageTitle ?? 'Administracao',
    'pageSubtitle' => $pageSubtitle ?? null,
])

@section('topbar-actions')
    @yield('admin-topbar-actions')
@endsection

@section('content')
    @yield('admin-content')
@endsection
```

- [ ] **Step 3: Procurar views admin que usam `@section('topbar-actions')` e renomear se necessário**

```bash
grep -rln "@section('topbar-actions')" "C:/vscode_projects/Plaude_like/resources/views/web/admin"
```

Para cada arquivo retornado: trocar `@section('topbar-actions')` por `@section('admin-topbar-actions')` e `@section('content')` por `@section('admin-content')`. Fazer isso nas tarefas C1–C5 quando cada view for tocada — anotar aqui para lembrança.

- [ ] **Step 4: Commit**

```bash
git add resources/views/layouts/admin-shell.blade.php
git commit -m "feat(web): admin-shell compoe sobre o app-shell editorial"
```

---

## Phase B — Web key views

### Task B1: Login

**Files:**
- Modify (rewrite): `resources/views/web/auth/login.blade.php`

- [ ] **Step 1: Ler view atual para extrair variáveis e ações**

```bash
cat "C:/vscode_projects/Plaude_like/resources/views/web/auth/login.blade.php"
```

Anote: campos do form, action, mensagens de erro, name das inputs.

- [ ] **Step 2: Substituir conteúdo (assume campos `email` e `password` na rota `login`; ajuste se a leitura do passo 1 mostrar nomes diferentes)**

```blade
@extends('layouts.base')

@section('title', 'Entrar — SPOT Sonora')

@section('body')
    <div class="auth-shell">
        <aside class="auth-story">
            <div class="ring ring--lg" aria-hidden="true"></div>
            <div class="kicker-row"><span class="dot"></span><span class="type-kicker">SPOT Sonora</span></div>
            <h1 class="type-display auth-story-headline">
                Onde a estrat&eacute;gia <em>encontra</em> a execu&ccedil;&atilde;o.
            </h1>
            <p class="type-body" style="max-width: 48ch; color: var(--ink-mute); margin-top: var(--sp-5);">
                Captacao, leitura e operacao em uma esteira unica. Acesse para gravar, organizar e revisar.
            </p>
        </aside>

        <section class="auth-card">
            <div class="kicker-row"><span class="dot"></span><span class="type-kicker">Acesso</span></div>
            <h2 class="type-title" style="margin: 0 0 var(--sp-5);">Entre na sess&atilde;o</h2>

            @include('web.partials.flash')

            <form class="auth-form" method="POST" action="{{ route('login') }}">
                @csrf
                <div class="field-grid">
                    <label for="login-email">Email</label>
                    <input class="field-input" id="login-email" name="email" type="email" autocomplete="email" required value="{{ old('email') }}">
                </div>
                <div class="field-grid">
                    <label for="login-password">Senha</label>
                    <input class="field-input" id="login-password" name="password" type="password" autocomplete="current-password" required>
                </div>
                @error('email')
                    <div class="flash flash--error">{{ $message }}</div>
                @enderror
                <button class="btn-primary btn-wide" type="submit" style="margin-top: var(--sp-4);">Entrar</button>
                <button type="button" class="btn-quiet" data-theme-toggle aria-label="Alternar tema">☾ Alternar tema</button>
            </form>
        </section>
    </div>

    <script type="module" src="{{ asset('build/assets/app.js') }}" defer></script>
    @include('layouts.partials.vite-assets')
@endsection
```

- [ ] **Step 3: Smoke manual (abra `/login` no browser)**

```bash
php artisan serve --host=127.0.0.1 --port=8000
```

Acesse `http://127.0.0.1:8000/login`. Confira: layout split, fonts carregam, vermelho em `encontra`, toggle de tema funciona, submit redireciona corretamente.

- [ ] **Step 4: Commit**

```bash
git add resources/views/web/auth/login.blade.php
git commit -m "feat(web): login editorial split com mensagem-chave MIV"
```

---

### Task B2: Home

**Files:**
- Modify (rewrite): `resources/views/web/home.blade.php`

- [ ] **Step 1: Substituir conteúdo**

```blade
@extends('layouts.app-shell', [
    'pageEyebrow' => 'Comando central',
    'pageTitle' => 'Grave agora. Execute depois.',
    'pageSubtitle' => 'Projeto ativo: ' . ($activeProject?->name ?? 'Sem projeto') . '. O frontend consolida audio, resumo, transcript e operacao de chat em uma unica esteira.',
])

@section('topbar-actions')
    <a class="btn-quiet" href="{{ route('workspace.library') }}">Library</a>
    <a class="btn-quiet" href="{{ route('workspace.settings') }}">Settings</a>
    @if ($showAdminNav)
        <a class="btn-quiet" href="{{ route('workspace.admin.dashboard') }}">Admin</a>
    @endif
@endsection

@section('content')
    <section class="hero">
        <div class="ring ring--lg" aria-hidden="true"></div>
        <div style="display: flex; gap: var(--sp-3); margin-top: var(--sp-4);">
            <a class="btn-primary" href="{{ route('workspace.library') }}">Abrir library</a>
            <a class="btn-ghost" href="{{ route('workspace.settings') }}">Organizar projetos</a>
        </div>
    </section>

    <div class="metric-row">
        <div class="metric-cell">
            <div class="metric-label">Notas</div>
            <div class="metric-value">{{ $summaryStats['total'] }}</div>
        </div>
        <div class="metric-cell">
            <div class="metric-label">Processando</div>
            <div class="metric-value">{{ $summaryStats['processing'] }}</div>
        </div>
        <div class="metric-cell">
            <div class="metric-label">Falhas</div>
            <div class="metric-value">{{ $summaryStats['failed'] }}</div>
        </div>
    </div>

    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: var(--sp-5);">
        <section class="panel">
            <div class="kicker-row"><span class="dot"></span><span class="type-kicker">Enviar audio</span></div>
            <h2 class="type-section" style="margin: 0 0 var(--sp-4);">Carregue um arquivo local</h2>

            <form method="POST" action="{{ route('workspace.recordings.upload') }}" enctype="multipart/form-data" data-upload-form style="display: flex; flex-direction: column; gap: var(--sp-4);">
                @csrf
                <input type="hidden" name="source_type" value="upload">
                <div class="field-grid">
                    <label for="upload-title">Titulo</label>
                    <input class="field-input" id="upload-title" type="text" name="title" placeholder="Nome do audio ou reuniao">
                </div>
                <div class="field-grid">
                    <label for="upload-project-id">Projeto</label>
                    <select class="field-select" id="upload-project-id" name="project_id">
                        <option value="">Sem projeto</option>
                        @foreach ($projects as $projectOption)
                            <option value="{{ $projectOption->id }}" @selected(optional($activeProject)->id === $projectOption->id)>
                                {{ $projectOption->name }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <input data-audio-input type="file" name="audio" accept="audio/*" hidden>
                <div>
                    <button class="btn-primary" type="button" data-audio-upload-trigger>Selecionar arquivo</button>
                    <p class="type-meta" style="margin-top: var(--sp-3);">O envio inicia automaticamente apos a escolha.</p>
                </div>
            </form>
        </section>

        <section class="panel" style="display: flex; flex-direction: column; align-items: center; justify-content: center; gap: var(--sp-4); min-height: 320px;">
            <div class="kicker-row" style="align-self: flex-start; margin: 0;"><span class="dot"></span><span class="type-kicker">Captacao</span></div>
            <form method="POST" action="{{ route('workspace.recordings.upload') }}" enctype="multipart/form-data" data-record-form style="display: contents;">
                @csrf
                <input type="hidden" name="source_type" value="microphone">
                <input type="hidden" name="title" value="Captacao web {{ now()->format('d/m H:i') }}">
                <input type="hidden" name="project_id" value="{{ $activeProject?->id }}">
                <input data-record-input type="file" name="audio" hidden>
                <button class="btn-mic"
                        type="button"
                        data-record-trigger
                        data-record-label-start="Iniciar"
                        data-record-label-stop="Parar">
                    <span class="dot" aria-hidden="true"></span>
                    Iniciar
                </button>
                <p class="type-meta" style="text-align: center; max-width: 32ch;">Captacao via microfone enviada automaticamente ao parar.</p>
            </form>
        </section>
    </div>
@endsection
```

- [ ] **Step 2: Verificar no browser**

Acesse `/` autenticado. Confira: hero com ring, métricas grandes inline, dois panels lado a lado, botão de mic 120px circular.

- [ ] **Step 3: Commit**

```bash
git add resources/views/web/home.blade.php
git commit -m "feat(web): home editorial com hero e captacao circular"
```

---

### Task B3: Library

**Files:**
- Modify (rewrite): `resources/views/web/library/index.blade.php`

- [ ] **Step 1: Ler conteúdo atual e inspecionar variáveis disponíveis**

```bash
cat "C:/vscode_projects/Plaude_like/resources/views/web/library/index.blade.php"
```

Anote nomes das coleções (`$recordings`? `$inbox`? colunas Kanban?). Os passos abaixo assumem que existe uma coleção `$recordings` paginada — ajuste se for diferente.

- [ ] **Step 2: Substituir por índice editorial**

```blade
@extends('layouts.app-shell', [
    'pageEyebrow' => 'Library',
    'pageTitle' => 'Indice de gravacoes',
    'pageSubtitle' => 'Lista cronologica com filtro por status e projeto.',
])

@section('content')
    <form method="GET" class="chip-row" style="align-items: center;">
        <label class="type-kicker" for="filter-status"><span class="dot"></span> Status</label>
        <select class="field-select" id="filter-status" name="status" onchange="this.form.submit()" style="border: 1px solid var(--ink-line); padding: 6px 28px 6px 12px; border-radius: var(--rad-pill); width: auto;">
            <option value="">Todos</option>
            @foreach (['ready','processing_transcript','indexing','failed','inactive'] as $opt)
                <option value="{{ $opt }}" @selected(request('status') === $opt)>{{ $opt }}</option>
            @endforeach
        </select>

        <label class="type-kicker" for="filter-project" style="margin-left: var(--sp-4);"><span class="dot"></span> Projeto</label>
        <select class="field-select" id="filter-project" name="project_id" onchange="this.form.submit()" style="border: 1px solid var(--ink-line); padding: 6px 28px 6px 12px; border-radius: var(--rad-pill); width: auto;">
            <option value="">Todos</option>
            @foreach ($projects as $p)
                <option value="{{ $p->id }}" @selected((string) request('project_id') === (string) $p->id)>{{ $p->name }}</option>
            @endforeach
        </select>
    </form>

    @if ($recordings->isEmpty())
        @include('web.partials.empty-state', [
            'eyebrow' => 'Sem registros',
            'title' => 'Nenhuma gravacao por aqui.',
            'copy' => 'Inicie pela home enviando um audio ou capturando pelo microfone.',
            'cta' => ['label' => 'Ir para home', 'route' => route('workspace.home')],
        ])
    @else
        <ul class="index-list">
            @foreach ($recordings as $index => $r)
                <li class="index-item">
                    <span class="index-num">{{ str_pad($loop->iteration + (($recordings->currentPage() - 1) * $recordings->perPage()), 2, '0', STR_PAD_LEFT) }}</span>
                    <div>
                        <a class="index-title" href="{{ route('workspace.recordings.show', $r) }}">{{ $r->title ?: 'Gravacao sem titulo' }}</a>
                        <div class="index-meta">
                            <span>{{ $r->project?->name ?? 'Sem projeto' }}</span>
                            <span>{{ $r->created_at?->format('d/m/Y H:i') }}</span>
                            @if ($r->duration_ms)
                                <span class="type-mono">{{ gmdate('i:s', intdiv($r->duration_ms, 1000)) }}</span>
                            @endif
                        </div>
                    </div>
                    <span class="index-status">
                        @php
                            $statusMap = [
                                'ready' => 'positive',
                                'processing_transcript' => 'accent',
                                'indexing' => 'info',
                                'failed' => 'warning',
                                'inactive' => 'mute',
                            ];
                            $token = $statusMap[$r->status] ?? 'mute';
                        @endphp
                        <span class="dot-status dot-status--{{ $token }}"></span>
                        {{ str_replace('_', ' ', $r->status) }}
                    </span>
                </li>
            @endforeach
        </ul>

        <nav class="pager">
            @if ($recordings->onFirstPage())
                <span style="color: var(--ink-line);">&larr; Anterior</span>
            @else
                <a href="{{ $recordings->previousPageUrl() }}">&larr; Anterior</a>
            @endif
            <span>{{ $recordings->currentPage() }} / {{ $recordings->lastPage() }}</span>
            @if ($recordings->hasMorePages())
                <a href="{{ $recordings->nextPageUrl() }}">Proxima &rarr;</a>
            @else
                <span style="color: var(--ink-line);">Proxima &rarr;</span>
            @endif
        </nav>
    @endif
@endsection
```

**Importante:** se o controller atual passa `$inbox`, `$ready`, `$failed` separados (Kanban), ajustar o controller — caso ele faça queries separadas, junte numa única paginação ordenada por `created_at desc`. Ver `app/Modules/Recordings/Http/Controllers/Web/AppController.php@library`. Se sentir que o ajuste do controller é maior que 5 linhas, criar uma sub-tarefa B3b para o ajuste do controller; caso contrário, fazer aqui.

- [ ] **Step 3: Verificar no browser**

`/library` deve mostrar lista numerada com filtros chip-style e paginação editorial.

- [ ] **Step 4: Commit**

```bash
git add resources/views/web/library/index.blade.php
git commit -m "feat(web): library como indice editorial vertical numerado"
```

---

### Task B4: Recording show

**Files:**
- Modify (rewrite): `resources/views/web/recordings/show.blade.php`

- [ ] **Step 1: Ler atual para mapear variáveis (`$recording`, `$transcript`, `$chapters`, `$summary`)**

```bash
cat "C:/vscode_projects/Plaude_like/resources/views/web/recordings/show.blade.php"
```

- [ ] **Step 2: Substituir conteúdo**

```blade
@extends('layouts.app-shell', [
    'pageEyebrow' => $recording->project?->name ?? 'Gravacao',
    'pageTitle' => $recording->title ?: 'Gravacao sem titulo',
    'pageSubtitle' => $recording->created_at?->format('d/m/Y H:i'),
])

@section('topbar-actions')
    <a class="btn-quiet" href="{{ route('workspace.library') }}">&larr; Library</a>
    <a class="btn-ghost" href="{{ route('workspace.recordings.chat', $recording) }}">Abrir chat</a>
@endsection

@section('content')
    <div class="detail-grid">
        <div>
            <div class="waveform" aria-hidden="true"></div>
            <audio controls src="{{ route('workspace.recordings.audio', $recording) }}"></audio>

            <div class="tabs" role="tablist" style="margin-top: var(--sp-6);">
                <button class="tab is-active" data-tab="transcript" type="button"><span class="dot"></span> Transcricao</button>
                <button class="tab" data-tab="chapters" type="button">Capitulos</button>
                <button class="tab" data-tab="summary" type="button">Resumo</button>
            </div>

            <div class="tab-panel" data-panel="transcript">
                @if (!empty($transcript))
                    <div class="type-body" style="line-height: 1.75; max-width: 65ch; white-space: pre-wrap;">{{ $transcript }}</div>
                @else
                    <p class="type-meta">Transcricao indisponivel.</p>
                @endif
            </div>

            <div class="tab-panel" data-panel="chapters" hidden>
                @forelse ($chapters ?? [] as $chap)
                    <div style="padding: var(--sp-4) 0; border-bottom: 1px solid var(--ink-line-soft);">
                        <span class="type-mono" style="color: var(--ink-mute);">{{ gmdate('i:s', intdiv($chap->start_ms ?? 0, 1000)) }}</span>
                        <h3 class="type-section" style="margin: 4px 0;">{{ $chap->title }}</h3>
                        <p class="type-meta" style="margin: 0;">{{ $chap->summary }}</p>
                    </div>
                @empty
                    <p class="type-meta">Capitulos nao gerados.</p>
                @endforelse
            </div>

            <div class="tab-panel" data-panel="summary" hidden>
                @if (!empty($summary))
                    <div class="type-body" style="line-height: 1.75; max-width: 65ch;">{!! nl2br(e($summary)) !!}</div>
                @else
                    <p class="type-meta">Resumo nao gerado.</p>
                @endif
            </div>
        </div>

        <aside class="meta-stack">
            <div>
                <span>Status</span>
                <strong>{{ str_replace('_', ' ', $recording->status) }}</strong>
            </div>
            <div>
                <span>Duracao</span>
                <strong>{{ $recording->duration_ms ? gmdate('i:s', intdiv($recording->duration_ms, 1000)) : '—' }}</strong>
            </div>
            <div>
                <span>Origem</span>
                <strong>{{ $recording->source_type }}</strong>
            </div>
            <div>
                <span>Projeto</span>
                <strong>{{ $recording->project?->name ?? 'Sem projeto' }}</strong>
            </div>
            <div>
                <span>ID</span>
                <strong class="type-mono" style="font-size: 0.8rem;">{{ $recording->id }}</strong>
            </div>

            <form method="POST" action="{{ route('workspace.recordings.reprocess', $recording) }}">
                @csrf
                <button class="btn-ghost btn-wide" type="submit">Reprocessar</button>
            </form>
        </aside>
    </div>

    <script>
        (function () {
            var buttons = document.querySelectorAll('.tab[data-tab]');
            var panels = document.querySelectorAll('.tab-panel[data-panel]');
            buttons.forEach(function (btn) {
                btn.addEventListener('click', function () {
                    var target = btn.getAttribute('data-tab');
                    buttons.forEach(function (b) { b.classList.toggle('is-active', b === btn); });
                    panels.forEach(function (p) { p.hidden = p.getAttribute('data-panel') !== target; });
                });
            });
        })();
    </script>
@endsection
```

- [ ] **Step 3: Verificar no browser**

Acesse `/recordings/<id>` para uma gravação ready. Confira waveform decorativo, audio nativo controla play, abas alternam.

- [ ] **Step 4: Commit**

```bash
git add resources/views/web/recordings/show.blade.php
git commit -m "feat(web): recording show editorial com meta-stack e tabs"
```

---

### Task B5: Recording chat

**Files:**
- Modify (rewrite): `resources/views/web/recordings/chat.blade.php`

- [ ] **Step 1: Ler conteúdo atual para variáveis (`$messages`, `$recording`, `$promptSuggestions`)**

```bash
cat "C:/vscode_projects/Plaude_like/resources/views/web/recordings/chat.blade.php"
```

- [ ] **Step 2: Substituir**

```blade
@extends('layouts.app-shell', [
    'pageEyebrow' => 'Chat',
    'pageTitle' => $recording->title ?: 'Gravacao sem titulo',
    'pageSubtitle' => 'Converse com a IA usando o conteudo desta gravacao.',
])

@section('topbar-actions')
    <a class="btn-quiet" href="{{ route('workspace.recordings.show', $recording) }}">&larr; Voltar</a>
@endsection

@section('content')
    <div class="chat-thread">
        @forelse ($messages ?? [] as $msg)
            @if ($msg->role === 'user')
                <div class="chat-msg-user">{{ $msg->content }}</div>
            @else
                <div class="chat-msg-assistant">
                    <span class="dot" aria-hidden="true"></span>
                    <div>
                        {!! nl2br(e($msg->content)) !!}
                    </div>
                </div>
            @endif
        @empty
            <div class="chat-msg-assistant">
                <span class="dot" aria-hidden="true"></span>
                <div>
                    <p>Pergunte algo sobre esta gravacao. Pode resumir, buscar trechos, listar a&ccedil;&otilde;es ou tra&ccedil;ar timeline.</p>
                </div>
            </div>
        @endforelse
    </div>

    <form class="chat-composer" method="POST" action="{{ route('workspace.recordings.chat.send', $recording) }}">
        @csrf
        <textarea name="message" placeholder="Pergunte sobre esta gravacao..." rows="1" required></textarea>
        <button class="btn-primary" type="submit" aria-label="Enviar">
            <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 12l18-9-9 18-2-7-7-2z"/></svg>
        </button>
    </form>
@endsection
```

- [ ] **Step 3: Commit**

```bash
git add resources/views/web/recordings/chat.blade.php
git commit -m "feat(web): chat editorial com bolha user e texto largo assistente"
```

---

### Task B6: Settings

**Files:**
- Modify (rewrite): `resources/views/web/settings.blade.php`

- [ ] **Step 1: Ler atual**

```bash
cat "C:/vscode_projects/Plaude_like/resources/views/web/settings.blade.php"
```

- [ ] **Step 2: Substituir conteúdo**

```blade
@extends('layouts.app-shell', [
    'pageEyebrow' => 'Settings',
    'pageTitle' => 'Sessao e organizacao',
    'pageSubtitle' => 'Perfil, projetos e preferencias da sua conta.',
])

@section('content')
    <div style="display: grid; grid-template-columns: 200px minmax(0, 1fr); gap: var(--sp-7);">
        <nav aria-label="Secoes" style="display: flex; flex-direction: column; gap: var(--sp-3);">
            <a href="#perfil" class="type-mono" style="color: var(--ink-mute); padding: 4px 0;">I &middot; Perfil</a>
            <a href="#projetos" class="type-mono" style="color: var(--ink-mute); padding: 4px 0;">II &middot; Projetos</a>
            <a href="#sessao" class="type-mono" style="color: var(--ink-mute); padding: 4px 0;">III &middot; Sess&atilde;o</a>
        </nav>

        <div style="display: flex; flex-direction: column; gap: var(--sp-7);">
            <section id="perfil">
                <div class="kicker-row"><span class="dot"></span><span class="type-kicker">I &middot; Perfil</span></div>
                <h2 class="type-title" style="margin: 0 0 var(--sp-4);">{{ $user->full_name ?? $user->email }}</h2>
                <div class="meta-stack" style="max-width: 480px;">
                    <div><span>Email</span><strong>{{ $user->email }}</strong></div>
                    <div><span>Perfil</span><strong>{{ $user->profile?->name ?? 'Sem perfil' }}</strong></div>
                </div>
            </section>

            <div class="divider-rule"><span class="dot"></span></div>

            <section id="projetos">
                <div class="kicker-row"><span class="dot"></span><span class="type-kicker">II &middot; Projetos</span></div>
                <h2 class="type-title" style="margin: 0 0 var(--sp-4);">Projetos acessiveis</h2>

                @if ($projects->isEmpty())
                    <p class="type-meta">Nenhum projeto vinculado.</p>
                @else
                    <ul class="index-list" style="max-width: 600px;">
                        @foreach ($projects as $p)
                            <li class="index-item">
                                <span class="index-num">{{ str_pad($loop->iteration, 2, '0', STR_PAD_LEFT) }}</span>
                                <div>
                                    <strong class="index-title">{{ $p->name }}</strong>
                                    <div class="index-meta">
                                        <span>{{ $p->status ?? 'ativo' }}</span>
                                        @if (isset($p->recordings_count))
                                            <span>{{ $p->recordings_count }} gravacoes</span>
                                        @endif
                                    </div>
                                </div>
                                <span>
                                    @if (optional($activeProject)->id === $p->id)
                                        <span class="chip chip--accent"><span class="dot-status dot-status--accent"></span> Ativo</span>
                                    @endif
                                </span>
                            </li>
                        @endforeach
                    </ul>
                @endif

                @if (Route::has('workspace.projects.store'))
                    <form method="POST" action="{{ route('workspace.projects.store') }}" style="margin-top: var(--sp-5); display: flex; gap: var(--sp-3); align-items: flex-end; max-width: 480px;">
                        @csrf
                        <div class="field-grid" style="flex: 1;">
                            <label for="new-project-name">Novo projeto</label>
                            <input class="field-input" id="new-project-name" type="text" name="name" required>
                        </div>
                        <button class="btn-primary" type="submit">Criar</button>
                    </form>
                @endif
            </section>

            <div class="divider-rule"><span class="dot"></span></div>

            <section id="sessao">
                <div class="kicker-row"><span class="dot"></span><span class="type-kicker">III &middot; Sess&atilde;o</span></div>
                <h2 class="type-title" style="margin: 0 0 var(--sp-4);">Encerrar acesso</h2>
                <p class="type-meta" style="max-width: 56ch; margin-bottom: var(--sp-4);">Encerra a sessao no navegador atual. Outros dispositivos permanecem conectados.</p>
                <form method="POST" action="{{ route('logout') }}">
                    @csrf
                    <button class="btn-ghost" type="submit">Sair da sessao</button>
                </form>
            </section>
        </div>
    </div>
@endsection
```

- [ ] **Step 3: Commit**

```bash
git add resources/views/web/settings.blade.php
git commit -m "feat(web): settings com TOC editorial e secoes numeradas"
```

---

## Phase C — Web admin views

### Task C1: Admin dashboard

**Files:**
- Modify: `resources/views/web/admin/dashboard.blade.php`

- [ ] **Step 1: Ler atual para mapear variáveis (`$counts`, `$recentJobs`, etc.)**

```bash
cat "C:/vscode_projects/Plaude_like/resources/views/web/admin/dashboard.blade.php"
```

- [ ] **Step 2: Substituir conteúdo (assume `$counts` com chaves users/projects/recordings/jobs — ajuste pelo passo 1)**

```blade
@extends('layouts.admin-shell', [
    'pageEyebrow' => 'Admin',
    'pageTitle' => 'Painel administrativo',
    'pageSubtitle' => 'Visao geral de usuarios, projetos, gravacoes e jobs.',
])

@section('admin-topbar-actions')
    <a class="btn-quiet" href="{{ route('workspace.home') }}">&larr; Workspace</a>
@endsection

@section('admin-content')
    <div class="metric-row">
        <div class="metric-cell">
            <div class="metric-label">Usuarios</div>
            <div class="metric-value">{{ $counts['users'] ?? 0 }}</div>
        </div>
        <div class="metric-cell">
            <div class="metric-label">Projetos</div>
            <div class="metric-value">{{ $counts['projects'] ?? 0 }}</div>
        </div>
        <div class="metric-cell">
            <div class="metric-label">Gravacoes</div>
            <div class="metric-value">{{ $counts['recordings'] ?? 0 }}</div>
        </div>
        <div class="metric-cell">
            <div class="metric-label">Jobs</div>
            <div class="metric-value">{{ $counts['jobs'] ?? 0 }}</div>
        </div>
    </div>

    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: var(--sp-5);">
        <a class="card" href="{{ route('workspace.admin.users') }}">
            <div class="kicker-row"><span class="dot"></span><span class="type-kicker">Acesso</span></div>
            <h3 class="type-section" style="margin: 0 0 var(--sp-2);">Usuarios e perfis</h3>
            <p class="type-meta" style="margin: 0;">Gerencie acessos, papeis e vinculos.</p>
        </a>
        <a class="card" href="{{ route('workspace.admin.projects') }}">
            <div class="kicker-row"><span class="dot"></span><span class="type-kicker">Operacao</span></div>
            <h3 class="type-section" style="margin: 0 0 var(--sp-2);">Projetos e membros</h3>
            <p class="type-meta" style="margin: 0;">Crie, atribua e organize.</p>
        </a>
        <a class="card" href="{{ route('workspace.admin.recordings') }}">
            <div class="kicker-row"><span class="dot"></span><span class="type-kicker">Conteudo</span></div>
            <h3 class="type-section" style="margin: 0 0 var(--sp-2);">Gravacoes</h3>
            <p class="type-meta" style="margin: 0;">Inspecione e reprocesse.</p>
        </a>
        <a class="card" href="{{ route('workspace.admin.jobs') }}">
            <div class="kicker-row"><span class="dot"></span><span class="type-kicker">Pipeline</span></div>
            <h3 class="type-section" style="margin: 0 0 var(--sp-2);">Jobs</h3>
            <p class="type-meta" style="margin: 0;">Acompanhe a fila de processamento.</p>
        </a>
    </div>
@endsection
```

- [ ] **Step 3: Commit**

```bash
git add resources/views/web/admin/dashboard.blade.php
git commit -m "feat(web): admin dashboard com metricas inline e cards de atalho"
```

---

### Task C2: Admin tables (users, projects, profiles, recordings, jobs)

**Files:**
- Modify:
  - `resources/views/web/admin/users/index.blade.php`
  - `resources/views/web/admin/projects/index.blade.php`
  - `resources/views/web/admin/projects/members.blade.php`
  - `resources/views/web/admin/profiles/index.blade.php`
  - `resources/views/web/admin/recordings/index.blade.php`
  - `resources/views/web/admin/recordings/show.blade.php`
  - `resources/views/web/admin/jobs/index.blade.php`

Cada uma segue o mesmo padrão: header via `admin-shell`, filtros chip-row se aplicável, tabela `.table`, paginação `.pager`, formulários com `.field-grid` editorial.

- [ ] **Step 1: Para cada arquivo da lista, ler o conteúdo atual**

```bash
for f in users/index projects/index projects/members profiles/index recordings/index recordings/show jobs/index; do
  echo "=== $f ==="
  cat "C:/vscode_projects/Plaude_like/resources/views/web/admin/$f.blade.php"
done
```

- [ ] **Step 2: Aplicar template canônico — users/index como exemplo (replicar padrão para os outros)**

`resources/views/web/admin/users/index.blade.php`:

```blade
@extends('layouts.admin-shell', [
    'pageEyebrow' => 'Admin · Usuarios',
    'pageTitle' => 'Usuarios',
    'pageSubtitle' => 'Lista de usuarios da plataforma.',
])

@section('admin-content')
    @if (Route::has('workspace.admin.users.store'))
        <details>
            <summary class="btn-ghost" style="cursor: pointer; display: inline-flex;">+ Novo usuario</summary>
            <form method="POST" action="{{ route('workspace.admin.users.store') }}" style="margin-top: var(--sp-4); display: grid; grid-template-columns: 1fr 1fr 1fr auto; gap: var(--sp-4); max-width: 880px;">
                @csrf
                <div class="field-grid"><label>Nome</label><input class="field-input" type="text" name="full_name" required></div>
                <div class="field-grid"><label>Email</label><input class="field-input" type="email" name="email" required></div>
                <div class="field-grid">
                    <label>Perfil</label>
                    <select class="field-select" name="profile_id">
                        @foreach ($profiles ?? [] as $prof)
                            <option value="{{ $prof->id }}">{{ $prof->name }}</option>
                        @endforeach
                    </select>
                </div>
                <button class="btn-primary" type="submit" style="align-self: end;">Criar</button>
            </form>
        </details>
    @endif

    <div class="table-wrap">
        <table class="table">
            <thead>
                <tr>
                    <th>Nome</th>
                    <th>Email</th>
                    <th>Perfil</th>
                    <th>Status</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                @forelse ($users as $u)
                    <tr>
                        <td><strong>{{ $u->full_name ?? '—' }}</strong></td>
                        <td class="type-mono">{{ $u->email }}</td>
                        <td>{{ $u->profile?->name ?? '—' }}</td>
                        <td>
                            <span class="dot-status dot-status--{{ ($u->status ?? 'active') === 'active' ? 'positive' : 'mute' }}"></span>
                            {{ $u->status ?? 'active' }}
                        </td>
                        <td style="text-align: right;">
                            @if (Route::has('workspace.admin.users.destroy'))
                                <form method="POST" action="{{ route('workspace.admin.users.destroy', $u) }}" onsubmit="return confirm('Remover {{ $u->email }}?')" style="display: inline;">
                                    @csrf @method('DELETE')
                                    <button class="btn-quiet" type="submit">Remover</button>
                                </form>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="5"><p class="type-meta" style="padding: var(--sp-4) 0;">Sem usuarios.</p></td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
@endsection
```

- [ ] **Step 3: Aplicar o mesmo padrão (header + table.table + form com fields editoriais) aos demais arquivos.**

Para cada arquivo:
1. Trocar `@extends('layouts.admin-shell')` para a forma com array de variáveis (`pageEyebrow`, `pageTitle`, `pageSubtitle`).
2. Renomear `@section('topbar-actions')` → `@section('admin-topbar-actions')` e `@section('content')` → `@section('admin-content')`.
3. Substituir cards/grids antigos por `<table class="table">` quando for listagem, ou `meta-stack` quando for detalhe.
4. Manter o action/method/inputs originais — só envolver com classes `.field-grid` / `.field-input` / `.field-select` / `.btn-*`.

Templates específicos:

- **`profiles/index.blade.php`** — mesma estrutura que users, colunas: Nome, Slug, Permissoes (chip-row de chips), Acoes.
- **`projects/index.blade.php`** — colunas: Nome, Status, Membros (count), Gravacoes (count), Acoes. Link "Membros" via `route('workspace.admin.projects.members', $project)`.
- **`projects/members.blade.php`** — header com `$project->name`, lista de membros como `.index-list`, form de adicionar membro com `field-select` para users.
- **`recordings/index.blade.php`** — colunas: Titulo, Projeto, Status (com `dot-status`), Duracao (type-mono), Criado em, Acoes (link para show).
- **`recordings/show.blade.php`** — `detail-grid` similar à view do workspace mas com formulários admin extras (`reprocess`, `export`, `updateRecordingProject`).
- **`jobs/index.blade.php`** — colunas: ID (mono), Nome, Queue, Tentativas, Status (dot-status), Criado em.

- [ ] **Step 4: Verificar no browser cada rota admin**

```
/admin
/admin/users
/admin/profiles
/admin/projects
/admin/projects/<id>/members
/admin/recordings
/admin/recordings/<id>
/admin/jobs
```

Acesse cada uma e confira: header com kicker, tabela zebrada, sem regressão funcional.

- [ ] **Step 5: Commit**

```bash
git add resources/views/web/admin/
git commit -m "feat(web): admin tables editoriais zebradas com fields refatorados"
```

---

## Phase D — Web partials, cleanup, verification

### Task D1: Partials

**Files:**
- Modify:
  - `resources/views/web/partials/flash.blade.php`
  - `resources/views/web/partials/empty-state.blade.php`
  - `resources/views/web/partials/recording-card.blade.php`
  - `resources/views/web/partials/status-pill.blade.php`
  - `resources/views/web/partials/wordmark.blade.php`

- [ ] **Step 1: Reescrever `flash.blade.php`**

```blade
@if (session('status'))
    <div class="flash flash--success">{{ session('status') }}</div>
@endif

@if (session('error'))
    <div class="flash flash--error">{{ session('error') }}</div>
@endif

@if ($errors->any())
    <div class="flash flash--error">
        <ul style="margin: 0; padding-left: 18px;">
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif
```

- [ ] **Step 2: Reescrever `empty-state.blade.php`**

```blade
@props(['eyebrow' => 'Vazio', 'title' => 'Nada por aqui.', 'copy' => null, 'cta' => null])

<div class="empty-state">
    <div class="kicker-row"><span class="dot"></span><span class="type-kicker">{{ $eyebrow }}</span></div>
    <h3 class="type-title">{{ $title }}</h3>
    @if ($copy)
        <p>{{ $copy }}</p>
    @endif
    @if ($cta && isset($cta['route']) && isset($cta['label']))
        <a class="btn-primary" href="{{ $cta['route'] }}">{{ $cta['label'] }}</a>
    @endif
</div>
```

(Atenção: este é um componente — se ele é incluído com `@include` passando array, mantenha como blade comum sem `@props`. Substitua o `@props` por leitura simples das variáveis se a base usar `@include`.)

Alternativa para `@include`:

```blade
@php
    $eyebrow = $eyebrow ?? 'Vazio';
    $title = $title ?? 'Nada por aqui.';
    $copy = $copy ?? null;
    $cta = $cta ?? null;
@endphp

<div class="empty-state">
    <div class="kicker-row"><span class="dot"></span><span class="type-kicker">{{ $eyebrow }}</span></div>
    <h3 class="type-title">{{ $title }}</h3>
    @if ($copy)<p>{{ $copy }}</p>@endif
    @if ($cta && isset($cta['route'], $cta['label']))
        <a class="btn-primary" href="{{ $cta['route'] }}">{{ $cta['label'] }}</a>
    @endif
</div>
```

- [ ] **Step 3: Reescrever `recording-card.blade.php` (caso ainda seja usado em qualquer lugar)**

```blade
@php
    $statusMap = [
        'ready' => 'positive',
        'processing_transcript' => 'accent',
        'indexing' => 'info',
        'failed' => 'warning',
        'inactive' => 'mute',
    ];
    $token = $statusMap[$recording->status] ?? 'mute';
@endphp

<a class="card" href="{{ route('workspace.recordings.show', $recording) }}" style="text-decoration: none; display: block;">
    <div class="kicker-row"><span class="dot-status dot-status--{{ $token }}"></span><span class="type-kicker">{{ str_replace('_', ' ', $recording->status) }}</span></div>
    <h3 class="type-section" style="margin: 0 0 var(--sp-2);">{{ $recording->title ?: 'Gravacao sem titulo' }}</h3>
    <p class="type-meta" style="margin: 0;">
        {{ $recording->project?->name ?? 'Sem projeto' }}
        @if ($recording->duration_ms) &middot; <span class="type-mono">{{ gmdate('i:s', intdiv($recording->duration_ms, 1000)) }}</span>@endif
    </p>
</a>
```

- [ ] **Step 4: Reescrever `status-pill.blade.php`**

```blade
@php
    $statusMap = [
        'ready' => 'positive',
        'processing_transcript' => 'accent',
        'indexing' => 'info',
        'failed' => 'warning',
        'inactive' => 'mute',
    ];
    $token = $statusMap[$status ?? 'inactive'] ?? 'mute';
@endphp

<span class="index-status">
    <span class="dot-status dot-status--{{ $token }}"></span>
    {{ str_replace('_', ' ', $status ?? 'inactive') }}
</span>
```

- [ ] **Step 5: Reescrever `wordmark.blade.php`**

```blade
@php
    $brandName = $brandName ?? 'Sonora';
    $subtitle = $subtitle ?? null;
    $href = $href ?? '#';
@endphp

<a href="{{ $href }}" style="display: inline-flex; align-items: center; gap: var(--sp-3); text-decoration: none;">
    <span style="font-family: var(--font-display); font-weight: 900; font-size: 1.5rem; color: var(--ink-loud);">
        SP<span class="dot" style="display: inline-block; transform: translateY(-2px);"></span>
    </span>
    <span style="display: flex; flex-direction: column;">
        <strong style="font-family: var(--font-display); font-weight: 900; font-size: 1.25rem; color: var(--ink-loud);">{{ $brandName }}</strong>
        @if ($subtitle)
            <span class="type-meta" style="margin: 0;">{{ $subtitle }}</span>
        @endif
    </span>
</a>
```

- [ ] **Step 6: Commit**

```bash
git add resources/views/web/partials/
git commit -m "feat(web): partials editoriais (flash, empty-state, status, wordmark)"
```

---

### Task D2: Verificação web — testes + smoke

- [ ] **Step 1: Rodar suite PHPUnit**

```bash
cd C:/vscode_projects/Plaude_like
php artisan test
```

Expected: PASS — todos os testes existentes ainda verdes. Se algum teste de view específico falhar por mudança de classe CSS, corrija o teste para refletir o novo HTML.

- [ ] **Step 2: Build de produção do CSS**

```bash
npm run build
```

Expected: build verde, sem warnings críticos.

- [ ] **Step 3: Smoke manual em modo dev — checklist**

```bash
php artisan serve --host=127.0.0.1 --port=8000
```

Abra cada rota e marque visualmente:

- [ ] `/login` — split editorial renderiza, vermelho em "encontra", toggle de tema persiste após refresh
- [ ] `/` (home) — hero com ring, métricas inline grandes, mic button circular, ambos forms submetem
- [ ] `/library` — lista numerada, filtros chip, paginação editorial
- [ ] `/recordings/{id}` — waveform decorativo, audio toca, abas alternam
- [ ] `/recordings/{id}/chat` — chat editorial, composer fixo
- [ ] `/settings` — TOC romano, 3 seções funcionais
- [ ] `/admin` (como admin) — métricas + cards de atalho
- [ ] `/admin/users`, `/projects`, `/profiles`, `/recordings`, `/jobs` — tabelas zebradas
- [ ] Toggle de tema (☾) alterna escuro/claro, persiste, sem flash de tema errado no refresh

- [ ] **Step 4: Commit (apenas se houve correções de teste)**

```bash
git add -A
git commit -m "test(web): ajusta assertions de view para o novo markup"
```

(Pular se nada mudou.)

---

## Phase E — Flutter foundation

### Task E1: Adicionar google_fonts ao pubspec

**Files:**
- Modify: `C:/vscode_projects/sonora_flutter_app/pubspec.yaml`

- [ ] **Step 1: Adicionar dependência**

Em `pubspec.yaml`, abaixo de `shared_preferences:`:

```yaml
  google_fonts: ^6.2.1
```

- [ ] **Step 2: Instalar**

```bash
cd C:/vscode_projects/sonora_flutter_app
flutter pub get
```

Expected: `Got dependencies!`.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "build(flutter): adiciona google_fonts para Montserrat e Roboto"
```

---

### Task E2: spot_tokens.dart

**Files:**
- Create: `C:/vscode_projects/sonora_flutter_app/lib/ui/theme/spot_tokens.dart`

- [ ] **Step 1: Criar arquivo**

```dart
import 'package:flutter/material.dart';

class SpotColors {
  final Color inkVoid;
  final Color inkBase;
  final Color inkRise;
  final Color inkEdge;
  final Color inkLine;
  final Color inkLineSoft;
  final Color inkMute;
  final Color inkLoud;
  final Color accent;
  final Color accentDeep;
  final Color accentSoft;
  final Color accentGlow;
  final Color positive;
  final Color warning;
  final Color info;

  const SpotColors({
    required this.inkVoid,
    required this.inkBase,
    required this.inkRise,
    required this.inkEdge,
    required this.inkLine,
    required this.inkLineSoft,
    required this.inkMute,
    required this.inkLoud,
    required this.accent,
    required this.accentDeep,
    required this.accentSoft,
    required this.accentGlow,
    required this.positive,
    required this.warning,
    required this.info,
  });

  static const dark = SpotColors(
    inkVoid: Color(0xFF0B0B0C),
    inkBase: Color(0xFF161514),
    inkRise: Color(0xFF1F1D1C),
    inkEdge: Color(0xFF2A2826),
    inkLine: Color(0xFF3F3D3C),
    inkLineSoft: Color(0x803F3D3C),
    inkMute: Color(0xFF8C8988),
    inkLoud: Color(0xFFF9F9F9),
    accent: Color(0xFFDE0C2F),
    accentDeep: Color(0xFFA20A25),
    accentSoft: Color(0xFFF05A6C),
    accentGlow: Color(0x2EDE0C2F),
    positive: Color(0xFF02B663),
    warning: Color(0xFFFF6D37),
    info: Color(0xFF2934F1),
  );

  static const light = SpotColors(
    inkVoid: Color(0xFFF9F9F9),
    inkBase: Color(0xFFFFFFFF),
    inkRise: Color(0xFFFFFFFF),
    inkEdge: Color(0xFFF0F4F8),
    inkLine: Color(0xFFD8DADF),
    inkLineSoft: Color(0x99D8DADF),
    inkMute: Color(0xFF666362),
    inkLoud: Color(0xFF1F252C),
    accent: Color(0xFFDE0C2F),
    accentDeep: Color(0xFFA20A25),
    accentSoft: Color(0xFFF05A6C),
    accentGlow: Color(0x1FDE0C2F),
    positive: Color(0xFF02B663),
    warning: Color(0xFFFF6D37),
    info: Color(0xFF2934F1),
  );
}

class SpotSpacing {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
  static const double s7 = 48;
  static const double s8 = 72;
  static const double s9 = 112;
}

class SpotRadius {
  static const double pill = 999;
  static const double sm = 4;
  static const double md = 10;
  static const double lg = 16;
}

class SpotMotion {
  static const Curve curve = Cubic(0.2, 0.7, 0.2, 1);
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration med = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 540);
  static const Duration pulse = Duration(milliseconds: 1800);
}
```

- [ ] **Step 2: Verificar compilação**

```bash
flutter analyze lib/ui/theme/spot_tokens.dart
```

Expected: no issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/theme/spot_tokens.dart
git commit -m "feat(flutter): tokens SPOT (cores dark/light, espacos, raios, motion)"
```

---

### Task E3: spot_theme.dart

**Files:**
- Create: `C:/vscode_projects/sonora_flutter_app/lib/ui/theme/spot_theme.dart`

- [ ] **Step 1: Criar arquivo**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'spot_tokens.dart';

class SpotTheme {
  static ThemeData build({required Brightness brightness}) {
    final colors = brightness == Brightness.dark
        ? SpotColors.dark
        : SpotColors.light;

    final body = GoogleFonts.robotoTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );
    final display = GoogleFonts.montserratTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    final textTheme = body.copyWith(
      displayLarge: display.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,
        fontSize: 56,
        height: 0.95,
        letterSpacing: -2.2,
        color: colors.inkLoud,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        fontWeight: FontWeight.w900,
        fontSize: 36,
        height: 1,
        letterSpacing: -1.1,
        color: colors.inkLoud,
      ),
      titleLarge: display.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 22,
        letterSpacing: -0.4,
        color: colors.inkLoud,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: colors.inkLoud,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 15,
        height: 1.55,
        color: colors.inkLoud,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 13,
        color: colors.inkMute,
        letterSpacing: 0.13,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 2,
        color: colors.inkMute,
      ),
    );

    final colorScheme = brightness == Brightness.dark
        ? ColorScheme.dark(
            surface: colors.inkBase,
            primary: colors.accent,
            onPrimary: Colors.white,
            secondary: colors.accentSoft,
            error: colors.warning,
            onSurface: colors.inkLoud,
          )
        : ColorScheme.light(
            surface: colors.inkBase,
            primary: colors.accent,
            onPrimary: Colors.white,
            secondary: colors.accentSoft,
            error: colors.warning,
            onSurface: colors.inkLoud,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.inkVoid,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        SpotColorsExt(colors),
      ],
      iconTheme: IconThemeData(color: colors.inkMute, size: 20),
      dividerTheme: DividerThemeData(color: colors.inkLine, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.inkVoid,
        foregroundColor: colors.inkLoud,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: SpotSpacing.s5,
      ),
    );
  }
}

@immutable
class SpotColorsExt extends ThemeExtension<SpotColorsExt> {
  final SpotColors palette;
  const SpotColorsExt(this.palette);

  @override
  SpotColorsExt copyWith({SpotColors? palette}) =>
      SpotColorsExt(palette ?? this.palette);

  @override
  SpotColorsExt lerp(ThemeExtension<SpotColorsExt>? other, double t) {
    if (other is! SpotColorsExt) return this;
    return t < 0.5 ? this : other;
  }

  static SpotColors of(BuildContext context) =>
      Theme.of(context).extension<SpotColorsExt>()!.palette;
}
```

- [ ] **Step 2: Verificar análise**

```bash
flutter analyze lib/ui/theme/spot_theme.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/theme/spot_theme.dart
git commit -m "feat(flutter): SpotTheme dark+light com TextTheme MIV"
```

---

### Task E4: spot_widgets.dart — primitivos

**Files:**
- Create: `C:/vscode_projects/sonora_flutter_app/lib/ui/theme/spot_widgets.dart`

- [ ] **Step 1: Criar arquivo**

```dart
import 'package:flutter/material.dart';

import 'spot_theme.dart';
import 'spot_tokens.dart';

class SpotDot extends StatelessWidget {
  final double size;
  final Color? color;
  const SpotDot({super.key, this.size = 8, this.color});

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? palette.accent,
        shape: BoxShape.circle,
      ),
    );
  }
}

class SpotDotLive extends StatefulWidget {
  final double size;
  const SpotDotLive({super.key, this.size = 10});

  @override
  State<SpotDotLive> createState() => _SpotDotLiveState();
}

class _SpotDotLiveState extends State<SpotDotLive>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: SpotMotion.pulse,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final radius = t * 14;
        final opacity = (1 - t).clamp(0.0, 1.0) * 0.6;
        return Container(
          width: widget.size + 14,
          height: widget.size + 14,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: opacity),
                blurRadius: 0,
                spreadRadius: radius,
              ),
            ],
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: palette.accent,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class SpotRing extends StatelessWidget {
  final double size;
  final Color? color;
  final double opacity;
  const SpotRing({super.key, this.size = 160, this.color, this.opacity = 0.4});

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: (color ?? palette.inkLine).withValues(alpha: opacity),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class SpotKicker extends StatelessWidget {
  final String text;
  const SpotKicker(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SpotDot(size: 8),
        const SizedBox(width: SpotSpacing.s2),
        Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class SpotChip extends StatelessWidget {
  final String label;
  final Color? color;
  const SpotChip({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SpotSpacing.s3, vertical: 4),
      decoration: BoxDecoration(
        color: palette.inkEdge,
        borderRadius: BorderRadius.circular(SpotRadius.pill),
        border: Border.all(color: palette.inkLine, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: SpotSpacing.s2),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.inkMute,
            ),
          ),
        ],
      ),
    );
  }
}

class SpotField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const SpotField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: palette.inkLoud, fontSize: 16),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(color: palette.inkMute),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: palette.inkLine, width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: palette.accent, width: 1.5),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: palette.warning, width: 1.5),
            ),
            focusedErrorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: palette.warning, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class SpotButtonPrimary extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool wide;
  const SpotButtonPrimary({
    super.key,
    required this.label,
    required this.onPressed,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: palette.inkEdge,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpotRadius.pill),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      child: Text(label),
    );
    return wide ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class SpotButtonGhost extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool wide;
  const SpotButtonGhost({
    super.key,
    required this.label,
    required this.onPressed,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.inkLoud,
        side: BorderSide(color: palette.inkLine),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpotRadius.pill),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      child: Text(label),
    );
    return wide ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class SpotPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool ringTopRight;
  const SpotPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SpotSpacing.s6),
    this.ringTopRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Container(
          decoration: BoxDecoration(
            color: palette.inkRise,
            border: Border.all(color: palette.inkLine, width: 1),
            borderRadius: BorderRadius.circular(SpotRadius.lg),
          ),
          padding: padding,
          child: child,
        ),
        if (ringTopRight)
          Positioned(
            right: -80,
            top: -80,
            child: SpotRing(size: 200, opacity: 0.35),
          ),
      ],
    );
  }
}

class SpotDivider extends StatelessWidget {
  const SpotDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpotSpacing.s5),
      child: Row(
        children: [
          const SpotDot(size: 6),
          const SizedBox(width: SpotSpacing.s3),
          Expanded(child: Container(height: 1, color: palette.inkLine)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verificar análise**

```bash
flutter analyze lib/ui/theme/spot_widgets.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/theme/spot_widgets.dart
git commit -m "feat(flutter): widgets SPOT (Dot, DotLive, Ring, Field, Panel...)"
```

---

### Task E5: ThemeNotifier + SonoraApp

**Files:**
- Create: `C:/vscode_projects/sonora_flutter_app/lib/state/theme_notifier.dart`
- Modify: `C:/vscode_projects/sonora_flutter_app/lib/ui/sonora_app.dart`
- Modify: `C:/vscode_projects/sonora_flutter_app/lib/main.dart`

- [ ] **Step 1: Criar `theme_notifier.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  static const _key = 'spot-theme';
  final SharedPreferences _preferences;
  ThemeMode _mode;

  ThemeNotifier(this._preferences) : _mode = _read(_preferences);

  static ThemeMode _read(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == 'light') return ThemeMode.light;
    return ThemeMode.dark;
  }

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _preferences.setString(_key, _mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }
}
```

- [ ] **Step 2: Atualizar `sonora_app.dart`**

```dart
import 'package:flutter/material.dart';

import '../state/app_session.dart';
import '../state/theme_notifier.dart';
import 'theme/spot_theme.dart';
import 'workspace_screen.dart';
import 'login_screen.dart';

class SonoraApp extends StatelessWidget {
  const SonoraApp({super.key, required this.session, required this.themeNotifier});

  final AppSession session;
  final ThemeNotifier themeNotifier;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([session, themeNotifier]),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SPOT Sonora',
          theme: SpotTheme.build(brightness: Brightness.light),
          darkTheme: SpotTheme.build(brightness: Brightness.dark),
          themeMode: themeNotifier.mode,
          home: session.isLoading
              ? const _BootScreen()
              : session.isAuthenticated
                  ? WorkspaceScreen(session: session, themeNotifier: themeNotifier)
                  : LoginScreen(session: session, themeNotifier: themeNotifier),
        );
      },
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
```

- [ ] **Step 3: Atualizar `main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'data/sonora_api.dart';
import 'state/app_session.dart';
import 'state/theme_notifier.dart';
import 'ui/sonora_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  final preferences = await SharedPreferences.getInstance();
  final api = SonoraApi(baseUrl: Uri.parse(apiBaseUrl), client: http.Client());

  runApp(
    SonoraApp(
      session: AppSession(api: api, preferences: preferences)..restore(),
      themeNotifier: ThemeNotifier(preferences),
    ),
  );
}
```

- [ ] **Step 4: Teste unitário do ThemeNotifier**

Criar `test/theme_notifier_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonora_flutter_app/state/theme_notifier.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('default mode is dark when no preference saved', () async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = ThemeNotifier(prefs);
    expect(notifier.isDark, isTrue);
  });

  test('toggle persists to shared preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifier = ThemeNotifier(prefs);

    await notifier.toggle();

    expect(notifier.isDark, isFalse);
    expect(prefs.getString('spot-theme'), equals('light'));
  });

  test('reads saved light preference', () async {
    SharedPreferences.setMockInitialValues({'spot-theme': 'light'});
    final prefs = await SharedPreferences.getInstance();
    final notifier = ThemeNotifier(prefs);
    expect(notifier.isDark, isFalse);
  });
}
```

- [ ] **Step 5: Rodar teste**

```bash
flutter test test/theme_notifier_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/state/theme_notifier.dart lib/ui/sonora_app.dart lib/main.dart test/theme_notifier_test.dart
git commit -m "feat(flutter): ThemeNotifier persistente e wiring no SonoraApp"
```

---

## Phase F — Flutter screens

### Task F1: Refatorar login_screen.dart

**Files:**
- Modify (rewrite): `C:/vscode_projects/sonora_flutter_app/lib/ui/login_screen.dart`

- [ ] **Step 1: Substituir conteúdo**

```dart
import 'package:flutter/material.dart';

import '../state/app_session.dart';
import '../state/theme_notifier.dart';
import 'theme/spot_theme.dart';
import 'theme/spot_tokens.dart';
import 'theme/spot_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.session, required this.themeNotifier});

  final AppSession session;
  final ThemeNotifier themeNotifier;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@sonora.app');
  final _passwordController = TextEditingController(text: 'password');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.session.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    final story = Stack(
      children: [
        Positioned(
          right: -40,
          bottom: -80,
          child: SpotRing(size: 280, opacity: 0.35),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SpotSpacing.s7, SpotSpacing.s8, SpotSpacing.s7, SpotSpacing.s8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SpotKicker('SPOT Sonora'),
              const SizedBox(height: SpotSpacing.s4),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.displayLarge,
                  children: [
                    const TextSpan(text: 'Onde a estrategia\n'),
                    TextSpan(
                      text: 'encontra',
                      style: TextStyle(color: palette.accent),
                    ),
                    const TextSpan(text: '\na execucao.'),
                  ],
                ),
              ),
              const SizedBox(height: SpotSpacing.s5),
              SizedBox(
                width: 360,
                child: Text(
                  'Captacao, leitura e operacao em uma esteira unica.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.inkMute),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final card = Container(
      color: palette.inkBase,
      padding: const EdgeInsets.all(SpotSpacing.s7),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SpotKicker('Acesso'),
                const SizedBox(height: SpotSpacing.s3),
                Text('Entre na sessao',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: SpotSpacing.s5),
                SpotField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Informe um email valido.'
                      : null,
                ),
                const SizedBox(height: SpotSpacing.s4),
                SpotField(
                  controller: _passwordController,
                  label: 'Senha',
                  obscureText: true,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Informe a senha.'
                      : null,
                ),
                if (widget.session.errorMessage != null) ...[
                  const SizedBox(height: SpotSpacing.s3),
                  Text(widget.session.errorMessage!,
                      style: TextStyle(color: palette.warning, fontSize: 13)),
                ],
                const SizedBox(height: SpotSpacing.s5),
                SpotButtonPrimary(
                  label: widget.session.isBusy ? 'Entrando...' : 'Entrar',
                  onPressed: widget.session.isBusy ? null : _submit,
                  wide: true,
                ),
                const SizedBox(height: SpotSpacing.s3),
                TextButton(
                  onPressed: widget.themeNotifier.toggle,
                  child: Text(
                    widget.themeNotifier.isDark ? '☾ Alternar para claro' : '☀ Alternar para escuro',
                    style: TextStyle(color: palette.inkMute),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  Expanded(child: story),
                  Expanded(child: card),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 320, child: story),
                    card,
                  ],
                ),
              ),
      ),
    );
  }
}
```

- [ ] **Step 2: Análise**

```bash
flutter analyze lib/ui/login_screen.dart
```

- [ ] **Step 3: Smoke (Flutter Windows ou web)**

```bash
flutter run -d windows
```

(Ou `-d chrome` se preferir web.) Confira: split editorial em desktop, stack em mobile, vermelho em "encontra", toggle de tema.

- [ ] **Step 4: Commit**

```bash
git add lib/ui/login_screen.dart
git commit -m "feat(flutter): login editorial split com mensagem-chave MIV"
```

---

### Task F2: Refatorar workspace_screen.dart com bottom nav SPOTLIGHT

**Files:**
- Modify (rewrite): `C:/vscode_projects/sonora_flutter_app/lib/ui/workspace_screen.dart`
- Create: `C:/vscode_projects/sonora_flutter_app/lib/ui/views/home_view.dart`
- Create: `C:/vscode_projects/sonora_flutter_app/lib/ui/views/library_view.dart`
- Create: `C:/vscode_projects/sonora_flutter_app/lib/ui/views/settings_view.dart`

- [ ] **Step 1: Criar `lib/ui/views/home_view.dart`**

```dart
import 'package:flutter/material.dart';

import '../../state/app_session.dart';
import '../theme/spot_theme.dart';
import '../theme/spot_tokens.dart';
import '../theme/spot_widgets.dart';

class HomeView extends StatelessWidget {
  final AppSession session;
  final Future<void> Function() onRefresh;
  const HomeView({super.key, required this.session, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    final ready = session.recordings.where((r) => r.status == 'ready').length;
    final failed = session.recordings.where((r) => r.status == 'failed').length;
    final processing = session.recordings.length - ready - failed;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: SpotSpacing.s5, vertical: SpotSpacing.s5),
        children: [
          const SpotKicker('Comando central'),
          const SizedBox(height: SpotSpacing.s3),
          Text('Grave agora.\nExecute depois.',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: SpotSpacing.s4),
          Text(
            'Projeto ativo: ${session.activeProject?.name ?? "Sem projeto"}',
            style: TextStyle(color: palette.inkMute, fontSize: 14),
          ),
          const SizedBox(height: SpotSpacing.s6),
          _MetricRow(
            entries: [
              _Metric('Notas', session.recordings.length.toString()),
              _Metric('Processando', processing.toString()),
              _Metric('Prontas', ready.toString()),
            ],
          ),
          const SizedBox(height: SpotSpacing.s6),
          SpotPanel(
            ringTopRight: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SpotKicker('Captacao'),
                const SizedBox(height: SpotSpacing.s5),
                _MicButton(session: session),
                const SizedBox(height: SpotSpacing.s4),
                Text(
                  'Toque para iniciar a captacao via microfone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.inkMute, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric {
  final String label;
  final String value;
  _Metric(this.label, this.value);
}

class _MetricRow extends StatelessWidget {
  final List<_Metric> entries;
  const _MetricRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: palette.inkLine, width: 1),
          bottom: BorderSide(color: palette.inkLine, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: SpotSpacing.s4),
      child: Row(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entries[i].label.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(entries[i].value,
                      style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
            ),
            if (i < entries.length - 1)
              Container(width: 1, height: 48, color: palette.inkLine),
          ],
        ],
      ),
    );
  }
}

class _MicButton extends StatefulWidget {
  final AppSession session;
  const _MicButton({required this.session});

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> {
  bool _isRecording = false;

  void _toggle() {
    setState(() => _isRecording = !_isRecording);
  }

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: SpotMotion.fast,
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isRecording ? palette.inkBase : palette.inkRise,
          border: Border.all(
            color: _isRecording ? palette.accent : palette.inkLine,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isRecording ? const SpotDotLive() : const SpotDot(size: 14),
            const SizedBox(height: 8),
            Text(
              _isRecording ? 'PARAR' : 'INICIAR',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Criar `lib/ui/views/library_view.dart`**

```dart
import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../state/app_session.dart';
import '../theme/spot_theme.dart';
import '../theme/spot_tokens.dart';
import '../theme/spot_widgets.dart';

class LibraryView extends StatelessWidget {
  final AppSession session;
  final Future<void> Function() onRefresh;
  const LibraryView({super.key, required this.session, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    final recordings = session.recordings;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                SpotSpacing.s5, SpotSpacing.s5, SpotSpacing.s5, SpotSpacing.s3),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SpotKicker('Library'),
                const SizedBox(height: SpotSpacing.s3),
                Text('Indice de gravacoes',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: SpotSpacing.s4),
              ]),
            ),
          ),
          if (recordings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(SpotSpacing.s5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SpotKicker('Sem registros'),
                    const SizedBox(height: SpotSpacing.s3),
                    Text('Nenhuma gravacao por aqui.',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: SpotSpacing.s3),
                    Text(
                      'Inicie pela home capturando ou enviando audio.',
                      style: TextStyle(color: palette.inkMute, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList.separated(
              itemCount: recordings.length,
              separatorBuilder: (_, __) =>
                  Container(height: 1, color: palette.inkLine),
              itemBuilder: (context, index) {
                return _RecordingRow(
                  index: index + 1,
                  recording: recordings[index],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RecordingRow extends StatelessWidget {
  final int index;
  final Recording recording;
  const _RecordingRow({required this.index, required this.recording});

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    final statusColor = switch (recording.status) {
      'ready' => palette.positive,
      'failed' => palette.warning,
      'processing_transcript' => palette.accent,
      _ => palette.inkMute,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: SpotSpacing.s5, vertical: SpotSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: TextStyle(
                fontFamily: 'RobotoMono',
                color: palette.inkMute,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recording.title.isNotEmpty
                      ? recording.title
                      : 'Gravacao sem titulo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  recording.summary ?? 'Resumo indisponivel.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.inkMute, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: SpotSpacing.s3),
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Criar `lib/ui/views/settings_view.dart`**

```dart
import 'package:flutter/material.dart';

import '../../state/app_session.dart';
import '../../state/theme_notifier.dart';
import '../theme/spot_theme.dart';
import '../theme/spot_tokens.dart';
import '../theme/spot_widgets.dart';

class SettingsView extends StatelessWidget {
  final AppSession session;
  final ThemeNotifier themeNotifier;
  const SettingsView({super.key, required this.session, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    final user = session.user;

    return ListView(
      padding: const EdgeInsets.all(SpotSpacing.s5),
      children: [
        const SpotKicker('Settings'),
        const SizedBox(height: SpotSpacing.s3),
        Text('Sessao e organizacao',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: SpotSpacing.s6),
        const SpotKicker('I · Perfil'),
        const SizedBox(height: SpotSpacing.s3),
        Text(user?.fullName ?? user?.email ?? '—',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: SpotSpacing.s2),
        if (user?.email != null)
          Text(user!.email, style: TextStyle(color: palette.inkMute)),
        const SpotDivider(),
        const SpotKicker('II · Tema'),
        const SizedBox(height: SpotSpacing.s3),
        SpotButtonGhost(
          label: themeNotifier.isDark ? 'Alternar para tema claro' : 'Alternar para tema escuro',
          onPressed: themeNotifier.toggle,
        ),
        const SpotDivider(),
        const SpotKicker('III · Sessao'),
        const SizedBox(height: SpotSpacing.s3),
        Text(
          'Encerra a sessao no dispositivo atual.',
          style: TextStyle(color: palette.inkMute, fontSize: 13),
        ),
        const SizedBox(height: SpotSpacing.s3),
        SpotButtonGhost(label: 'Sair', onPressed: session.logout),
      ],
    );
  }
}
```

- [ ] **Step 4: Reescrever `workspace_screen.dart`**

```dart
import 'package:flutter/material.dart';

import '../state/app_session.dart';
import '../state/theme_notifier.dart';
import 'theme/spot_theme.dart';
import 'theme/spot_tokens.dart';
import 'theme/spot_widgets.dart';
import 'views/home_view.dart';
import 'views/library_view.dart';
import 'views/settings_view.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({
    super.key,
    required this.session,
    required this.themeNotifier,
  });

  final AppSession session;
  final ThemeNotifier themeNotifier;

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  int _index = 0;

  Future<void> _refresh() async {
    await widget.session.refreshWorkspace();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    final views = [
      HomeView(session: widget.session, onRefresh: _refresh),
      LibraryView(session: widget.session, onRefresh: _refresh),
      SettingsView(session: widget.session, themeNotifier: widget.themeNotifier),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        title: Row(
          children: [
            const SpotKicker('PROJETO'),
            const SizedBox(width: SpotSpacing.s3),
            Flexible(
              child: Text(
                widget.session.activeProject?.name ?? 'Sem projeto',
                style: TextStyle(fontWeight: FontWeight.w700, color: palette.inkLoud),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.themeNotifier.isDark ? 'Claro' : 'Escuro',
            onPressed: widget.themeNotifier.toggle,
            icon: Text(
              widget.themeNotifier.isDark ? '☾' : '☀',
              style: TextStyle(color: palette.inkMute, fontSize: 18),
            ),
          ),
          const SizedBox(width: SpotSpacing.s2),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: palette.inkLine),
        ),
      ),
      body: SafeArea(child: IndexedStack(index: _index, children: views)),
      bottomNavigationBar: _SpotBottomNav(
        index: _index,
        onSelect: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _SpotBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const _SpotBottomNav({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final palette = SpotColorsExt.of(context);
    final items = const [
      _NavItem(label: 'Home', icon: Icons.home_outlined),
      _NavItem(label: 'Library', icon: Icons.library_books_outlined),
      _NavItem(label: 'Settings', icon: Icons.settings_outlined),
    ];

    return Container(
      decoration: BoxDecoration(
        color: palette.inkVoid,
        border: Border(top: BorderSide(color: palette.inkLine, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = i == index;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: Stack(
                    children: [
                      if (isActive)
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 0),
                            width: 24,
                            height: 2,
                            color: palette.accent,
                          ),
                        ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              items[i].icon,
                              size: 22,
                              color: isActive ? palette.inkLoud : palette.inkMute,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              items[i].label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: isActive ? palette.inkLoud : palette.inkMute,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem({required this.label, required this.icon});
}
```

- [ ] **Step 5: Verificar que `AppSession` expõe `activeProject` e `user`**

```bash
grep -n "activeProject\|fullName\|class AppSession\|class User\b" "C:/vscode_projects/sonora_flutter_app/lib/state/app_session.dart" "C:/vscode_projects/sonora_flutter_app/lib/domain/models.dart"
```

Se `activeProject` não existir no `AppSession`, ajuste o `home_view` e `workspace_screen` para usar `session.projects.firstOrNull?.name` em vez disso, e remova a referência.

Se `User` não tiver `fullName`, ajuste o `settings_view` para usar só `email`.

- [ ] **Step 6: Análise + teste**

```bash
flutter analyze
flutter test
```

Expected: no issues. Testes passam.

- [ ] **Step 7: Commit**

```bash
git add lib/ui/workspace_screen.dart lib/ui/views/
git commit -m "feat(flutter): workspace shell + Home/Library/Settings views editoriais"
```

---

### Task F3: Widget test para SpotDot e SpotDotLive

**Files:**
- Create: `C:/vscode_projects/sonora_flutter_app/test/spot_widgets_test.dart`

- [ ] **Step 1: Criar teste**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonora_flutter_app/ui/theme/spot_theme.dart';
import 'package:sonora_flutter_app/ui/theme/spot_widgets.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: SpotTheme.build(brightness: Brightness.dark),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('SpotDot renders as a circle with default size', (tester) async {
    await tester.pumpWidget(_wrap(const SpotDot()));
    final dot = tester.widget<Container>(find.byType(Container).first);
    final decoration = dot.decoration as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, isNotNull);
  });

  testWidgets('SpotDotLive animates and pumps without error', (tester) async {
    await tester.pumpWidget(_wrap(const SpotDotLive()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SpotDotLive), findsOneWidget);
  });

  testWidgets('SpotKicker renders text uppercase', (tester) async {
    await tester.pumpWidget(_wrap(const SpotKicker('projeto ativo')));
    expect(find.text('PROJETO ATIVO'), findsOneWidget);
  });

  testWidgets('SpotField shows label and validates required', (tester) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(_wrap(Form(
      key: formKey,
      child: SpotField(
        controller: controller,
        label: 'Email',
        validator: (v) => (v == null || v.isEmpty) ? 'Obrigatorio' : null,
      ),
    )));
    expect(find.text('EMAIL'), findsOneWidget);
    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('Obrigatorio'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar**

```bash
flutter test test/spot_widgets_test.dart
```

Expected: 4 passes.

- [ ] **Step 3: Commit**

```bash
git add test/spot_widgets_test.dart
git commit -m "test(flutter): widget tests para primitivos SPOT"
```

---

## Phase G — Final verification & docs

### Task G1: Verificação cruzada e finalização

- [ ] **Step 1: Rodar suite completa do web**

```bash
cd C:/vscode_projects/Plaude_like
php artisan test
npm run build
```

Expected: testes verdes, build limpo.

- [ ] **Step 2: Rodar suite completa do Flutter**

```bash
cd C:/vscode_projects/sonora_flutter_app
flutter analyze
flutter test
```

Expected: zero analyzer issues, todos os testes passam.

- [ ] **Step 3: Smoke duplo (web + Flutter rodando simultaneamente)**

Terminal 1: `cd C:/vscode_projects/Plaude_like && php artisan serve`
Terminal 2: `cd C:/vscode_projects/sonora_flutter_app && flutter run -d windows`

Checklist visual:
- [ ] Web `/login` e Flutter login mostram a mesma manchete editorial
- [ ] Toggle de tema funciona nos dois e cada um persiste seu próprio estado
- [ ] Web `/library` (índice numerado) e Flutter Library (índice numerado) compartilham a linguagem
- [ ] Status dots usam as mesmas cores tokenizadas
- [ ] Botão de mic 120px presente no `/` web e no Home Flutter

- [ ] **Step 4: Atualizar README do web indicando o novo sistema (apenas se já houver seção de UI)**

Se `README.md` ou `docs/api.md` mencionarem o tema/UI antigo, atualize a referência. Caso contrário, pular.

- [ ] **Step 5: Commit final + push da branch**

```bash
cd C:/vscode_projects/Plaude_like
git status
git push -u origin feat/spotlight-redesign
```

Expected: branch publicada. **Não criar PR automaticamente** — o usuário decide quando abrir.

```bash
cd C:/vscode_projects/sonora_flutter_app
git status
git checkout -b feat/spotlight-redesign 2>/dev/null || git checkout feat/spotlight-redesign
git push -u origin feat/spotlight-redesign
```

(O repo Flutter pode não estar versionado; verifique com `git status` antes. Se for um repo Git válido, publique; se não, ignore o push.)

---

## Self-review notes (do autor do plano)

**Spec coverage:**
- §1 tokens → Task A3 (CSS) + E2 (Dart)
- §2 tipografia/escala → A3 + E3
- §3 vocabulário do "O" → A3 (CSS) + E4 (Dart widgets)
- §4 shell rail+main → A5
- §5 telas web (auth/home/library/recording show/chat/settings/admin) → B1–B6 + C1–C2 + D1
- §6 Flutter parity → E1–E5 + F1–F3

Coverage OK. Recording detail e Chat **não estão portados para Flutter neste plano** — o spec mencionou views novas mas o app Flutter atual só usa workspace + library. Portar essas views para Flutter pode virar follow-up se o usuário quiser; documentado como omissão consciente nos critérios de aceitação 5 (5 views ⇒ Login + Home + Library + Settings + Workspace shell = 5, dentro do limite).

**Placeholder scan:** sem TBDs, sem "implementar depois". Cada step tem código completo ou comando exato. As variáveis de Blade desconhecidas (`$summaryStats`, `$messages`, `$counts`) recebem uma leitura prévia (`cat`) para confirmação antes da escrita.

**Type consistency:** `ThemeNotifier`, `SpotColors`, `SpotColorsExt.of`, `SpotDotLive`, `SpotField`, `SpotPanel(ringTopRight:)` — nomes idênticos em todos os usos (login, workspace, views).

**Riscos conhecidos:** controller `library` pode estar entregando coleções separadas tipo Kanban (`$inbox`, `$ready`, `$failed`) em vez de paginação única. Task B3 step 1 obriga leitura prévia; ajuste embutido se necessário.
