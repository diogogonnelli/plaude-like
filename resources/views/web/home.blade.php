@extends('layouts.app-shell', [
    'pageEyebrow' => 'Comando central',
    'pageTitle' => 'Grave agora. Execute depois.',
    'pageSubtitle' => 'Projeto ativo: ' . ($activeProject?->name ?? 'Sem projeto') . '. Audio, transcricao, resumo e operacao em uma esteira unica.',
])

@section('topbar-actions')
    <a class="btn-quiet" href="{{ route('workspace.library') }}">Library</a>
    <a class="btn-quiet" href="{{ route('workspace.settings') }}">Settings</a>
    @if ($showAdminNav)
        <a class="btn-quiet" href="{{ route('workspace.admin.dashboard') }}">Admin</a>
    @endif
@endsection

@section('content')
    <section class="hero">
        <span class="ring ring--lg" aria-hidden="true"></span>
        <div class="kicker-row" style="margin-bottom: var(--sp-2);"><span class="dot-live" aria-hidden="true"></span><span class="type-kicker">Ao vivo · pronto para captar</span></div>
        <p class="type-body" style="max-width: 64ch; color: var(--ink-mute); margin-top: var(--sp-3);">
            Inicie pela captacao via microfone, envie um arquivo local ou abra a library para revisar a fila.
        </p>
        <div style="display: flex; gap: var(--sp-3); margin-top: var(--sp-5); flex-wrap: wrap;">
            <a class="btn-primary" href="{{ route('workspace.library') }}">Abrir library</a>
            <a class="btn-ghost" href="{{ route('workspace.settings') }}">Organizar projetos</a>
        </div>
    </section>

    <div class="metric-row">
        <div class="metric-cell">
            <div class="metric-label">Notas</div>
            <div class="metric-value">{{ $summaryStats['total'] }}</div>
        </div>
        <div class="metric-cell">
            <div class="metric-label">Processando</div>
            <div class="metric-value">{{ $summaryStats['processing'] }}</div>
        </div>
        <div class="metric-cell">
            <div class="metric-label">Prontas</div>
            <div class="metric-value">{{ $summaryStats['ready'] }}</div>
        </div>
        <div class="metric-cell">
            <div class="metric-label">Falhas</div>
            <div class="metric-value">{{ $summaryStats['failed'] }}</div>
        </div>
    </div>

    <div class="split-grid">
        <section class="panel">
            <div class="kicker-row"><span class="dot"></span><span class="type-kicker">Enviar audio</span></div>
            <h2 class="type-section" style="margin: 0 0 var(--sp-4);">Carregue um arquivo local</h2>

            <form method="POST" action="{{ route('workspace.recordings.upload') }}" enctype="multipart/form-data" data-upload-form style="display: flex; flex-direction: column; gap: var(--sp-4);">
                @csrf
                <input type="hidden" name="source_type" value="upload">
                <div class="field-grid">
                    <label for="upload-title">Titulo</label>
                    <input class="field-input" id="upload-title" type="text" name="title" placeholder="Nome do audio ou reuniao">
                </div>
                <div class="field-grid">
                    <label for="upload-project-id">Projeto</label>
                    <select class="field-select" id="upload-project-id" name="project_id">
                        <option value="">Sem projeto</option>
                        @foreach ($projects as $projectOption)
                            <option value="{{ $projectOption->id }}" @selected(optional($activeProject)->id === $projectOption->id)>
                                {{ $projectOption->name }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <input data-audio-input type="file" name="audio" accept="audio/*" hidden>
                <div>
                    <button class="btn-primary" type="button" data-audio-upload-trigger>Selecionar arquivo</button>
                    <p class="type-meta" style="margin-top: var(--sp-3);">O envio inicia automaticamente apos a escolha.</p>
                </div>
            </form>
        </section>

        <section class="panel" style="display: flex; flex-direction: column; align-items: center; justify-content: center; gap: var(--sp-4); min-height: 320px;">
            <div class="kicker-row" style="align-self: flex-start; margin: 0;"><span class="dot"></span><span class="type-kicker">Captacao por microfone</span></div>

            <form method="POST" action="{{ route('workspace.recordings.upload') }}" enctype="multipart/form-data" data-record-form style="display: contents;">
                @csrf
                <input type="hidden" name="source_type" value="microphone">
                <input type="hidden" name="title" value="Captacao web {{ now()->format('d/m H:i') }}">
                <input type="hidden" name="project_id" value="{{ $activeProject?->id }}">
                <input data-record-input type="file" name="audio" hidden>
                <button
                    class="btn-mic"
                    type="button"
                    data-record-trigger
                    data-record-label-start="Iniciar"
                    data-record-label-stop="Parar"
                >
                    <span class="dot" aria-hidden="true"></span>
                    <span data-record-label>Iniciar</span>
                </button>
                <p class="type-meta" style="text-align: center; max-width: 32ch; margin: 0;">
                    Captacao via microfone enviada automaticamente ao parar.
                </p>
            </form>
        </section>
    </div>
@endsection
