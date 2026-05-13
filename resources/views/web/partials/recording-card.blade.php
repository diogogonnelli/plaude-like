@php
    $summary = $recording->summary?->overview
        ?? $recording->noteArtifact?->title
        ?? 'Aguardando transcript ou resumo estruturado.';
@endphp

<a class="card-link" href="{{ route('workspace.recordings.show', $recording) }}">
    <article class="recording-card">
        <div class="recording-card-header">
            <div>
                <h3 class="recording-card-title">{{ $recording->title }}</h3>
                <p class="recording-card-copy">{{ $summary }}</p>
            </div>
            @include('web.partials.status-pill', ['status' => $recording->status])
        </div>

        <div class="meta-row">
            <span class="meta-chip">{{ $recording->project?->name ?? 'Sem projeto' }}</span>
            <span class="meta-chip">{{ \App\Modules\Recordings\Support\WebUi::recordingSourceDetail($recording) }}</span>
            <span class="meta-chip">{{ $recording->createdByUser?->full_name ?? $recording->createdByUser?->email ?? 'Usuario' }}</span>
            <span class="meta-chip">{{ optional($recording->created_at)->format('d/m/Y H:i') ?? 'Sem data' }}</span>
            @if ($recording->transcriptSegments->isNotEmpty())
                <span class="meta-chip">{{ $recording->transcriptSegments->count() }} segmentos</span>
            @endif
        </div>
    </article>
</a>
