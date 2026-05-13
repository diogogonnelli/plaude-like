@extends('layouts.base')

@section('title', ($brandName ?? config('app.name', 'Sonora')).' | Login')

@section('body')
    <div class="auth-shell">
        <div class="auth-grid">
            <section class="auth-card">
                <div class="brand-kicker">SPOT endorsed workflow</div>
                @include('web.partials.wordmark', [
                    'brandName' => $brandName ?? config('app.name', 'Sonora'),
                    'subtitle' => 'Frontend web Laravel',
                    'href' => route('home'),
                ])
                <h1 class="auth-title">Entrar no workspace</h1>
                <p class="page-copy">
                    Use a conta provisionada neste ambiente para acessar biblioteca, detalhe da gravacao e chat contextual.
                </p>

                <div class="page-stack">
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

                        <button class="button-primary button-wide" type="submit">Entrar</button>
                    </form>
                </div>
            </section>

            <section class="auth-story">
                <div class="brand-kicker">Produto co-branded com SPOT</div>
                <div class="spot-badge">
                    <span class="spot-badge-dot"></span>
                    <span>Shell unico com URLs dedicadas</span>
                </div>
                <h2 class="auth-title">Captacao, estrutura e execucao na mesma operacao.</h2>
                <p class="page-copy">
                    Esta experiencia web unifica home, library, detalhe, chat, settings e admin no Laravel principal.
                </p>

                <div class="overview-grid">
                    <article class="overview-card">
                        <span class="eyebrow">Home</span>
                        <strong>Upload + mic</strong>
                        <p class="muted-copy">Projeto ativo, captura por navegador e leitura rapida do pipeline.</p>
                    </article>
                    <article class="overview-card">
                        <span class="eyebrow">Library</span>
                        <strong>Fila operacional</strong>
                        <p class="muted-copy">Busca, filtros por projeto e agrupamento entre processando, prontas e falhas.</p>
                    </article>
                    <article class="overview-card">
                        <span class="eyebrow">Admin</span>
                        <strong>Backoffice web</strong>
                        <p class="muted-copy">Usuarios, perfis, projetos, gravacoes e jobs no mesmo visual.</p>
                    </article>
                </div>
            </section>
        </div>
    </div>
@endsection
