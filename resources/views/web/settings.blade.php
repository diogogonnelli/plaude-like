@extends('layouts.app-shell')

@section('topbar-actions')
    <a class="button-secondary" href="{{ route('workspace.home') }}">Home</a>
    <a class="button-secondary" href="{{ route('workspace.library') }}">Library</a>
    @if ($showAdminNav)
        <a class="button-secondary" href="{{ route('workspace.admin.dashboard') }}">Admin</a>
    @endif
@endsection

@section('content')
    <div class="split-grid">
        <section class="surface-panel">
            <h2 class="section-title">Sessao atual</h2>
            <div class="info-grid">
                <div class="info-card">
                    <span>Usuario</span>
                    <strong>{{ $user->full_name ?? 'Sem nome' }}</strong>
                </div>
                <div class="info-card">
                    <span>Email</span>
                    <strong>{{ $user->email }}</strong>
                </div>
                <div class="info-card">
                    <span>Perfil</span>
                    <strong>{{ $user->profile?->name ?? 'Sem perfil' }}</strong>
                </div>
                <div class="info-card">
                    <span>Admin</span>
                    <strong>{{ $showAdminNav ? 'Sim' : 'Nao' }}</strong>
                </div>
            </div>
        </section>

        <section class="surface-panel">
            <h2 class="section-title">Projeto ativo</h2>
            <form class="stack-form" method="POST" action="{{ route('workspace.projects.active') }}">
                @csrf
                <div class="field-grid">
                    <label for="settings-active-project">Projeto</label>
                    <select class="field-select" id="settings-active-project" name="project_id">
                        <option value="">Sem projeto</option>
                        @foreach ($projects as $projectOption)
                            <option value="{{ $projectOption->id }}" @selected(optional($activeProject)->id === $projectOption->id)>
                                {{ $projectOption->name }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div class="form-actions">
                    <button class="button-primary" type="submit">Salvar projeto ativo</button>
                </div>
            </form>

            <div class="detail-item">
                <span>Projeto selecionado</span>
                <strong>{{ $activeProject?->name ?? 'Sem projeto' }}</strong>
            </div>
        </section>
    </div>

    <div class="split-grid">
        <section class="surface-panel">
            <h2 class="section-title">Criar novo projeto</h2>
            <form class="stack-form" method="POST" action="{{ route('workspace.projects.store') }}">
                @csrf
                <div class="field-grid">
                    <label for="new-project-name">Nome do projeto</label>
                    <input class="field-input" id="new-project-name" type="text" name="name" placeholder="Ex.: Operacao Q2" required>
                </div>
                <div class="form-actions">
                    <button class="button-primary" type="submit">Criar projeto</button>
                </div>
            </form>
        </section>

        <section class="surface-panel">
            <h2 class="section-title">Projetos acessiveis</h2>
            @if ($projects->isEmpty())
                @include('web.partials.empty-state', [
                    'title' => 'Nenhum projeto disponivel',
                    'description' => 'Crie um projeto ou receba acesso para comecar a organizar novas gravacoes.',
                ])
            @else
                <div class="admin-list">
                    @foreach ($projects as $projectOption)
                        <article class="admin-list-item">
                            <strong>{{ $projectOption->name }}</strong>
                            <span>{{ $projectOption->recordings_count }} gravacoes vinculadas</span>
                            @include('web.partials.status-pill', ['status' => $projectOption->status])
                        </article>
                    @endforeach
                </div>
            @endif
        </section>
    </div>

    <section class="surface-panel">
        <div class="section-header">
            <div>
                <h2 class="section-title">Encerrar sessao</h2>
                <p class="section-copy">O logout usa a autenticacao Laravel atual e mantem a aplicacao principal no runtime unificado.</p>
            </div>
        </div>

        <form method="POST" action="{{ route('logout') }}">
            @csrf
            <button class="button-danger" type="submit">Sair agora</button>
        </form>
    </section>
@endsection
