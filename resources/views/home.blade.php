@extends('layouts.base')

@php
    $isAuthenticated = $user !== null;
    $isAdmin = $isAuthenticated && $user->isAdmin();
    $brandName = config('app.name', 'Sonora');
    $selectedRecordingId = request()->query('recording');
    $queryState = [
        'tab' => $selectedTab ?? 'home',
        'recording' => $selectedRecordingId,
        'project' => $filters['project'] ?? 'all',
        'status' => $filters['status'] ?? 'all',
        'query' => $filters['query'] ?? '',
    ];
    $navLink = function (string $tab, array $overrides = []) use ($queryState) {
        return route('home', array_filter(array_merge($queryState, ['tab' => $tab], $overrides), fn ($value) => $value !== null && $value !== ''));
    };
    $statusTone = function (string $status): string {
        return match ($status) {
            'ready' => 'bg-emerald-100 text-emerald-700 border-emerald-200',
            'failed' => 'bg-rose-100 text-rose-700 border-rose-200',
            default => 'bg-amber-100 text-amber-700 border-amber-200',
        };
    };
@endphp

@section('body')
@if (! $isAuthenticated)
    <div class="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(222,12,47,0.14),_transparent_35%),linear-gradient(180deg,_#f8f9fb_0%,_#f1f5f9_100%)] px-lg py-xl">
        <div class="mx-auto flex min-h-[calc(100vh-48px)] max-w-6xl items-center justify-center">
            <div class="grid w-full gap-xl lg:grid-cols-[320px_minmax(0,560px)]">
                <aside class="rounded-[32px] border border-stroke bg-surface p-xl shadow-[0_24px_70px_rgba(31,37,44,0.08)]">
                    <div class="flex items-center gap-sm">
                        <span class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-accent text-lg font-black text-white">S</span>
                        <div>
                            <p class="font-display text-3xl font-black tracking-tight text-shell-dark">{{ $brandName }}</p>
                            <p class="text-sm text-text-muted">Shell operacional em uma unica pagina.</p>
                        </div>
                    </div>

                    <div class="mt-xl rounded-[28px] bg-surface-muted p-lg">
                        <p class="text-xs font-bold uppercase tracking-[0.18em] text-text-muted">Fluxo web</p>
                        <ul class="mt-md space-y-sm text-sm text-text">
                            <li>Inicio com acoes de captura e upload</li>
                            <li>Biblioteca com filtros, detalhe e chat</li>
                            <li>Sistema e administracao no mesmo shell</li>
                        </ul>
                    </div>
                </aside>

                <section class="rounded-[40px] border border-white/70 bg-white/95 p-xl shadow-[0_32px_90px_rgba(222,12,47,0.12)]">
                    <div class="max-w-md">
                        <p class="text-xs font-bold uppercase tracking-[0.24em] text-accent">Acesso</p>
                        <h1 class="mt-sm font-display text-4xl font-black tracking-tight text-shell-dark">Entrar no {{ $brandName }}</h1>
                        <p class="mt-sm text-base text-text-muted">Use suas credenciais para abrir o cockpit operacional sem sair da raiz do dominio.</p>
                    </div>

                    @if ($errors->any())
                        <div class="mt-lg rounded-[22px] border border-rose-200 bg-rose-50 px-lg py-md text-sm text-rose-700">
                            @foreach ($errors->all() as $error)
                                <p>{{ $error }}</p>
                            @endforeach
                        </div>
                    @endif

                    <form method="POST" action="{{ route('home.submit') }}" class="mt-xl space-y-md">
                        @csrf
                        <input type="hidden" name="intent" value="login">

                        <div>
                            <label for="email" class="mb-xs block text-sm font-bold text-text">E-mail</label>
                            <input
                                type="email"
                                name="email"
                                id="email"
                                value="{{ old('email') }}"
                                required
                                autofocus
                                class="w-full rounded-[20px] border border-stroke bg-surface px-md py-sm outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/20"
                            >
                        </div>

                        <div>
                            <label for="password" class="mb-xs block text-sm font-bold text-text">Senha</label>
                            <input
                                type="password"
                                name="password"
                                id="password"
                                required
                                class="w-full rounded-[20px] border border-stroke bg-surface px-md py-sm outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/20"
                            >
                        </div>

                        <button
                            type="submit"
                            class="inline-flex w-full items-center justify-center rounded-[999px] bg-accent px-lg py-sm font-bold text-white transition hover:bg-accent-soft"
                        >
                            Entrar
                        </button>
                    </form>
                </section>
            </div>
        </div>
    </div>
