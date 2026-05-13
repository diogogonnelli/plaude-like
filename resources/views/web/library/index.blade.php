@extends('layouts.app-shell')

@section('topbar-actions')
    <a class="button-secondary" href="{{ route('workspace.home') }}">Home</a>
    <a class="button-secondary" href="{{ route('workspace.settings') }}">Settings</a>
@endsection

@section('content')
    <section class="surface-panel">
        <div class="section-header">
            <div>
                <h2 class="section-title">Pesquisa e triagem</h2>
                <p class="section-copy">Busque por titulo, resumo, nota ou transcript e refine a fila por projeto e status.</p>
            </div>
            <div class="section-actions">
                <a class="button-secondary" href="{{ route('workspace.library') }}">Limpar filtros</a>
            </div>
        </div>

        <form class="filters-grid" method="GET" action="{{ route('workspace.library') }}">
            <div class="field-grid grow">
                <label for="library-query">Buscar</label>
                <input class="field-input" id="library-query" type="text" name="query" value="{{ $filters['query'] }}" placeholder="Titulo, resumo ou transcript">
            </div>
            <div class="field-grid">
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
            <div class="field-grid">
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
            <div class="form-actions">
                <button class="button-primary" type="submit">Aplicar filtros</button>
            </div>
        </form>
    </section>

    <div class="summary-grid">
        <article class="summary-card">
            <span class="eyebrow">Processando</span>
            <strong>{{ $recordingBuckets['processing']->count() }}</strong>
            <p class="muted-copy">Itens ainda atravessando transcript, resumo ou indexacao.</p>
        </article>
        <article class="summary-card">
            <span class="eyebrow">Prontas</span>
            <strong>{{ $recordingBuckets['ready']->count() }}</strong>
            <p class="muted-copy">Notas aptas para leitura, exportacao e chat contextual.</p>
        </article>
        <article class="summary-card">
            <span class="eyebrow">Falhas</span>
            <strong>{{ $recordingBuckets['failed']->count() }}</strong>
            <p class="muted-copy">Itens com erro, acessiveis para diagnostico e retry.</p>
        </article>
    </div>

    <div class="library-columns">
        <section class="library-column">
            <div class="surface-panel">
                <div class="column-header">
                    <div>
                        <h2 class="section-title">Em andamento</h2>
                        <p class="section-copy">Fila que ainda exige processamento.</p>
                    </div>
                    <span class="count-pill">{{ $recordingBuckets['processing']->count() }}</span>
                </div>

                @if ($recordingBuckets['processing']->isEmpty())
                    @include('web.partials.empty-state', [
                        'title' => 'Nenhuma gravacao em andamento',
                        'description' => 'Os filtros atuais nao retornaram itens em processamento.',
                    ])
                @else
                    @foreach ($recordingBuckets['processing'] as $recording)
                        @include('web.partials.recording-card', ['recording' => $recording])
                    @endforeach
                @endif
            </div>
        </section>

        <section class="library-column">
            <div class="surface-panel">
                <div class="column-header">
                    <div>
                        <h2 class="section-title">Notas prontas</h2>
                        <p class="section-copy">Itens prontos para leitura, exportacao e chat.</p>
                    </div>
                    <span class="count-pill">{{ $recordingBuckets['ready']->count() }}</span>
                </div>

                @if ($recordingBuckets['ready']->isEmpty())
                    @include('web.partials.empty-state', [
                        'title' => 'Nenhuma nota pronta',
                        'description' => 'Assim que o pipeline concluir, as gravacoes aparecerao aqui.',
                    ])
                @else
                    @foreach ($recordingBuckets['ready'] as $recording)
                        @include('web.partials.recording-card', ['recording' => $recording])
                    @endforeach
                @endif
            </div>
        </section>

        <section class="library-column">
            <div class="surface-panel">
                <div class="column-header">
                    <div>
                        <h2 class="section-title">Falhas</h2>
                        <p class="section-copy">Itens disponiveis para retry e diagnostico.</p>
                    </div>
                    <span class="count-pill">{{ $recordingBuckets['failed']->count() }}</span>
                </div>

                @if ($recordingBuckets['failed']->isEmpty())
                    @include('web.partials.empty-state', [
                        'title' => 'Nenhuma falha nesta consulta',
                        'description' => 'Os filtros atuais nao encontraram gravacoes com erro.',
                    ])
                @else
                    @foreach ($recordingBuckets['failed'] as $recording)
                        @include('web.partials.recording-card', ['recording' => $recording])
                    @endforeach
                @endif
            </div>
        </section>
    </div>
@endsection
