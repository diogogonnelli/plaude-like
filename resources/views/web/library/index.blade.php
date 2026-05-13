@extends('layouts.app-shell', [
    'pageEyebrow' => 'Library',
    'pageTitle' => 'Indice de gravacoes',
    'pageSubtitle' => 'Pesquise, filtre e abra qualquer gravacao desta carteira.',
])

@php
    $statusMap = [
        'uploaded' => 'mute',
        'processing_transcript' => 'accent',
        'processing_summary' => 'accent',
        'indexing' => 'info',
        'ready' => 'positive',
        'failed' => 'warning',
    ];

    $all = collect()
        ->concat($recordingBuckets['processing'] ?? [])
        ->concat($recordingBuckets['ready'] ?? [])
        ->concat($recordingBuckets['failed'] ?? [])
        ->sortByDesc(fn ($r) => $r->created_at)
        ->values();

    $countProcessing = ($recordingBuckets['processing'] ?? collect())->count();
    $countReady = ($recordingBuckets['ready'] ?? collect())->count();
    $countFailed = ($recordingBuckets['failed'] ?? collect())->count();
@endphp

@section('content')
    <form method="GET" action="{{ route('workspace.library') }}" style="display: flex; gap: var(--sp-3); align-items: end; flex-wrap: wrap;">
        <div class="field-grid" style="flex: 1 1 280px;">
            <label for="library-query">Buscar</label>
            <input class="field-input" id="library-query" type="text" name="query" value="{{ $filters['query'] }}" placeholder="Titulo, resumo ou transcript">
        </div>
        <div class="field-grid" style="min-width: 180px;">
            <label for="library-project">Projeto</label>
            <select class="field-select" id="library-project" name="project">
                <option value="all" @selected($filters['project'] === 'all')>Todos</option>
                <option value="none" @selected($filters['project'] === 'none')>Sem projeto</option>
                @foreach ($projects as $projectOption)
                    <option value="{{ $projectOption->id }}" @selected($filters['project'] === $projectOption->id)>
                        {{ $projectOption->name }}
                    </option>
                @endforeach
            </select>
        </div>
        <div class="field-grid" style="min-width: 180px;">
            <label for="library-status">Status</label>
            <select class="field-select" id="library-status" name="status">
                <option value="all" @selected($filters['status'] === 'all')>Todos</option>
                <option value="uploaded" @selected($filters['status'] === 'uploaded')>Enviado</option>
                <option value="processing_transcript" @selected($filters['status'] === 'processing_transcript')>Transcrevendo</option>
                <option value="processing_summary" @selected($filters['status'] === 'processing_summary')>Resumindo</option>
                <option value="indexing" @selected($filters['status'] === 'indexing')>Indexando</option>
                <option value="ready" @selected($filters['status'] === 'ready')>Pronto</option>
                <option value="failed" @selected($filters['status'] === 'failed')>Falhou</option>
            </select>
        </div>
        <button class="btn-primary" type="submit">Aplicar</button>
        <a class="btn-quiet" href="{{ route('workspace.library') }}">Limpar</a>
    </form>

    <div class="metric-row">
        <div class="metric-cell">
            <div class="metric-label">Processando</div>
            <div class="metric-value">{{ $countProcessing }}</div>
        </div>
        <div class="metric-cell">
            <div class="metric-label">Prontas</div>
            <div class="metric-value">{{ $countReady }}</div>
        </div>
        <div class="metric-cell">
            <div class="metric-label">Falhas</div>
            <div class="metric-value">{{ $countFailed }}</div>
        </div>
    </div>

    @if ($all->isEmpty())
        @include('web.partials.empty-state', [
            'eyebrow' => 'Sem registros',
            'title' => 'Nenhuma gravacao para os filtros atuais.',
            'description' => 'Limpe os filtros ou inicie pela home enviando um audio ou capturando pelo microfone.',
        ])
    @else
        <ul class="index-list">
            @foreach ($all as $recording)
                @php
                    $statusToken = $statusMap[$recording->status] ?? 'mute';
                    $duration = $recording->duration_ms ? gmdate('i:s', intdiv($recording->duration_ms, 1000)) : null;
                @endphp
                <li class="index-item">
                    <span class="index-num">{{ str_pad($loop->iteration, 2, '0', STR_PAD_LEFT) }}</span>
                    <div>
                        <a class="index-title" href="{{ route('workspace.recordings.show', $recording) }}">{{ $recording->title ?: 'Gravacao sem titulo' }}</a>
                        <div class="index-meta">
                            <span>{{ $recording->project?->name ?? 'Sem projeto' }}</span>
                            <span>{{ optional($recording->created_at)->format('d/m/Y H:i') }}</span>
                            @if ($duration)
                                <span class="type-mono">{{ $duration }}</span>
                            @endif
                        </div>
                    </div>
                    <span class="index-status">
                        <span class="dot-status dot-status--{{ $statusToken }}"></span>
                        {{ str_replace('_', ' ', $recording->status) }}
                    </span>
                </li>
            @endforeach
        </ul>
    @endif
@endsection
