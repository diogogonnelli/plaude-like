@extends('layouts.app-shell', [
    'pageEyebrow' => $recording->project?->name ?? 'Gravacao',
    'pageTitle' => $recording->title ?: 'Gravacao sem titulo',
    'pageSubtitle' => optional($recording->created_at)->format('d/m/Y H:i'),
])

@php
    $chapters = $recording->summary?->chapters ?? [];
    $highlights = $recording->noteArtifact?->highlights ?? [];
    $actionItems = $recording->noteArtifact?->action_items ?? [];
    $captureMetadata = $recording->capture_metadata ?? [];
@endphp

@section('topbar-actions')
    <a class="btn-quiet" href="{{ route('workspace.library') }}">&larr; Library</a>
    <a class="btn-ghost" href="{{ route('workspace.recordings.chat', $recording) }}">Abrir chat</a>
@endsection

@section('content')
    <div class="detail-grid">
        <div class="detail-stack">
            <div class="kicker-row" style="margin: 0;">
                <span class="dot-status dot-status--{{ ['ready'=>'positive','failed'=>'warning','processing_transcript'=>'accent','processing_summary'=>'accent','indexing'=>'info'][$recording->status] ?? 'mute' }}"></span>
                <span class="type-kicker">{{ str_replace('_', ' ', $recording->status) }}</span>
                @if ($recording->id)
                    <span class="type-mono" style="margin-left: var(--sp-3); color: var(--ink-mute); font-size: 0.75rem;">ID {{ $recording->id }}</span>
                @endif
            </div>

            <div class="waveform" aria-hidden="true"></div>
            @if ($recording->audio_path)
                <audio controls preload="none" src="{{ route('workspace.recordings.audio', $recording) }}"></audio>
            @endif

            <div class="tabs" role="tablist">
                <button class="tab is-active" data-tab="resumo" type="button"><span class="dot"></span> Resumo</button>
                <button class="tab" data-tab="capitulos" type="button">Capitulos</button>
                <button class="tab" data-tab="highlights" type="button">Highlights</button>
                <button class="tab" data-tab="acoes" type="button">Acoes</button>
                <button class="tab" data-tab="transcript" type="button">Transcript</button>
            </div>

            <div class="tab-panel" data-panel="resumo">
                @if ($recording->summary?->overview)
                    <p class="type-body" style="line-height: 1.75; max-width: 65ch;">{{ $recording->summary->overview }}</p>
                @else
                    <p class="type-meta">Resumo indisponivel ate o momento.</p>
                @endif
            </div>

            <div class="tab-panel" data-panel="capitulos" hidden>
                @forelse ($chapters as $chapter)
                    <div style="padding: var(--sp-4) 0; border-bottom: 1px solid var(--ink-line-soft);">
                        <span class="type-mono" style="color: var(--ink-mute);">{{ str_pad($loop->iteration, 2, '0', STR_PAD_LEFT) }}</span>
                        <h3 class="type-section" style="margin: 4px 0;">{{ $chapter['heading'] ?? 'Capitulo' }}</h3>
                        <p class="type-meta" style="margin: 0;">{{ $chapter['body'] ?? '' }}</p>
                    </div>
                @empty
                    <p class="type-meta">Capitulos nao gerados.</p>
                @endforelse
            </div>

            <div class="tab-panel" data-panel="highlights" hidden>
                @if (empty($highlights))
                    <p class="type-meta">Sem highlights estruturados.</p>
                @else
                    <ul style="list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: var(--sp-3);">
                        @foreach ($highlights as $item)
                            <li style="display: flex; gap: var(--sp-3); align-items: flex-start;">
                                <span class="dot" style="margin-top: 8px;"></span>
                                <span>{{ $item }}</span>
                            </li>
                        @endforeach
                    </ul>
                @endif
            </div>

            <div class="tab-panel" data-panel="acoes" hidden>
                @if (empty($actionItems))
                    <p class="type-meta">Sem action items.</p>
                @else
                    <ul style="list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: var(--sp-3);">
                        @foreach ($actionItems as $item)
                            <li style="display: flex; gap: var(--sp-3); align-items: flex-start;">
                                <span class="dot-status dot-status--accent" style="margin-top: 8px;"></span>
                                <span>{{ $item }}</span>
                            </li>
                        @endforeach
                    </ul>
                @endif
            </div>

            <div class="tab-panel" data-panel="transcript" hidden>
                @if ($recording->transcriptSegments->isEmpty())
                    <p class="type-meta">Transcricao indisponivel.</p>
                @else
                    <div style="display: flex; flex-direction: column; gap: var(--sp-4);">
                        @foreach ($recording->transcriptSegments as $segment)
                            <article>
                                <div class="kicker-row" style="margin: 0 0 var(--sp-2);">
                                    <span class="type-mono" style="color: var(--ink-mute); font-size: 0.75rem;">{{ \App\Modules\Recordings\Support\WebUi::formatTimestamp($segment->start_ms) }} - {{ \App\Modules\Recordings\Support\WebUi::formatTimestamp($segment->end_ms) }}</span>
                                    <span class="type-kicker">{{ $segment->speaker_label }}</span>
                                </div>
                                <p class="type-body" style="margin: 0; line-height: 1.65;">{{ $segment->text }}</p>
                            </article>
                        @endforeach
                    </div>
                @endif
            </div>
        </div>

        <aside>
            <div class="meta-stack">
                <div>
                    <span>Projeto</span>
                    <strong>{{ $projectName }}</strong>
                </div>
                <div>
                    <span>Autor</span>
                    <strong>{{ $authorName }}</strong>
                </div>
                <div>
                    <span>Origem</span>
                    <strong>{{ $sourceLabel }}</strong>
                </div>
                <div>
                    <span>Duracao</span>
                    <strong>{{ $recording->duration_ms ? gmdate('i:s', intdiv($recording->duration_ms, 1000)) : '—' }}</strong>
                </div>
                <div>
                    <span>Provider</span>
                    <strong>{{ $recording->transcription_provider ?? 'Sem provider' }}</strong>
                </div>
                <div>
                    <span>Job ID</span>
                    <strong class="type-mono" style="font-size: 0.8rem;">{{ $recording->transcription_job_id ?? 'Sem job' }}</strong>
                </div>
                @if (data_get($captureMetadata, 'platform'))
                    <div>
                        <span>Plataforma</span>
                        <strong>{{ \App\Modules\Recordings\Support\WebUi::platformLabel(data_get($captureMetadata, 'platform')) }}</strong>
                    </div>
                @endif
                @if ($recording->last_error)
                    <div>
                        <span style="color: var(--warning);">Ultimo erro</span>
                        <strong style="font-size: 0.875rem; color: var(--warning);">{{ $recording->last_error }}</strong>
                    </div>
                @endif
            </div>

            <form method="POST" action="{{ route('workspace.recordings.project', $recording) }}" style="margin-top: var(--sp-6);">
                @csrf
                <div class="field-grid">
                    <label for="recording-project-id">Reatribuir projeto</label>
                    <select class="field-select" id="recording-project-id" name="project_id">
                        <option value="">Sem projeto</option>
                        @foreach ($projects as $projectOption)
                            <option value="{{ $projectOption->id }}" @selected(optional($recording->project)->id === $projectOption->id)>
                                {{ $projectOption->name }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <button class="btn-ghost btn-wide" type="submit" style="margin-top: var(--sp-3);">Salvar vinculo</button>
            </form>

            <div style="display: flex; flex-direction: column; gap: var(--sp-3); margin-top: var(--sp-5);">
                <a class="btn-ghost" href="{{ route('workspace.recordings.export', ['recording' => $recording, 'format' => 'md']) }}">Exportar MD</a>
                <a class="btn-quiet" href="{{ route('workspace.recordings.export', ['recording' => $recording, 'format' => 'txt']) }}">Exportar TXT</a>
                <form method="POST" action="{{ route('workspace.recordings.reprocess', $recording) }}">
                    @csrf
                    <button class="btn-quiet" type="submit" style="color: var(--warning);">Reprocessar gravacao</button>
                </form>
            </div>
        </aside>
    </div>

    <script>
        (function () {
            var buttons = document.querySelectorAll('.tab[data-tab]');
            var panels = document.querySelectorAll('.tab-panel[data-panel]');
            buttons.forEach(function (btn) {
                btn.addEventListener('click', function () {
                    var target = btn.getAttribute('data-tab');
                    buttons.forEach(function (b) { b.classList.toggle('is-active', b === btn); });
                    panels.forEach(function (p) { p.hidden = p.getAttribute('data-panel') !== target; });
                });
            });
        })();
    </script>
@endsection
