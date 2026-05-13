@extends('layouts.app-shell')

@php
    $chapters = $recording->summary?->chapters ?? [];
    $highlights = $recording->noteArtifact?->highlights ?? [];
    $actionItems = $recording->noteArtifact?->action_items ?? [];
    $captureMetadata = $recording->capture_metadata ?? [];
@endphp

@section('topbar-actions')
    <a class="button-secondary" href="{{ route('workspace.library') }}">Voltar para a library</a>
    <a class="button-secondary" href="{{ route('workspace.recordings.chat', $recording) }}">Abrir chat</a>
    <a class="button-secondary" href="{{ route('workspace.recordings.export', ['recording' => $recording, 'format' => 'md']) }}">Exportar MD</a>
@endsection

@section('content')
    <section class="surface-panel">
        <div class="section-header">
            <div>
                <div class="eyebrow">Recording ID <span class="mono">{{ $recording->id }}</span></div>
                <h2 class="section-title">{{ $recording->title }}</h2>
                <p class="section-copy">{{ $recording->summary?->overview ?? 'Sem resumo estruturado ate o momento.' }}</p>
            </div>
            <div class="section-actions">
                @include('web.partials.status-pill', ['status' => $recording->status])
            </div>
        </div>
    </section>

    <div class="detail-grid">
        <div class="detail-stack">
            <section class="surface-panel detail-block">
                <div class="section-header">
                    <div>
                        <h2 class="section-title">Resumo executivo</h2>
                        <p class="section-copy">Leitura rapida da gravacao com capitulos e artefatos derivados.</p>
                    </div>
                </div>

                @if ($recording->summary?->overview)
                    <div class="detail-item">
                        <span>Overview</span>
                        <strong>{{ $recording->summary->overview }}</strong>
                    </div>
                @else
                    @include('web.partials.empty-state', [
                        'title' => 'Resumo indisponivel',
                        'description' => 'Esta gravacao ainda nao gerou overview estruturado.',
                    ])
                @endif

                @if (! empty($chapters))
                    <div class="chapter-grid">
                        @foreach ($chapters as $chapter)
                            <article class="chapter-card">
                                <div class="eyebrow">{{ $loop->iteration < 10 ? '0'.$loop->iteration : $loop->iteration }}</div>
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
                            'description' => 'Os destaques aparecem aqui quando o resumo estruturado estiver pronto.',
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
                            'description' => 'As acoes estruturadas aparecem aqui quando forem identificadas.',
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
                <div class="section-header">
                    <div>
                        <h2 class="section-title">Transcript</h2>
                        <p class="section-copy">Segmentos temporizados da gravacao atual.</p>
                    </div>
                </div>

                @if ($recording->transcriptSegments->isEmpty())
                    @include('web.partials.empty-state', [
                        'title' => 'Transcript indisponivel',
                        'description' => 'A transcricao ainda nao foi concluida para esta gravacao.',
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
            <section class="surface-panel">
                <h2 class="section-title">Metadados</h2>
                <div class="info-grid">
                    <div class="info-card">
                        <span>Projeto</span>
                        <strong>{{ $projectName }}</strong>
                    </div>
                    <div class="info-card">
                        <span>Autor</span>
                        <strong>{{ $authorName }}</strong>
                    </div>
                    <div class="info-card">
                        <span>Origem</span>
                        <strong>{{ $sourceLabel }}</strong>
                    </div>
                    <div class="info-card">
                        <span>Criada em</span>
                        <strong>{{ optional($recording->created_at)->format('d/m/Y H:i') ?? 'Sem data' }}</strong>
                    </div>
                    <div class="info-card">
                        <span>Provider</span>
                        <strong>{{ $recording->transcription_provider ?? 'Sem provider' }}</strong>
                    </div>
                    <div class="info-card">
                        <span>Job ID</span>
                        <strong class="mono">{{ $recording->transcription_job_id ?? 'Sem job' }}</strong>
                    </div>
                    @if (data_get($captureMetadata, 'platform'))
                        <div class="info-card">
                            <span>Plataforma</span>
                            <strong>{{ \App\Modules\Recordings\Support\WebUi::platformLabel(data_get($captureMetadata, 'platform')) }}</strong>
                        </div>
                    @endif
                    @if (data_get($captureMetadata, 'sourceApp'))
                        <div class="info-card">
                            <span>App de origem</span>
                            <strong>{{ \App\Modules\Recordings\Support\WebUi::sourceAppLabel(data_get($captureMetadata, 'sourceApp')) }}</strong>
                        </div>
                    @endif
                </div>
            </section>

            <section class="surface-panel detail-block">
                <h2 class="section-title">Projeto da gravacao</h2>
                <form class="stack-form" method="POST" action="{{ route('workspace.recordings.project', $recording) }}">
                    @csrf
                    <div class="field-grid">
                        <label for="recording-project-id">Projeto</label>
                        <select class="field-select" id="recording-project-id" name="project_id">
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
                <h2 class="section-title">Acoes</h2>
                <div class="form-actions">
                    <a class="button-secondary" href="{{ route('workspace.recordings.chat', $recording) }}">Abrir chat</a>
                    <a class="button-secondary" href="{{ route('workspace.recordings.export', ['recording' => $recording, 'format' => 'txt']) }}">Exportar TXT</a>
                    <a class="button-secondary" href="{{ route('workspace.recordings.export', ['recording' => $recording, 'format' => 'md']) }}">Exportar MD</a>
                </div>

                @if ($recording->audio_path)
                    <div class="audio-player">
                        <audio controls preload="none" src="{{ route('workspace.recordings.audio', $recording) }}"></audio>
                    </div>
                @endif

                <form method="POST" action="{{ route('workspace.recordings.reprocess', $recording) }}">
                    @csrf
                    <button class="button-danger" type="submit">Reprocessar gravacao</button>
                </form>
            </section>

            @if ($recording->last_error)
                <section class="surface-panel detail-block">
                    <h2 class="section-title">Ultimo erro</h2>
                    <div class="detail-item">
                        <span>Diagnostico</span>
                        <strong>{{ $recording->last_error }}</strong>
                    </div>
                </section>
            @endif
        </div>
    </div>
@endsection
