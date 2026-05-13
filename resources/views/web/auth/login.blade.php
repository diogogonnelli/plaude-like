@extends('layouts.base')

@section('title', ($brandName ?? config('app.name', 'Sonora')).' | Entrar')

@section('body')
    <div class="auth-shell">
        <aside class="auth-story">
            <span class="ring ring--lg" aria-hidden="true"></span>
            <div class="kicker-row"><span class="dot"></span><span class="type-kicker">{{ $brandName ?? 'SPOT Sonora' }}</span></div>
            <h1 class="type-display auth-story-headline">
                Onde a estrategia <em>encontra</em> a execucao.
            </h1>
            <p class="type-body" style="max-width: 48ch; color: var(--ink-mute); margin-top: var(--sp-5);">
                Captacao, leitura e operacao em uma esteira unica. Home, library, detalhe, chat e admin no mesmo shell.
            </p>
        </aside>

        <section class="auth-card">
            <div class="kicker-row"><span class="dot"></span><span class="type-kicker">Acesso</span></div>
            <h2 class="auth-title">Entre na sessao</h2>
            <p class="type-meta" style="margin-top: var(--sp-2); margin-bottom: var(--sp-5);">
                Use a conta provisionada neste ambiente para acessar o workspace.
            </p>

            @include('web.partials.flash')

            <form class="auth-form" method="POST" action="{{ route('login') }}">
                @csrf
                <div class="field-grid">
                    <label for="login-email">Email</label>
                    <input class="field-input" id="login-email" type="email" name="email" value="{{ old('email') }}" required autocomplete="email">
                </div>

                <div class="field-grid">
                    <label for="login-password">Senha</label>
                    <input class="field-input" id="login-password" type="password" name="password" required autocomplete="current-password">
                </div>

                <button class="btn-primary btn-wide" type="submit" style="margin-top: var(--sp-3);">Entrar</button>
                <button type="button" class="btn-quiet" data-theme-toggle aria-label="Alternar tema" style="align-self: flex-start;">
                    <span data-theme-toggle-label>☾</span> Alternar tema
                </button>
            </form>
        </section>
    </div>
@endsection
