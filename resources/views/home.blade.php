@extends('layouts.base')

@php
    $isAuthenticated = $user !== null;
    $isAdmin = $isAuthenticated && $user->isAdmin();
@endphp

@section('body')
@if (! $isAuthenticated)
    <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-shell-dark via-shell to-accent px-lg py-xl">
        <div class="bg-surface rounded-lg shadow-xl p-xxl w-full max-w-md border border-stroke">
            <div class="text-center mb-xl">
                <span class="font-display text-3xl font-black tracking-tight text-shell-dark">Sonora</span>
                <p class="text-text-muted mt-xs">Gravacao inteligente em uma unica pagina.</p>
            </div>

            @if ($errors->any())
                <div class="bg-red-50 border border-accent text-accent rounded-sm p-md mb-md text-sm">
                    @foreach ($errors->all() as $error)
                        <p>{{ $error }}</p>
                    @endforeach
                </div>
            @endif

            <form method="POST" action="{{ route('home.submit') }}" class="space-y-md">
                @csrf
                <input type="hidden" name="intent" value="login">

                <div>
                    <label for="email" class="block text-sm font-bold text-text mb-xs">E-mail</label>
                    <input
                        type="email"
                        name="email"
                        id="email"
                        value="{{ old('email') }}"
                        required
                        autofocus
                        class="w-full rounded-md border border-stroke px-md py-sm focus:border-accent focus:ring-1 focus:ring-accent outline-none"
                    >
                </div>

                <div>
                    <label for="password" class="block text-sm font-bold text-text mb-xs">Senha</label>
                    <input
                        type="password"
                        name="password"
                        id="password"
                        required
                        class="w-full rounded-md border border-stroke px-md py-sm focus:border-accent focus:ring-1 focus:ring-accent outline-none"
                    >
                </div>

                <button
                    type="submit"
                    class="w-full bg-accent hover:bg-accent-soft text-white font-bold py-sm rounded-md transition-colors duration-200"
                >
                    Entrar
                </button>
            </form>
        </div>
    </div>