@else
    <div class="min-h-screen bg-[radial-gradient(circle_at_bottom_left,_rgba(222,12,47,0.10),_transparent_18%),radial-gradient(circle_at_bottom_right,_rgba(31,37,44,0.08),_transparent_20%),linear-gradient(180deg,_#f7f8fa_0%,_#eef2f7_100%)] text-text">
        <div class="mx-auto flex min-h-screen max-w-[1600px] gap-lg px-md py-md lg:px-lg lg:py-lg">
            <aside class="hidden w-[308px] shrink-0 rounded-[34px] border border-stroke bg-surface px-lg py-xl shadow-[0_30px_70px_rgba(31,37,44,0.08)] lg:flex lg:flex-col">
                <div>
                    <p class="font-display text-4xl font-black tracking-tight text-shell-dark">{{ $brandName }}</p>
                    <p class="mt-sm text-base text-text-muted">Operacao concentrada em captura, biblioteca e execucao.</p>
                </div>

                <div class="mt-lg rounded-[28px] border border-stroke bg-surface-muted p-lg">
                    <p class="text-xs font-bold uppercase tracking-[0.18em] text-text-muted">Projeto ativo</p>
                    <p class="mt-sm text-2xl font-bold text-shell-dark">{{ $activeProject?->name ?? 'Selecione um projeto' }}</p>
                </div>

                <nav class="mt-xl space-y-md">
                    <a href="{{ $navLink('library') }}" class="flex items-center gap-sm text-base font-bold {{ $selectedTab === 'library' ? 'text-accent' : 'text-text-muted' }}">
                        <span class="inline-flex h-11 w-11 items-center justify-center rounded-full {{ $selectedTab === 'library' ? 'bg-accent/12 text-accent' : 'bg-surface-muted text-shell' }}">
                            <span class="text-lg">L</span>
                        </span>
                        Biblioteca
                    </a>
                    <a href="{{ $navLink('home') }}" class="flex items-center gap-sm text-base font-bold {{ $selectedTab === 'home' ? 'text-accent' : 'text-text-muted' }}">
                        <span class="inline-flex h-11 w-11 items-center justify-center rounded-full {{ $selectedTab === 'home' ? 'bg-accent/12 text-accent' : 'bg-surface-muted text-shell' }}">
                            <span class="text-lg">I</span>
                        </span>
                        Inicio
                    </a>
                    <a href="{{ $navLink('system') }}" class="flex items-center gap-sm text-base font-bold {{ $selectedTab === 'system' ? 'text-accent' : 'text-text-muted' }}">
                        <span class="inline-flex h-11 w-11 items-center justify-center rounded-full {{ $selectedTab === 'system' ? 'bg-accent/12 text-accent' : 'bg-surface-muted text-shell' }}">
                            <span class="text-lg">S</span>
                        </span>
                        Sistema
                    </a>
                    @if ($isAdmin)
                        <a href="{{ $navLink('admin') }}" class="flex items-center gap-sm text-base font-bold {{ $selectedTab === 'admin' ? 'text-accent' : 'text-text-muted' }}">
                            <span class="inline-flex h-11 w-11 items-center justify-center rounded-full {{ $selectedTab === 'admin' ? 'bg-accent/12 text-accent' : 'bg-surface-muted text-shell' }}">
                                <span class="text-lg">A</span>
                            </span>
                            Administracao
                        </a>
                    @endif
                </nav>

                <div class="mt-auto pt-xl text-xs font-bold uppercase tracking-[0.18em] text-text-muted">SPOT endorsed workflow</div>
            </aside>

            <div class="min-w-0 flex-1">
                <header class="rounded-[34px] border border-accent/20 bg-white/90 px-lg py-md shadow-[0_24px_60px_rgba(222,12,47,0.08)]">
                    <div class="flex flex-col gap-md xl:flex-row xl:items-center xl:justify-between">
                        <div>
                            <p class="font-display text-4xl font-black tracking-tight text-shell-dark">{{ $brandName }}</p>
                            <p class="mt-xs text-sm text-text-muted">Mesma raiz, agora com shell de inicio, biblioteca, sistema e admin.</p>
                        </div>

                        <div class="flex flex-col gap-sm md:flex-row md:items-end">
                            <form method="POST" action="{{ route('home.submit') }}" class="min-w-[260px]">
                                @csrf
                                <input type="hidden" name="intent" value="select-active-project">
                                <input type="hidden" name="tab" value="{{ $selectedTab }}">
                                <label for="active-project-id" class="mb-xs block text-xs font-bold uppercase tracking-[0.18em] text-text-muted">Projeto para novas gravacoes</label>
                                <div class="flex gap-sm">
                                    <select id="active-project-id" name="project_id" onchange="this.form.submit()" class="w-full rounded-[22px] border border-accent bg-white px-md py-sm font-bold text-shell-dark outline-none">
                                        <option value="">Sem projeto</option>
                                        @foreach ($projects as $project)
                                            <option value="{{ $project->id }}" @selected($activeProject?->id === $project->id)>{{ $project->name }}</option>
                                        @endforeach
                                    </select>
                                </div>
                            </form>

                            <a href="{{ route('home', array_filter($queryState, fn ($value) => $value !== null && $value !== '')) }}" class="inline-flex items-center justify-center rounded-[999px] border border-stroke bg-surface px-lg py-sm font-bold text-shell-dark transition hover:border-shell hover:bg-surface-muted">
                                Atualizar
                            </a>
                        </div>
                    </div>
                </header>

                @if (session('status'))
                    <div class="mt-md rounded-[24px] border border-emerald-200 bg-emerald-50 px-lg py-md text-sm font-medium text-emerald-700">
                        {{ session('status') }}
                    </div>
                @endif

                @if ($errors->any())
                    <div class="mt-md rounded-[24px] border border-rose-200 bg-rose-50 px-lg py-md text-sm text-rose-700">
                        @foreach ($errors->all() as $error)
                            <p>{{ $error }}</p>
                        @endforeach
                    </div>
                @endif

                <main class="mt-md space-y-lg pb-xl">
                    @if ($selectedTab === 'home')
                        <section class="rounded-[40px] bg-[linear-gradient(110deg,_#4a4646_0%,_#6f6666_42%,_#de0c2f_100%)] p-xl text-white shadow-[0_32px_80px_rgba(222,12,47,0.24)]">
                            <div class="max-w-4xl">
                                <h1 class="font-display text-5xl font-black tracking-tight">Grave agora. Execute depois.</h1>
                                <p class="mt-md text-2xl font-bold">Projeto para novas gravacoes: {{ $activeProject?->name ?? 'Sem projeto' }}</p>
                                <p class="mt-sm max-w-3xl text-lg text-white/85">O {{ $brandName }} consolida audio, resumo estruturado, evidencias e contexto operacional dentro da mesma raiz web.</p>
                            </div>

                            <div class="mt-xl grid gap-md md:grid-cols-2">
                                <button
                                    type="button"
                                    class="inline-flex min-h-[60px] items-center justify-center rounded-[999px] bg-white px-lg py-md text-lg font-bold text-shell-dark shadow-sm"
                                    data-record-trigger
                                    data-record-label-start="Iniciar captacao"
                                    data-record-label-stop="Parar captacao"
                                >
                                    Iniciar captacao
                                </button>

                                <form method="POST" action="{{ route('home.submit') }}" enctype="multipart/form-data" class="contents" data-upload-form>
                                    @csrf
                                    <input type="hidden" name="intent" value="upload-audio">
                                    <input type="hidden" name="tab" value="library">
                                    <input type="hidden" name="source_type" value="upload">
                                    <input type="hidden" name="project_id" value="{{ $activeProject?->id }}">
                                    <input type="file" name="audio" accept="audio/*" class="hidden" data-audio-input>
                                    <input type="hidden" name="title" value="">
                                    <button type="button" class="inline-flex min-h-[60px] items-center justify-center rounded-[999px] border border-white/30 bg-transparent px-lg py-md text-lg font-bold text-white transition hover:bg-white/10" data-audio-upload-trigger>
                                        Enviar audio
                                    </button>
                                </form>
                            </div>

                            <form method="POST" action="{{ route('home.submit') }}" enctype="multipart/form-data" class="hidden" data-record-form>
                                @csrf
                                <input type="hidden" name="intent" value="upload-audio">
                                <input type="hidden" name="tab" value="library">
                                <input type="hidden" name="source_type" value="microphone">
                                <input type="hidden" name="project_id" value="{{ $activeProject?->id }}">
                                <input type="hidden" name="title" value="captacao-web-{{ now()->format('Ymd-His') }}">
                                <input type="file" name="audio" accept="audio/*" class="hidden" data-record-input>
                            </form>

                            <div class="mt-xl grid gap-md lg:grid-cols-3">
                                <div class="rounded-[24px] border border-white/12 bg-white/10 p-lg">
                                    <p class="text-sm font-bold uppercase tracking-[0.16em] text-white/70">Notas</p>
                                    <p class="mt-sm text-5xl font-black">{{ $summaryStats['total'] }}</p>
                                </div>
                                <div class="rounded-[24px] border border-white/12 bg-white/10 p-lg">
                                    <p class="text-sm font-bold uppercase tracking-[0.16em] text-white/70">Processando</p>
                                    <p class="mt-sm text-5xl font-black">{{ $summaryStats['processing'] }}</p>
                                </div>
                                <div class="rounded-[24px] border border-white/12 bg-white/10 p-lg">
                                    <p class="text-sm font-bold uppercase tracking-[0.16em] text-white/70">Falhas</p>
                                    <p class="mt-sm text-5xl font-black">{{ $summaryStats['failed'] }}</p>
                                </div>
                            </div>
                        </section>
                    @endif

                    @if ($selectedTab === 'library')
                        <section class="grid gap-lg xl:grid-cols-[minmax(0,1.3fr)_minmax(360px,0.9fr)]">
                            <div class="space-y-lg">
                                <section class="rounded-[32px] border border-stroke bg-surface p-lg shadow-[0_20px_60px_rgba(31,37,44,0.06)]">
                                    <div class="flex flex-col gap-md lg:flex-row lg:items-end lg:justify-between">
                                        <div>
                                            <p class="text-xs font-bold uppercase tracking-[0.2em] text-accent">Biblioteca</p>
                                            <h2 class="mt-xs font-display text-3xl font-black tracking-tight text-shell-dark">Pesquisa e triagem</h2>
                                            <p class="mt-sm text-text-muted">Busca, filtros por projeto e leitura operacional no mesmo shell.</p>
                                        </div>

                                        <form method="GET" action="{{ route('home') }}" class="grid gap-sm md:grid-cols-4">
                                            <input type="hidden" name="tab" value="library">
                                            <input type="text" name="query" value="{{ $filters['query'] }}" placeholder="Buscar por titulo ou resumo" class="min-w-[220px] rounded-[20px] border border-stroke px-md py-sm outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/20">
                                            <select name="project" class="rounded-[20px] border border-stroke px-md py-sm outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/20">
                                                <option value="all" @selected($filters['project'] === 'all')>Todos os projetos</option>
                                                <option value="none" @selected($filters['project'] === 'none')>Sem projeto</option>
                                                @foreach ($projects as $project)
                                                    <option value="{{ $project->id }}" @selected($filters['project'] === $project->id)>{{ $project->name }}</option>
                                                @endforeach
                                            </select>
                                            <select name="status" class="rounded-[20px] border border-stroke px-md py-sm outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/20">
                                                <option value="all" @selected($filters['status'] === 'all')>Todos os status</option>
                                                <option value="uploaded" @selected($filters['status'] === 'uploaded')>Enviado</option>
                                                <option value="processing_transcript" @selected($filters['status'] === 'processing_transcript')>Transcrevendo</option>
                                                <option value="processing_summary" @selected($filters['status'] === 'processing_summary')>Resumindo</option>
                                                <option value="ready" @selected($filters['status'] === 'ready')>Pronto</option>
                                                <option value="failed" @selected($filters['status'] === 'failed')>Falhou</option>
                                            </select>
                                            <button type="submit" class="rounded-[999px] bg-shell-dark px-lg py-sm font-bold text-white">Aplicar</button>
                                        </form>
                                    </div>
                                </section>

                                <div class="grid gap-sm md:grid-cols-3">
                                    <div class="rounded-[24px] border border-rose-100 bg-rose-50 p-md">
                                        <p class="text-xs font-bold uppercase tracking-[0.18em] text-accent">Processando</p>
                                        <p class="mt-sm text-3xl font-black text-shell-dark">{{ $recordingBuckets['processing']->count() }}</p>
                                    </div>
                                    <div class="rounded-[24px] border border-emerald-100 bg-emerald-50 p-md">
                                        <p class="text-xs font-bold uppercase tracking-[0.18em] text-emerald-700">Prontas</p>
                                        <p class="mt-sm text-3xl font-black text-shell-dark">{{ $recordingBuckets['ready']->count() }}</p>
                                    </div>
                                    <div class="rounded-[24px] border border-amber-100 bg-amber-50 p-md">
                                        <p class="text-xs font-bold uppercase tracking-[0.18em] text-amber-700">Falhas</p>
                                        <p class="mt-sm text-3xl font-black text-shell-dark">{{ $recordingBuckets['failed']->count() }}</p>
                                    </div>
                                </div>

                                @foreach (['processing' => 'Em andamento', 'ready' => 'Notas prontas', 'failed' => 'Falhas'] as $bucketKey => $bucketTitle)
                                    <section class="rounded-[32px] border border-stroke bg-surface p-lg shadow-[0_20px_60px_rgba(31,37,44,0.05)]">
                                        <div class="flex items-center justify-between gap-md">
                                            <div>
                                                <h3 class="text-2xl font-black text-shell-dark">{{ $bucketTitle }}</h3>
                                                <p class="mt-xs text-sm text-text-muted">Leitura densa da esteira para o filtro atual.</p>
                                            </div>
                                            <span class="rounded-[999px] bg-surface-muted px-md py-xs text-sm font-bold text-text-muted">{{ $recordingBuckets[$bucketKey]->count() }}</span>
                                        </div>

                                        <div class="mt-md space-y-sm">
                                            @forelse ($recordingBuckets[$bucketKey] as $recording)
                                                <a href="{{ $navLink('library', ['recording' => $recording->id]) }}" class="block rounded-[24px] border {{ $selectedRecording?->id === $recording->id ? 'border-accent bg-rose-50/40' : 'border-stroke bg-surface-muted' }} p-md transition hover:border-accent/50">
                                                    <div class="flex flex-col gap-sm lg:flex-row lg:items-start lg:justify-between">
                                                        <div class="min-w-0">
                                                            <p class="text-lg font-bold text-shell-dark">{{ $recording->title }}</p>
                                                            <p class="mt-xs line-clamp-2 text-sm text-text-muted">{{ $recording->summary?->overview ?? 'Aguardando transcript ou resumo.' }}</p>
                                                            <p class="mt-sm text-xs font-bold uppercase tracking-[0.18em] text-text-muted">
                                                                {{ $recording->created_at->format('d/m/Y H:i') }}
                                                                @if ($recording->project)
                                                                    | {{ $recording->project->name }}
                                                                @endif
                                                            </p>
                                                        </div>
                                                        <span class="inline-flex rounded-[999px] border px-sm py-xs text-xs font-bold uppercase tracking-[0.16em] {{ $statusTone($recording->status) }}">
                                                            {{ str_replace('_', ' ', $recording->status) }}
                                                        </span>
                                                    </div>
                                                </a>
                                            @empty
                                                <div class="rounded-[24px] border border-dashed border-stroke bg-surface-muted px-lg py-lg text-sm text-text-muted">
                                                    Nenhuma gravacao encontrada nesta coluna para o filtro atual.
                                                </div>
                                            @endforelse
                                        </div>
                                    </section>
                                @endforeach
                            </div>

                            <aside class="rounded-[32px] border border-stroke bg-surface p-lg shadow-[0_20px_60px_rgba(31,37,44,0.06)]">
                                @if ($selectedRecording)
                                    <div class="flex items-start justify-between gap-md">
                                        <div>
                                            <p class="text-xs font-bold uppercase tracking-[0.2em] text-accent">Detalhe</p>
                                            <h3 class="mt-xs font-display text-3xl font-black tracking-tight text-shell-dark">{{ $selectedRecording->title }}</h3>
                                        </div>
                                        <span class="inline-flex rounded-[999px] border px-sm py-xs text-xs font-bold uppercase tracking-[0.16em] {{ $statusTone($selectedRecording->status) }}">
                                            {{ str_replace('_', ' ', $selectedRecording->status) }}
                                        </span>
                                    </div>

                                    <div class="mt-lg rounded-[24px] bg-surface-muted p-md">
                                        <p class="text-xs font-bold uppercase tracking-[0.18em] text-text-muted">Resumo</p>
                                        <p class="mt-sm text-sm leading-7 text-text">{{ $selectedRecording->summary?->overview ?? 'A gravacao ainda nao possui resumo pronto.' }}</p>
                                    </div>

                                    <div class="mt-md grid gap-sm">
                                        <form method="POST" action="{{ route('home.submit') }}" class="grid gap-sm">
                                            @csrf
                                            <input type="hidden" name="intent" value="update-recording-project">
                                            <input type="hidden" name="tab" value="library">
                                            <input type="hidden" name="recording" value="{{ $selectedRecording->id }}">
                                            <input type="hidden" name="recording_id" value="{{ $selectedRecording->id }}">
                                            <label class="text-xs font-bold uppercase tracking-[0.18em] text-text-muted">Projeto da gravacao</label>
                                            <select name="project_id" onchange="this.form.submit()" class="rounded-[20px] border border-stroke px-md py-sm outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/20">
                                                <option value="">Sem projeto</option>
                                                @foreach ($projects as $project)
                                                    <option value="{{ $project->id }}" @selected($selectedRecording->project_id === $project->id)>{{ $project->name }}</option>
                                                @endforeach
                                            </select>
                                        </form>

                                        <form method="POST" action="{{ route('home.submit') }}">
                                            @csrf
                                            <input type="hidden" name="intent" value="reprocess-recording">
                                            <input type="hidden" name="tab" value="library">
                                            <input type="hidden" name="recording" value="{{ $selectedRecording->id }}">
                                            <input type="hidden" name="recording_id" value="{{ $selectedRecording->id }}">
                                            <button type="submit" class="w-full rounded-[999px] border border-stroke bg-white px-lg py-sm font-bold text-shell-dark transition hover:border-accent hover:text-accent">
                                                Reprocessar gravacao
                                            </button>
                                        </form>
                                    </div>

                                    <div class="mt-lg">
                                        <p class="text-xs font-bold uppercase tracking-[0.18em] text-text-muted">Highlights</p>
                                        <div class="mt-sm flex flex-wrap gap-sm">
                                            @forelse (($selectedRecording->noteArtifact?->highlights ?? []) as $highlight)
                                                <span class="rounded-[999px] bg-rose-50 px-sm py-xs text-sm font-medium text-shell-dark">{{ $highlight }}</span>
                                            @empty
                                                <p class="text-sm text-text-muted">Ainda sem highlights extraidos.</p>
                                            @endforelse
                                        </div>
                                    </div>

                                    <div class="mt-lg">
                                        <p class="text-xs font-bold uppercase tracking-[0.18em] text-text-muted">Transcricao</p>
                                        <div class="mt-sm max-h-64 space-y-sm overflow-auto rounded-[24px] bg-surface-muted p-md">
                                            @forelse ($selectedRecording->transcriptSegments as $segment)
                                                <div class="rounded-[18px] bg-white px-md py-sm shadow-sm">
                                                    <p class="text-xs font-bold uppercase tracking-[0.16em] text-text-muted">{{ $segment->speaker_label }}</p>
                                                    <p class="mt-xs text-sm leading-6 text-text">{{ $segment->text }}</p>
                                                </div>
                                            @empty
                                                <p class="text-sm text-text-muted">Nenhum segmento de transcricao disponivel.</p>
                                            @endforelse
                                        </div>
                                    </div>

                                    <div class="mt-lg">
                                        <p class="text-xs font-bold uppercase tracking-[0.18em] text-text-muted">Chat</p>
                                        <div class="mt-sm max-h-72 space-y-sm overflow-auto rounded-[24px] bg-surface-muted p-md">
                                            @forelse (($selectedRecording->chatSession?->messages ?? collect()) as $message)
                                                <div class="rounded-[20px] px-md py-sm {{ $message->role === 'assistant' ? 'bg-white' : 'bg-accent/8' }}">
                                                    <p class="text-xs font-bold uppercase tracking-[0.16em] text-text-muted">{{ $message->role }}</p>
                                                    <p class="mt-xs text-sm leading-6 text-text">{{ $message->content }}</p>
                                                </div>
                                            @empty
                                                <p class="text-sm text-text-muted">Sem mensagens ainda para esta gravacao.</p>
                                            @endforelse
                                        </div>

                                        <form method="POST" action="{{ route('home.submit') }}" class="mt-sm space-y-sm">
                                            @csrf
                                            <input type="hidden" name="intent" value="send-chat">
                                            <input type="hidden" name="tab" value="library">
                                            <input type="hidden" name="recording" value="{{ $selectedRecording->id }}">
                                            <input type="hidden" name="recording_id" value="{{ $selectedRecording->id }}">
                                            <textarea name="message" rows="4" class="w-full rounded-[22px] border border-stroke px-md py-sm outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/20" placeholder="Pergunte algo sobre esta gravacao"></textarea>
                                            <button type="submit" class="w-full rounded-[999px] bg-accent px-lg py-sm font-bold text-white transition hover:bg-accent-soft">
                                                Enviar para o chat
                                            </button>
                                        </form>
                                    </div>
                                @else
                                    <div class="flex h-full min-h-[540px] items-center justify-center rounded-[24px] border border-dashed border-stroke bg-surface-muted p-lg text-center text-text-muted">
                                        Selecione uma gravacao na biblioteca para abrir detalhe, transcript e chat no mesmo shell.
                                    </div>
                                @endif
                            </aside>
                        </section>
                    @endif

                    @if ($selectedTab === 'system')
                        <section class="grid gap-lg xl:grid-cols-[minmax(0,0.9fr)_minmax(0,1.1fr)]">
                            <section class="rounded-[32px] border border-stroke bg-surface p-lg shadow-[0_20px_60px_rgba(31,37,44,0.06)]">
                                <p class="text-xs font-bold uppercase tracking-[0.2em] text-accent">Sistema</p>
                                <h2 class="mt-xs font-display text-3xl font-black tracking-tight text-shell-dark">Sessao e ambiente</h2>

                                <div class="mt-lg space-y-md">
                                    <div class="rounded-[24px] bg-surface-muted p-md">
                                        <p class="text-xs font-bold uppercase tracking-[0.16em] text-text-muted">Usuario</p>
                                        <p class="mt-sm text-lg font-bold text-shell-dark">{{ $user->full_name ?? $user->email }}</p>
                                        <p class="text-sm text-text-muted">{{ $user->email }}</p>
                                    </div>

                                    <div class="rounded-[24px] bg-surface-muted p-md">
                                        <p class="text-xs font-bold uppercase tracking-[0.16em] text-text-muted">Projeto ativo</p>
                                        <p class="mt-sm text-lg font-bold text-shell-dark">{{ $activeProject?->name ?? 'Nenhum projeto selecionado' }}</p>
                                    </div>

                                    <form method="POST" action="{{ route('home.submit') }}">
                                        @csrf
                                        <input type="hidden" name="intent" value="logout">
                                        <button type="submit" class="w-full rounded-[999px] border border-stroke bg-white px-lg py-sm font-bold text-shell-dark transition hover:border-accent hover:text-accent">
                                            Encerrar sessao
                                        </button>
                                    </form>
                                </div>
                            </section>

                            <section class="rounded-[32px] border border-stroke bg-surface p-lg shadow-[0_20px_60px_rgba(31,37,44,0.06)]">
                                <p class="text-xs font-bold uppercase tracking-[0.2em] text-accent">Projetos</p>
                                <h2 class="mt-xs font-display text-3xl font-black tracking-tight text-shell-dark">Criar e organizar</h2>

                                <form method="POST" action="{{ route('home.submit') }}" class="mt-lg rounded-[28px] bg-surface-muted p-lg">
                                    @csrf
                                    <input type="hidden" name="intent" value="create-project">
                                    <input type="hidden" name="tab" value="system">
                                    <label for="project-name" class="mb-xs block text-sm font-bold text-text">Nome do projeto</label>
                                    <div class="flex flex-col gap-sm md:flex-row">
                                        <input id="project-name" type="text" name="name" class="min-w-0 flex-1 rounded-[20px] border border-stroke bg-white px-md py-sm outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/20" placeholder="Ex.: Projeto campanha abril">
                                        <button type="submit" class="rounded-[999px] bg-accent px-lg py-sm font-bold text-white transition hover:bg-accent-soft">
                                            Criar projeto
                                        </button>
                                    </div>
                                </form>

                                <div class="mt-lg space-y-sm">
                                    @forelse ($projects as $project)
                                        <div class="rounded-[24px] border border-stroke bg-surface-muted p-md">
                                            <div class="flex flex-col gap-sm md:flex-row md:items-center md:justify-between">
                                                <div>
                                                    <p class="text-lg font-bold text-shell-dark">{{ $project->name }}</p>
                                                    <p class="text-sm text-text-muted">{{ $project->slug }}</p>
                                                </div>
                                                <div class="flex items-center gap-sm">
                                                    <span class="rounded-[999px] bg-white px-sm py-xs text-xs font-bold uppercase tracking-[0.16em] text-text-muted">{{ $project->status }}</span>
                                                    <span class="rounded-[999px] bg-accent/10 px-sm py-xs text-xs font-bold uppercase tracking-[0.16em] text-accent">{{ $project->recordings_count }} notas</span>
                                                </div>
                                            </div>
                                        </div>
                                    @empty
                                        <div class="rounded-[24px] border border-dashed border-stroke bg-surface-muted px-lg py-lg text-sm text-text-muted">
                                            Nenhum projeto associado ao seu usuario.
                                        </div>
                                    @endforelse
                                </div>
                            </section>
                        </section>
                    @endif

                    @if ($selectedTab === 'admin' && $isAdmin)
                        <section class="space-y-lg">
                            <section class="rounded-[32px] border border-stroke bg-surface p-lg shadow-[0_20px_60px_rgba(31,37,44,0.06)]">
                                <p class="text-xs font-bold uppercase tracking-[0.2em] text-accent">Admin</p>
                                <h2 class="mt-xs font-display text-3xl font-black tracking-tight text-shell-dark">Administracao</h2>

                                <div class="mt-lg grid gap-md md:grid-cols-2">
                                    <div class="rounded-[24px] border border-stroke bg-surface-muted p-lg">
                                        <p class="text-xs font-bold uppercase tracking-[0.16em] text-text-muted">Usuarios</p>
                                        <p class="mt-sm text-4xl font-black text-shell-dark">{{ $adminOverview['usersCount'] }}</p>
                                    </div>
                                    <div class="rounded-[24px] border border-stroke bg-surface-muted p-lg">
                                        <p class="text-xs font-bold uppercase tracking-[0.16em] text-text-muted">Perfis</p>
                                        <p class="mt-sm text-4xl font-black text-shell-dark">{{ $adminOverview['profilesCount'] }}</p>
                                    </div>
                                </div>
                            </section>

                            <div class="grid gap-lg xl:grid-cols-2">
                                <section class="rounded-[32px] border border-stroke bg-surface p-lg shadow-[0_20px_60px_rgba(31,37,44,0.05)]">
                                    <h3 class="text-2xl font-black text-shell-dark">Usuarios recentes</h3>
                                    <div class="mt-md space-y-sm">
                                        @foreach ($adminOverview['recentUsers'] as $adminUser)
                                            <div class="rounded-[22px] bg-surface-muted p-md">
                                                <p class="font-bold text-shell-dark">{{ $adminUser->full_name ?? $adminUser->email }}</p>
                                                <p class="mt-xs text-sm text-text-muted">{{ $adminUser->email }} | {{ $adminUser->profile?->name }}</p>
                                            </div>
                                        @endforeach
                                    </div>
                                </section>

                                <section class="rounded-[32px] border border-stroke bg-surface p-lg shadow-[0_20px_60px_rgba(31,37,44,0.05)]">
                                    <h3 class="text-2xl font-black text-shell-dark">Perfis</h3>
                                    <div class="mt-md space-y-sm">
                                        @foreach ($adminOverview['profiles'] as $profile)
                                            <div class="rounded-[22px] bg-surface-muted p-md">
                                                <div class="flex items-center justify-between gap-sm">
                                                    <div>
                                                        <p class="font-bold text-shell-dark">{{ $profile->name }}</p>
                                                        <p class="mt-xs text-sm text-text-muted">{{ $profile->code }}</p>
                                                    </div>
                                                    <span class="rounded-[999px] bg-white px-sm py-xs text-xs font-bold uppercase tracking-[0.16em] text-text-muted">{{ $profile->users_count }} usuarios</span>
                                                </div>
                                            </div>
                                        @endforeach
                                    </div>
                                </section>
                            </div>
                        </section>
                    @endif
                </main>
            </div>
        </div>
    </div>
@endif
@endsection
