@extends('layouts.admin-shell')

@php
    $chapters = $recording->summary?->chapters ?? [];
    $highlights = $recording->noteArtifact?->highlights ?? [];
    $actionItems = $recording->noteArtifact?->action_items ?? [];
    $messages = $recording->chatSession?->messages ?? collect();
    $captureMetadata = $recording->capture_metadata ?? [];
@endphp

@section('topbar-actions')
    <a class="button-secondary" href="{{ route('workspace.admin.recordings') }}">Voltar para gravacoes</a>
    <a class="button-secondary" href="{{ route('workspace.admin.jobs') }}">Jobs</a>
@endsection

@section('content')
    <section class="surface-panel">
        <div class="section-header">
            <div>
                <div class="eyebrow">Recording ID <span class="mono">{{ $recording->id }}</span></div>
                <h2 class="section-title">{{ $recording->title }}</h2>
                <p class="section-copy">Detalhe administrativo de transcript, sumario, notas, chat, provider e erro.</p>
            </div>
            <div class="section-actions">
                @include('web.partials.status-pill', ['status' => $recording->status])
            </div>
        </div>
    </section>

    <div class="detail-grid">
        <div class="detail-stack">
            <section class="surface-panel detail-block">
                <h2 class="section-title">Resumo</h2>
                @if ($recording->summary?->overview)
                    <div class="detail-item">
                        <span>Overview</span>
                        <strong>{{ $recording->summary->overview }}</strong>
                    </div>
                @else
                    @include('web.partials.empty-state', [
                        'title' => 'Resumo indisponivel',
                        'description' => 'Ainda nao existe overview estruturado para esta gravacao.',
                    ])
                @endif

                @if (! empty($chapters))
                    <div class="chapter-grid">
                        @foreach ($chapters as $chapter)
                            <article class="chapter-card">
                                <div class="eyebrow">Capitulo {{ $loop->iteration }}</div>
                                <h3 class="recording-card-title">{{ $chapter['heading'] ?? 'Capitulo' }}</h3>
                                <p class="recording-card-copy">{{ $chapter['body'] ?? '' }}</p>
                            </article>
                        @endforeach
                    </div>
                @endif
            </section>

            <div class="split-grid">
                <section class="surface-panel detail-block">
                    <h2 class="section-title">Highlights</h2>
                    @if (empty($highlights))
                        @include('web.partials.empty-state', [
                            'title' => 'Sem highlights',
                            'description' => 'Nenhum destaque estruturado disponivel.',
                        ])
                    @else
                        <ul class="list-plain">
                            @foreach ($highlights as $item)
                                <li>{{ $item }}</li>
                            @endforeach
                        </ul>
                    @endif
                </section>

                <section class="surface-panel detail-block">
                    <h2 class="section-title">Action items</h2>
                    @if (empty($actionItems))
                        @include('web.partials.empty-state', [
                            'title' => 'Sem action items',
                            'description' => 'Nenhuma acao estruturada foi detectada.',
                        ])
                    @else
                        <ul class="list-plain">
                            @foreach ($actionItems as $item)
                                <li>{{ $item }}</li>
                            @endforeach
                        </ul>
                    @endif
                </section>
            </div>

            <section class="surface-panel detail-block">
                <h2 class="section-title">Transcript</h2>
                @if ($recording->transcriptSegments->isEmpty())
                    @include('web.partials.empty-state', [
                        'title' => 'Transcript indisponivel',
                        'description' => 'Os segmentos ainda nao foram gerados.',
                    ])
                @else
                    <div class="transcript-stack">
                        @foreach ($recording->transcriptSegments as $segment)
                            <article class="transcript-card">
                                <div class="meta-row">
                                    <span class="meta-chip">{{ $segment->speaker_label }}</span>
                                    <span class="meta-chip">{{ \App\Modules\Recordings\Support\WebUi::formatTimestamp($segment->start_ms) }} - {{ \App\Modules\Recordings\Support\WebUi::formatTimestamp($segment->end_ms) }}</span>
                                </div>
                                <p class="recording-card-copy">{{ $segment->text }}</p>
                            </article>
                        @endforeach
                    </div>
                @endif
            </section>
        </div>

        <div class="detail-stack">
            <section class="surface-panel detail-block">
                <h2 class="section-title">Metadados operacionais</h2>
                <div class="info-grid">
                    <div class="info-card">
                        <span>Projeto</span>
                        <strong>{{ $recording->project?->name ?? 'Sem projeto' }}</strong>
                    </div>
                    <div class="info-card">
                        <span>Autor</span>
                        <strong>{{ $recording->createdByUser?->full_name ?? $recording->createdByUser?->email ?? 'Usuario' }}</strong>
                    </div>
                    <div class="info-card">
                        <span>Origem</span>
                        <strong>{{ \App\Modules\Recordings\Support\WebUi::recordingSourceDetail($recording) }}</strong>
                    </div>
                    <div class="info-card">
                        <span>Provider</span>
                        <strong>{{ $recording->transcription_provider ?? 'Sem provider' }}</strong>
                    </div>
                    <div class="info-card">
                        <span>Job ID</span>
                        <strong class="mono">{{ $recording->transcription_job_id ?? 'Sem job' }}</strong>
                    </div>
                    <div class="info-card">
                        <span>Inicio da transcricao</span>
                        <strong>{{ optional($recording->transcription_started_at)->format('d/m/Y H:i') ?? 'Sem inicio' }}</strong>
                    </div>
                    <div class="info-card">
                        <span>Conclusao</span>
                        <strong>{{ optional($recording->transcription_completed_at)->format('d/m/Y H:i') ?? 'Sem conclusao' }}</strong>
                    </div>
                    @if (data_get($captureMetadata, 'sourceApp'))
                        <div class="info-card">
                            <span>App</span>
                            <strong>{{ \App\Modules\Recordings\Support\WebUi::sourceAppLabel(data_get($captureMetadata, 'sourceApp')) }}</strong>
                        </div>
                    @endif
                    @if (data_get($captureMetadata, 'platform'))
                        <div class="info-card">
                            <span>Plataforma</span>
                            <strong>{{ \App\Modules\Recordings\Support\WebUi::platformLabel(data_get($captureMetadata, 'platform')) }}</strong>
                        </div>
                    @endif
                </div>
            </section>

            <section class="surface-panel detail-block">
                <h2 class="section-title">Atualizar projeto</h2>
                <form class="stack-form" method="POST" action="{{ route('workspace.admin.recordings.project', $recording) }}">
                    @csrf
                    <div class="field-grid">
                        <label for="admin-recording-project-id">Projeto</label>
                        <select class="field-select" id="admin-recording-project-id" name="project_id">
                            <option value="">Sem projeto</option>
                            @foreach ($projects as $projectOption)
                                <option value="{{ $projectOption->id }}" @selected(optional($recording->project)->id === $projectOption->id)>
                                    {{ $projectOption->name }}
                                </option>
                            @endforeach
                        </select>
                    </div>
                    <button class="button-primary" type="submit">Salvar vinculo</button>
                </form>
            </section>

            <section class="surface-panel detail-block">
                <h2 class="section-title">Acoes administrativas</h2>
                <div class="form-actions">
                    <a class="button-secondary" href="{{ route('workspace.admin.recordings.export', ['recording' => $recording, 'format' => 'txt']) }}">Exportar TXT</a>
                    <a class="button-secondary" href="{{ route('workspace.admin.recordings.export', ['recording' => $recording, 'format' => 'md']) }}">Exportar MD</a>
                </div>
                <form method="POST" action="{{ route('workspace.admin.recordings.reprocess', $recording) }}">
                    @csrf
                    <button class="button-danger" type="submit">Reprocessar gravacao</button>
                </form>
            </section>

            <section class="surface-panel detail-block">
                <h2 class="section-title">Chat armazenado</h2>
                @if ($messages->isEmpty())
                    @include('web.partials.empty-state', [
                        'title' => 'Sem mensagens',
                        'description' => 'O historico do chat desta gravacao ainda esta vazio.',
                    ])
                @else
                    <div class="admin-list">
                        @foreach ($messages as $message)
                            <article class="admin-list-item">
                                <strong>{{ $message->role === 'assistant' ? 'Assistente' : 'Usuario' }}</strong>
                                <span>{{ $message->content }}</span>
                            </article>
                        @endforeach
                    </div>
                @endif
            </section>

            @if ($recording->last_error)
                <section class="surface-panel detail-block">
                    <h2 class="section-title">Ultimo erro</h2>
                    <div class="detail-item">
                        <span>Erro</span>
                        <strong>{{ $recording->last_error }}</strong>
                    </div>
                </section>
            @endif
        </div>
    </div>
@endsection
