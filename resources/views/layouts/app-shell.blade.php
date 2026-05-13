@extends('layouts.base')

@section('body')
    <div class="app-shell">
        <aside class="shell-sidebar">
            <div class="brand-card">
                <div class="brand-kicker">SPOT endorsed workflow</div>
                @include('web.partials.wordmark', [
                    'brandName' => $brandName,
                    'subtitle' => 'Captacao, leitura e operacao',
                    'href' => route('workspace.home'),
                ])
                <h1 class="brand-title">{{ $brandName }}</h1>
                <p class="brand-copy">
                    Shell web unico para gravacoes, biblioteca, chat e organizacao do fluxo operacional.
                </p>
            </div>

            <form class="shell-project-card" method="POST" action="{{ route('workspace.projects.active') }}">
                @csrf
                <div class="shell-kicker">Projeto ativo</div>
                <strong>{{ $activeProject?->name ?? 'Sem projeto' }}</strong>
                <p class="muted-copy">{{ $projects->count() }} projetos acessiveis nesta sessao.</p>
                <div class="field-grid">
                    <label for="sidebar-project-id">Selecionar projeto</label>
                    <select class="field-select" id="sidebar-project-id" name="project_id">
                        <option value="">Sem projeto</option>
                        @foreach ($projects as $projectOption)
                            <option value="{{ $projectOption->id }}" @selected(optional($activeProject)->id === $projectOption->id)>
                                {{ $projectOption->name }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <button class="button-secondary" type="submit">Aplicar projeto</button>
            </form>

            <nav class="shell-nav" aria-label="Navegacao principal">
                <a class="shell-nav-link {{ request()->routeIs('workspace.home') ? 'is-active' : '' }}" href="{{ route('workspace.home') }}">
                    <span class="shell-nav-icon">H</span>
                    <span class="shell-nav-copy">
                        <strong>Home</strong>
                        <span>Captacao e resumo rapido</span>
                    </span>
                </a>
                <a class="shell-nav-link {{ request()->routeIs('workspace.library') || request()->routeIs('workspace.recordings.*') ? 'is-active' : '' }}" href="{{ route('workspace.library') }}">
                    <span class="shell-nav-icon">L</span>
                    <span class="shell-nav-copy">
                        <strong>Library</strong>
                        <span>Fila, notas e transcript</span>
                    </span>
                </a>
                <a class="shell-nav-link {{ request()->routeIs('workspace.settings') ? 'is-active' : '' }}" href="{{ route('workspace.settings') }}">
                    <span class="shell-nav-icon">S</span>
                    <span class="shell-nav-copy">
                        <strong>Settings</strong>
                        <span>Sessao e organizacao</span>
                    </span>
                </a>
                @if ($showAdminNav)
                    <a class="shell-nav-link {{ request()->routeIs('workspace.admin.*') ? 'is-active' : '' }}" href="{{ route('workspace.admin.dashboard') }}">
                        <span class="shell-nav-icon">A</span>
                        <span class="shell-nav-copy">
                            <strong>Admin</strong>
                            <span>Usuarios, projetos e jobs</span>
                        </span>
                    </a>
                @endif
            </nav>

            <div class="shell-sidebar-footer">
                <div class="sidebar-meta">
                    <strong>{{ $user->full_name ?? $user->email }}</strong>
                    <span>{{ $user->email }}</span>
                    <span>{{ $user->profile?->name ?? 'Sem perfil' }}</span>
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
                    <div class="eyebrow">Fluxo web SPOT</div>
                    <h1 class="page-title">{{ $pageTitle ?? 'Workspace' }}</h1>
                    @if (! empty($pageSubtitle))
                        <p class="page-copy">{{ $pageSubtitle }}</p>
                    @endif
                </div>
                <div class="topbar-actions">
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
