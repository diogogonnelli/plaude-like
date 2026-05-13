@extends('layouts.base')

@section('body')
    <div class="app-shell">
        <aside class="rail" aria-label="Navegacao administrativa">
            <a class="rail-brand" href="{{ route('workspace.admin.dashboard') }}" aria-label="SPOT Admin">
                <span>SP</span><span class="dot" aria-hidden="true"></span>
            </a>

            <a class="rail-link {{ request()->routeIs('workspace.admin.dashboard') ? 'is-active' : '' }}"
               href="{{ route('workspace.admin.dashboard') }}" data-tooltip="Dashboard">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
                    <rect x="3" y="3" width="8" height="8" rx="1"/>
                    <rect x="13" y="3" width="8" height="5" rx="1"/>
                    <rect x="13" y="10" width="8" height="11" rx="1"/>
                    <rect x="3" y="13" width="8" height="8" rx="1"/>
                </svg>
            </a>

            <a class="rail-link {{ request()->routeIs('workspace.admin.users*') ? 'is-active' : '' }}"
               href="{{ route('workspace.admin.users') }}" data-tooltip="Usuarios">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
                    <circle cx="12" cy="8" r="4"/>
                    <path d="M4 21c0-4 4-7 8-7s8 3 8 7"/>
                </svg>
            </a>

            <a class="rail-link {{ request()->routeIs('workspace.admin.profiles*') ? 'is-active' : '' }}"
               href="{{ route('workspace.admin.profiles') }}" data-tooltip="Perfis">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
                    <path d="M9 11l3 3 8-8"/>
                    <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
                </svg>
            </a>

            <a class="rail-link {{ request()->routeIs('workspace.admin.projects*') ? 'is-active' : '' }}"
               href="{{ route('workspace.admin.projects') }}" data-tooltip="Projetos">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
                    <path d="M3 7l3-3h5l2 2h8a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V7z"/>
                </svg>
            </a>

            <a class="rail-link {{ request()->routeIs('workspace.admin.recordings*') ? 'is-active' : '' }}"
               href="{{ route('workspace.admin.recordings') }}" data-tooltip="Gravacoes">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
                    <rect x="3" y="4" width="4" height="16" rx="1"/>
                    <rect x="10" y="4" width="4" height="16" rx="1"/>
                    <path d="M18 6l3 1-3 14-3-1z"/>
                </svg>
            </a>

            <a class="rail-link {{ request()->routeIs('workspace.admin.jobs*') ? 'is-active' : '' }}"
               href="{{ route('workspace.admin.jobs') }}" data-tooltip="Jobs">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
                    <circle cx="12" cy="12" r="9"/>
                    <path d="M12 7v5l3 2"/>
                </svg>
            </a>

            <a class="rail-link" href="{{ route('workspace.home') }}" data-tooltip="Workspace">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
                    <path d="M3 11l9-8 9 8v10a1 1 0 0 1-1 1h-5v-7h-6v7H4a1 1 0 0 1-1-1V11z"/>
                </svg>
            </a>

            <div class="rail-spacer"></div>

            <form method="POST" action="{{ route('logout') }}">
                @csrf
                <button class="rail-avatar" type="submit" title="Sair de {{ $currentUser->full_name ?? $currentUser->email }}">
                    {{ strtoupper(mb_substr($currentUser->full_name ?? $currentUser->email, 0, 1)) }}
                </button>
            </form>
        </aside>

        <main class="shell-main">
            <header class="shell-topbar">
                <div class="topbar-left">
                    <span class="type-kicker"><span class="dot"></span> Admin SPOT</span>
                    <span class="type-meta">{{ $adminStats['recordings'] }} gravacoes · {{ $adminStats['users'] }} usuarios · {{ $adminStats['projects'] }} projetos</span>
                </div>

                <div class="topbar-right">
                    @yield('topbar-actions')
                    <button type="button" class="theme-toggle" data-theme-toggle aria-label="Alternar tema" aria-pressed="false">☾</button>
                </div>
            </header>

            <div class="shell-content">
                <div>
                    <div class="kicker-row"><span class="dot"></span><span class="type-kicker">{{ $pageEyebrow ?? 'Backoffice SPOT' }}</span></div>
                    <h1 class="type-headline">{{ $pageTitle ?? 'Administracao' }}</h1>
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