@else
    <div class="min-h-screen bg-canvas text-text">
        <div class="flex min-h-screen flex-col lg:flex-row">
            <aside class="w-full lg:w-72 bg-shell-dark text-white border-b border-white/10 lg:border-b-0 lg:border-r lg:border-white/10">
                <div class="p-xl">
                    <span class="font-display text-2xl font-black tracking-tight">Sonora</span>
                    <p class="text-sm text-white/70 mt-xs">{{ $user->full_name ?? $user->email }}</p>
                </div>

                <nav class="px-md pb-xl space-y-xs">
                    <a href="#resumo" class="block px-md py-sm rounded-sm bg-white/10 text-white font-bold">Resumo</a>
                    <a href="#gravacoes" class="block px-md py-sm rounded-sm text-white/80 hover:bg-white/10 hover:text-white transition-colors">Gravacoes Recentes</a>
                    <a href="#projetos" class="block px-md py-sm rounded-sm text-white/80 hover:bg-white/10 hover:text-white transition-colors">Projetos</a>
                    @if ($isAdmin)
                        <a href="#administracao" class="block px-md py-sm rounded-sm text-white/80 hover:bg-white/10 hover:text-white transition-colors">Administracao</a>
                    @endif
                </nav>
            </aside>

            <div class="flex-1 flex flex-col">
                <header class="bg-surface border-b border-stroke px-xl py-lg flex flex-col gap-md md:flex-row md:items-center md:justify-between">
                    <div>
                        <h1 class="text-2xl font-bold">Painel Sonora</h1>
                        <p class="text-text-muted text-sm">Tudo concentrado em uma unica pagina web.</p>
                    </div>

                    <form method="POST" action="{{ route('home.submit') }}">
                        @csrf
                        <input type="hidden" name="intent" value="logout">
                        <button type="submit" class="px-md py-sm rounded-md border border-stroke text-sm font-bold hover:bg-shell-dark hover:text-white transition-colors">
                            Sair
                        </button>
                    </form>
                </header>

                <main class="flex-1 p-xl space-y-xl">
                    <section id="resumo" class="space-y-md">
                        <div>
                            <h2 class="text-xl font-bold">Resumo</h2>
                            <p class="text-text-muted">Visao geral da operacao do usuario atual.</p>
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-3 gap-md">
                            <div class="bg-surface rounded-lg border border-stroke p-lg">
                                <p class="text-text-muted text-sm font-bold">Total Gravacoes</p>
                                <p class="text-2xl font-bold mt-xs">{{ $recordings->count() }}</p>
                            </div>
                            <div class="bg-surface rounded-lg border border-stroke p-lg">
                                <p class="text-text-muted text-sm font-bold">Prontas</p>
                                <p class="text-2xl font-bold mt-xs text-positive">{{ $recordings->where('status', 'ready')->count() }}</p>
                            </div>
                            <div class="bg-surface rounded-lg border border-stroke p-lg">
                                <p class="text-text-muted text-sm font-bold">Projetos ativos</p>
                                <p class="text-2xl font-bold mt-xs">{{ $projects->count() }}</p>
                            </div>
                        </div>
                    </section>

                    <section id="gravacoes" class="bg-surface rounded-lg border border-stroke">
                        <div class="p-lg border-b border-stroke">
                            <h2 class="font-bold text-lg">Gravacoes Recentes</h2>
                        </div>

                        <div class="divide-y divide-stroke">
                            @forelse ($recordings as $recording)
                                <div class="p-lg flex items-center justify-between gap-md">
                                    <div>
                                        <p class="font-bold">{{ $recording->title }}</p>
                                        <p class="text-sm text-text-muted">
                                            {{ $recording->created_at->format('d/m/Y H:i') }}
                                            @if ($recording->project)
                                                · {{ $recording->project->name }}
                                            @endif
                                        </p>
                                    </div>

                                    <span class="px-sm py-xxs rounded-pill text-xs font-bold
                                        @if ($recording->status === 'ready') bg-green-100 text-positive
                                        @elseif ($recording->status === 'failed') bg-red-100 text-accent
                                        @else bg-yellow-100 text-warning
                                        @endif">
                                        {{ $recording->status }}
                                    </span>
                                </div>
                            @empty
                                <div class="p-lg text-center text-text-muted">
                                    Nenhuma gravacao encontrada.
                                </div>
                            @endforelse
                        </div>
                    </section>

                    <section id="projetos" class="bg-surface rounded-lg border border-stroke">
                        <div class="p-lg border-b border-stroke">
                            <h2 class="font-bold text-lg">Projetos</h2>
                        </div>

                        <div class="p-lg space-y-sm">
                            @forelse ($projects as $project)
                                <div class="flex items-center justify-between gap-md border border-stroke rounded-md px-md py-sm">
                                    <div>
                                        <p class="font-bold">{{ $project->name }}</p>
                                        <p class="text-sm text-text-muted">{{ $project->slug }}</p>
                                    </div>
                                    <span class="text-xs font-bold uppercase tracking-wide text-text-muted">{{ $project->status }}</span>
                                </div>
                            @empty
                                <p class="text-text-muted">Nenhum projeto associado a este usuario.</p>
                            @endforelse
                        </div>
                    </section>

                    @if ($isAdmin)
                        <section id="administracao" class="space-y-md">
                            <div>
                                <h2 class="text-xl font-bold">Administracao</h2>
                                <p class="text-text-muted">Atalhos e leitura rapida para o perfil admin.</p>
                            </div>

                            <div class="grid grid-cols-1 md:grid-cols-2 gap-md">
                                <div class="bg-surface rounded-lg border border-stroke p-lg">
                                    <p class="text-text-muted text-sm font-bold">Usuarios</p>
                                    <p class="text-2xl font-bold mt-xs">{{ $adminOverview['usersCount'] }}</p>
                                </div>
                                <div class="bg-surface rounded-lg border border-stroke p-lg">
                                    <p class="text-text-muted text-sm font-bold">Perfis</p>
                                    <p class="text-2xl font-bold mt-xs">{{ $adminOverview['profilesCount'] }}</p>
                                </div>
                            </div>

                            <div class="grid grid-cols-1 xl:grid-cols-2 gap-md">
                                <div class="bg-surface rounded-lg border border-stroke">
                                    <div class="p-lg border-b border-stroke">
                                        <h3 class="font-bold">Usuarios recentes</h3>
                                    </div>
                                    <div class="divide-y divide-stroke">
                                        @foreach ($adminOverview['recentUsers'] as $adminUser)
                                            <div class="p-lg">
                                                <p class="font-bold">{{ $adminUser->full_name ?? $adminUser->email }}</p>
                                                <p class="text-sm text-text-muted">{{ $adminUser->email }} · {{ $adminUser->profile?->name }}</p>
                                            </div>
                                        @endforeach
                                    </div>
                                </div>

                                <div class="bg-surface rounded-lg border border-stroke">
                                    <div class="p-lg border-b border-stroke">
                                        <h3 class="font-bold">Perfis</h3>
                                    </div>
                                    <div class="divide-y divide-stroke">
                                        @foreach ($adminOverview['profiles'] as $profile)
                                            <div class="p-lg flex items-center justify-between gap-md">
                                                <div>
                                                    <p class="font-bold">{{ $profile->name }}</p>
                                                    <p class="text-sm text-text-muted">{{ $profile->code }}</p>
                                                </div>
                                                <span class="text-sm font-bold text-text-muted">{{ $profile->users_count }}</span>
                                            </div>
                                        @endforeach
                                    </div>
                                </div>
                            </div>
                        </section>
                    @endif
                </main>
            </div>
        </div>
    </div>
@endif
@endsection
