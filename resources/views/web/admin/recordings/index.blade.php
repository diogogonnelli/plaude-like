@extends('layouts.admin-shell')

@section('topbar-actions')
    <a class="button-secondary" href="{{ route('workspace.admin.jobs') }}">Jobs</a>
@endsection

@section('content')
    <section class="surface-panel">
        <div class="section-header">
            <div>
                <h2 class="section-title">Catalogo de gravacoes</h2>
                <p class="section-copy">Filtros reais por texto, projeto, autor, status, app e plataforma.</p>
            </div>
            <div class="section-actions">
                <a class="button-secondary" href="{{ route('workspace.admin.recordings') }}">Limpar</a>
            </div>
        </div>

        <form class="filters-grid" method="GET" action="{{ route('workspace.admin.recordings') }}">
            <div class="field-grid grow">
                <label for="recordings-query">Buscar</label>
                <input class="field-input" id="recordings-query" type="text" name="query" value="{{ $filters['query'] }}" placeholder="Titulo, resumo ou transcript">
            </div>
            <div class="field-grid">
                <label for="recordings-project">Projeto</label>
                <select class="field-select" id="recordings-project" name="project_id">
                    <option value="">Todos</option>
                    <option value="none" @selected($filters['project_id'] === 'none')>Sem projeto</option>
                    @foreach ($projects as $projectOption)
                        <option value="{{ $projectOption->id }}" @selected($filters['project_id'] === $projectOption->id)>{{ $projectOption->name }}</option>
                    @endforeach
                </select>
            </div>
            <div class="field-grid">
                <label for="recordings-status">Status</label>
                <select class="field-select" id="recordings-status" name="status">
                    <option value="">Todos</option>
                    <option value="uploaded" @selected($filters['status'] === 'uploaded')>Enviado</option>
                    <option value="processing_transcript" @selected($filters['status'] === 'processing_transcript')>Transcrevendo</option>
                    <option value="processing_summary" @selected($filters['status'] === 'processing_summary')>Resumindo</option>
                    <option value="indexing" @selected($filters['status'] === 'indexing')>Indexando</option>
                    <option value="ready" @selected($filters['status'] === 'ready')>Pronto</option>
                    <option value="failed" @selected($filters['status'] === 'failed')>Falhou</option>
                </select>
            </div>
            <div class="field-grid">
                <label for="recordings-user">Autor</label>
                <select class="field-select" id="recordings-user" name="user_id">
                    <option value="">Todos</option>
                    @foreach ($users as $userOption)
                        <option value="{{ $userOption->id }}" @selected($filters['user_id'] === $userOption->id)>
                            {{ $userOption->full_name ?? $userOption->email }}
                        </option>
                    @endforeach
                </select>
            </div>
            <div class="field-grid">
                <label for="recordings-source-app">App</label>
                <select class="field-select" id="recordings-source-app" name="source_app">
                    <option value="">Todos</option>
                    <option value="teams" @selected($filters['source_app'] === 'teams')>Teams</option>
                    <option value="zoom" @selected($filters['source_app'] === 'zoom')>Zoom</option>
                    <option value="meet" @selected($filters['source_app'] === 'meet')>Google Meet</option>
                    <option value="system_audio" @selected($filters['source_app'] === 'system_audio')>Audio do sistema</option>
                </select>
            </div>
            <div class="field-grid">
                <label for="recordings-platform">Plataforma</label>
                <select class="field-select" id="recordings-platform" name="platform">
                    <option value="">Todas</option>
                    <option value="windows" @selected($filters['platform'] === 'windows')>Windows</option>
                    <option value="macos" @selected($filters['platform'] === 'macos')>macOS</option>
                </select>
            </div>
            <div class="form-actions">
                <button class="button-primary" type="submit">Aplicar filtros</button>
            </div>
        </form>
    </section>

    <section class="surface-panel">
        @if ($recordings->isEmpty())
            @include('web.partials.empty-state', [
                'title' => 'Nenhuma gravacao encontrada',
                'description' => 'Ajuste os filtros para localizar o item desejado.',
            ])
        @else
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Titulo</th>
                            <th>Origem</th>
                            <th>Projeto</th>
                            <th>Status</th>
                            <th>Criada em</th>
                            <th>Acoes</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($recordings as $listedRecording)
                            <tr>
                                <td>
                                    <div class="table-primary">{{ $listedRecording->title }}</div>
                                    <div class="table-secondary">{{ $listedRecording->createdByUser?->full_name ?? $listedRecording->createdByUser?->email ?? 'Usuario' }}</div>
                                </td>
                                <td>{{ \App\Modules\Recordings\Support\WebUi::recordingSourceDetail($listedRecording) }}</td>
                                <td>{{ $listedRecording->project?->name ?? 'Sem projeto' }}</td>
                                <td>@include('web.partials.status-pill', ['status' => $listedRecording->status])</td>
                                <td>{{ optional($listedRecording->created_at)->format('d/m/Y H:i') ?? 'Sem data' }}</td>
                                <td>
                                    <div class="form-actions">
                                        <a class="button-secondary" href="{{ route('workspace.admin.recordings.show', $listedRecording) }}">Detalhe</a>
                                        <a class="button-secondary" href="{{ route('workspace.admin.recordings.export', ['recording' => $listedRecording, 'format' => 'md']) }}">Exportar</a>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </section>
@endsection
