@extends('layouts.app-shell')

@section('topbar-actions')
    <a class="button-secondary" href="{{ route('workspace.library') }}">Abrir library</a>
    <a class="button-secondary" href="{{ route('workspace.settings') }}">Settings</a>
    @if ($showAdminNav)
        <a class="button-secondary" href="{{ route('workspace.admin.dashboard') }}">Admin</a>
    @endif
@endsection

@section('content')
    <section class="hero-panel">
        <div class="hero-copy">
            <div class="shell-kicker">Comando central</div>
            <h2 class="page-title">Grave agora. Execute depois.</h2>
            <p class="page-copy">
                Projeto ativo para novas gravacoes: <strong>{{ $activeProject?->name ?? 'Sem projeto' }}</strong>.
                O frontend web consolida audio, resumo, transcript e operacao de chat em uma unica esteira.
            </p>
        </div>

        <div class="hero-actions">
            <a class="button" href="{{ route('workspace.library') }}">Ir para a library</a>
            <a class="button-ghost" href="{{ route('workspace.settings') }}">Organizar projetos</a>
        </div>

        <div class="metric-grid">
            <article class="metric-card">
                <div class="metric-label">Notas</div>
                <div class="metric-value">{{ $summaryStats['total'] }}</div>
            </article>
            <article class="metric-card">
                <div class="metric-label">Processando</div>
                <div class="metric-value">{{ $summaryStats['processing'] }}</div>
            </article>
            <article class="metric-card">
                <div class="metric-label">Falhas</div>
                <div class="metric-value">{{ $summaryStats['failed'] }}</div>
            </article>
        </div>
    </section>

    <div class="split-grid">
        <section class="surface-panel">
            <div class="section-header">
                <div>
                    <h2 class="section-title">Enviar audio</h2>
                    <p class="section-copy">Selecione um arquivo local e reuse o projeto ativo ou escolha outro projeto acessivel.</p>
                </div>
                <span class="surface-badge">
                    <span>Status</span>
                    <strong>{{ $summaryStats['ready'] }} prontas</strong>
                </span>
            </div>

            <form class="stack-form" method="POST" action="{{ route('workspace.recordings.upload') }}" enctype="multipart/form-data" data-upload-form>
                @csrf
                <input type="hidden" name="source_type" value="upload">
                <div class="field-grid">
                    <label for="upload-title">Titulo da gravacao</label>
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
                <div class="form-actions">
                    <button class="button-primary" type="button" data-audio-upload-trigger>Selecionar arquivo</button>
                    <span class="caption">Ao escolher o arquivo, o envio e o processamento sao iniciados automaticamente.</span>
                </div>
            </form>
        </section>

        <section class="surface-panel">
            <div class="section-header">
                <div>
                    <h2 class="section-title">Captacao por microfone</h2>
                    <p class="section-copy">Use o navegador para capturar audio em tempo real e enviar como uma nova gravacao.</p>
                </div>
            </div>

            <form class="stack-form" method="POST" action="{{ route('workspace.recordings.upload') }}" enctype="multipart/form-data" data-record-form>
                @csrf
                <input type="hidden" name="source_type" value="microphone">
                <div class="field-grid">
                    <label for="record-title">Titulo da captacao</label>
                    <input class="field-input" id="record-title" type="text" name="title" value="Captacao web {{ now()->format('d/m H:i') }}">
                </div>
                <div class="field-grid">
                    <label for="record-project-id">Projeto</label>
                    <select class="field-select" id="record-project-id" name="project_id">
                        <option value="">Sem projeto</option>
                        @foreach ($projects as $projectOption)
                            <option value="{{ $projectOption->id }}" @selected(optional($activeProject)->id === $projectOption->id)>
                                {{ $projectOption->name }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <input data-record-input type="file" name="audio" hidden>
                <div class="form-actions">
                    <button
                        class="button-primary"
                        type="button"
                        data-record-trigger
                        data-record-label-start="Iniciar captacao"
                        data-record-label-stop="Parar captacao"
                    >
                        Iniciar captacao
                    </button>
                    <span class="caption">Quando voce parar a captacao, o audio sera enviado automaticamente para processamento.</span>
                </div>
            </form>
        </section>
    </div>

    <div class="overview-grid">
        <article class="overview-card">
            <span class="eyebrow">Projeto ativo</span>
            <strong>{{ $activeProject?->name ?? 'Sem projeto' }}</strong>
            <p class="muted-copy">Troque o projeto a qualquer momento pelo seletor da barra lateral ou pela tela de settings.</p>
        </article>
        <article class="overview-card">
            <span class="eyebrow">Carteira</span>
            <strong>{{ $projects->count() }} projetos</strong>
            <p class="muted-copy">Cada novo audio pode herdar o projeto ativo ou ser enviado sem vinculo.</p>
        </article>
        <article class="overview-card">
            <span class="eyebrow">Admin</span>
            <strong>{{ $showAdminNav ? 'Disponivel' : 'Oculto' }}</strong>
            <p class="muted-copy">A navegacao administrativa e exibida apenas para usuarios com perfil admin.</p>
        </article>
    </div>
@endsection
