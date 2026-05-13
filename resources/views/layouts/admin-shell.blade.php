@extends('layouts.base')

@section('body')
    <div class="app-shell">
        <aside class="shell-sidebar">
            <div class="brand-card">
                <div class="brand-kicker">Backoffice SPOT</div>
                @include('web.partials.wordmark', [
                    'brandName' => $brandName.' Admin',
                    'subtitle' => 'Cadastros, projetos e operacao',
                    'href' => route('workspace.admin.dashboard'),
                ])
                <h1 class="brand-title">{{ $brandName }} Admin</h1>
                <p class="brand-copy">
                    Superficie unica para usuarios, perfis, projetos, gravacoes e monitoramento de jobs.
                </p>
            </div>

            <nav class="shell-nav" aria-label="Navegacao administrativa">
                <a class="shell-nav-link {{ request()->routeIs('workspace.admin.dashboard') ? 'is-active' : '' }}" href="{{ route('workspace.admin.dashboard') }}">
                    <span class="shell-nav-icon">D</span>
                    <span class="shell-nav-copy">
                        <strong>Dashboard</strong>
                        <span>Visao geral administrativa</span>
                    </span>
                </a>
                <a class="shell-nav-link {{ request()->routeIs('workspace.admin.users*') ? 'is-active' : '' }}" href="{{ route('workspace.admin.users') }}">
                    <span class="shell-nav-icon">U</span>
                    <span class="shell-nav-copy">
                        <strong>Users</strong>
                        <span>Pessoas e ativacao</span>
                    </span>
                </a>
                <a class="shell-nav-link {{ request()->routeIs('workspace.admin.profiles*') ? 'is-active' : '' }}" href="{{ route('workspace.admin.profiles') }}">
                    <span class="shell-nav-icon">P</span>
                    <span class="shell-nav-copy">
                        <strong>Profiles</strong>
                        <span>Papeis e acessos</span>
                    </span>
                </a>
                <a class="shell-nav-link {{ request()->routeIs('workspace.admin.projects*') ? 'is-active' : '' }}" href="{{ route('workspace.admin.projects') }}">
                    <span class="shell-nav-icon">J</span>
                    <span class="shell-nav-copy">
                        <strong>Projects</strong>
                        <span>Carteira e membros</span>
                    </span>
                </a>
                <a class="shell-nav-link {{ request()->routeIs('workspace.admin.recordings*') ? 'is-active' : '' }}" href="{{ route('workspace.admin.recordings') }}">
                    <span class="shell-nav-icon">R</span>
                    <span class="shell-nav-copy">
                        <strong>Recordings</strong>
                        <span>Detalhe e reprocessamento</span>
                    </span>
                </a>
                <a class="shell-nav-link {{ request()->routeIs('workspace.admin.jobs*') ? 'is-active' : '' }}" href="{{ route('workspace.admin.jobs') }}">
                    <span class="shell-nav-icon">Q</span>
                    <span class="shell-nav-copy">
                        <strong>Jobs</strong>
                        <span>Provider, fila e erro</span>
                    </span>
                </a>
                <a class="shell-nav-link" href="{{ route('workspace.home') }}">
                    <span class="shell-nav-icon">W</span>
                    <span class="shell-nav-copy">
                        <strong>Workspace</strong>
                        <span>Voltar ao app principal</span>
                    </span>
                </a>
            </nav>

            <div class="shell-sidebar-footer">
                <div class="sidebar-meta">
                    <strong>{{ $currentUser->full_name ?? $currentUser->email }}</strong>
                    <span>{{ $currentUser->email }}</span>
                    <span>{{ $currentUser->profile?->name ?? 'Sem perfil' }}</span>
                </div>

                <div class="sidebar-meta">
                    <strong>{{ $adminStats['recordings'] }} gravacoes</strong>
                    <span>{{ $adminStats['users'] }} usuarios</span>
                    <span>{{ $adminStats['projects'] }} projetos</span>
                </div>

                <form method="POST" action="{{ route('logout') }}">
                    @csrf
                    <button class="button-secondary button-wide" type="submit">Sair da sessao</button>
                </form>
            </div>
        </aside>

        <main class="shell-main">
            <header class="shell-topbar">
                <div>
                    <div class="eyebrow">Backoffice web</div>
                    <h1 class="page-title">{{ $pageTitle ?? 'Administracao' }}</h1>
                    @if (! empty($pageSubtitle))
                        <p class="page-copy">{{ $pageSubtitle }}</p>
                    @endif
                </div>
                <div class="topbar-actions">
                    <span class="topbar-badge">
                        <span>Auth</span>
                        <strong>Laravel session</strong>
                    </span>
                    @yield('topbar-actions')
                </div>
            </header>

            <div class="page-stack">
                @include('web.partials.flash')
                @yield('content')
            </div>
        </main>
    </div>
@endsection
