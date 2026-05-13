@extends('layouts.base')

@section('body')
    <div class="app-shell">
        <aside class="rail" aria-label="Navegacao principal">
            <a class="rail-brand" href="{{ route('workspace.home') }}" aria-label="SPOT Sonora">
                <span>SP</span><span class="dot" aria-hidden="true"></span>
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
                        <span class="type-kicker"><span class="dot"></span> Projeto</span>
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
