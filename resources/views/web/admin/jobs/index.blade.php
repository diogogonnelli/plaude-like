@extends('layouts.admin-shell')

@section('topbar-actions')
    <a class="button-secondary" href="{{ route('workspace.admin.recordings') }}">Gravacoes</a>
@endsection

@section('content')
    <section class="surface-panel">
        <div class="section-header">
            <div>
                <h2 class="section-title">Jobs operacionais</h2>
                <p class="section-copy">Monitoramento de provider, job id, timestamps, origem e erros do pipeline.</p>
            </div>
            <div class="section-actions">
                <a class="button-secondary" href="{{ route('workspace.admin.jobs') }}">Limpar</a>
            </div>
        </div>

        <form class="filters-grid" method="GET" action="{{ route('workspace.admin.jobs') }}">
            <div class="field-grid grow">
                <label for="jobs-query">Buscar</label>
                <input class="field-input" id="jobs-query" type="text" name="query" value="{{ $filters['query'] }}" placeholder="Titulo, job id ou erro">
            </div>
            <div class="field-grid">
                <label for="jobs-project-id">Projeto</label>
                <select class="field-select" id="jobs-project-id" name="project_id">
                    <option value="">Todos</option>
                    <option value="none" @selected($filters['project_id'] === 'none')>Sem projeto</option>
                    @foreach ($projects as $projectOption)
                        <option value="{{ $projectOption->id }}" @selected($filters['project_id'] === $projectOption->id)>{{ $projectOption->name }}</option>
                    @endforeach
                </select>
            </div>
            <div class="field-grid">
                <label for="jobs-status">Status</label>
                <select class="field-select" id="jobs-status" name="status">
                    <option value="">Todos</option>
                    <option value="processing_transcript" @selected($filters['status'] === 'processing_transcript')>Transcrevendo</option>
                    <option value="processing_summary" @selected($filters['status'] === 'processing_summary')>Resumindo</option>
                    <option value="indexing" @selected($filters['status'] === 'indexing')>Indexando</option>
                    <option value="ready" @selected($filters['status'] === 'ready')>Pronto</option>
                    <option value="failed" @selected($filters['status'] === 'failed')>Falhou</option>
                </select>
            </div>
            <div class="field-grid">
                <label for="jobs-user-id">Autor</label>
                <select class="field-select" id="jobs-user-id" name="user_id">
                    <option value="">Todos</option>
                    @foreach ($users as $userOption)
                        <option value="{{ $userOption->id }}" @selected($filters['user_id'] === $userOption->id)>
                            {{ $userOption->full_name ?? $userOption->email }}
                        </option>
                    @endforeach
                </select>
            </div>
            <div class="field-grid">
                <label for="jobs-source-app">App</label>
                <select class="field-select" id="jobs-source-app" name="source_app">
                    <option value="">Todos</option>
                    <option value="teams" @selected($filters['source_app'] === 'teams')>Teams</option>
                    <option value="zoom" @selected($filters['source_app'] === 'zoom')>Zoom</option>
                    <option value="meet" @selected($filters['source_app'] === 'meet')>Google Meet</option>
                    <option value="system_audio" @selected($filters['source_app'] === 'system_audio')>Audio do sistema</option>
                </select>
            </div>
            <div class="field-grid">
                <label for="jobs-platform">Plataforma</label>
                <select class="field-select" id="jobs-platform" name="platform">
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
        @if ($jobs->isEmpty())
            @include('web.partials.empty-state', [
                'title' => 'Nenhum job encontrado',
                'description' => 'Ajuste os filtros para localizar o processamento desejado.',
            ])
        @else
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Recording</th>
                            <th>Projeto</th>
                            <th>Status</th>
                            <th>Provider</th>
                            <th>Job ID</th>
                            <th>Atualizacao</th>
                            <th>Acoes</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($jobs as $job)
                            <tr>
                                <td>
                                    <div class="table-primary">{{ $job->title }}</div>
                                    <div class="table-secondary mono">{{ $job->id }}</div>
                                </td>
                                <td>{{ $job->project?->name ?? 'Sem projeto' }}</td>
                                <td>@include('web.partials.status-pill', ['status' => $job->status])</td>
                                <td>{{ $job->transcription_provider ?? 'Sem provider' }}</td>
                                <td class="mono">{{ $job->transcription_job_id ?? 'Sem job' }}</td>
                                <td>{{ optional($job->transcription_completed_at ?? $job->transcription_started_at ?? $job->updated_at)->format('d/m/Y H:i') ?? 'Sem data' }}</td>
                                <td>
                                    <a class="button-secondary" href="{{ route('workspace.admin.recordings.show', $job) }}">Detalhe</a>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </section>
@endsection
