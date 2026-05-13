@extends('layouts.admin-shell')

@section('topbar-actions')
    <a class="button-secondary" href="{{ route('workspace.home') }}">Workspace</a>
@endsection

@section('content')
    <div class="summary-grid">
        <article class="summary-card">
            <span class="eyebrow">Usuarios</span>
            <strong>{{ $stats['users'] }}</strong>
            <p class="muted-copy">Diretorio autenticado neste ambiente.</p>
        </article>
        <article class="summary-card">
            <span class="eyebrow">Projetos</span>
            <strong>{{ $stats['projects'] }}</strong>
            <p class="muted-copy">Carteira ativa e historica da operacao.</p>
        </article>
        <article class="summary-card">
            <span class="eyebrow">Gravacoes</span>
            <strong>{{ $stats['recordings'] }}</strong>
            <p class="muted-copy">{{ $stats['processing'] }} processando e {{ $stats['failed'] }} com falha.</p>
        </article>
    </div>

    <div class="admin-grid">
        <section class="surface-panel admin-card">
            <div class="section-header">
                <div>
                    <h2 class="section-title">Usuarios recentes</h2>
                    <p class="section-copy">Ultimos cadastros ou usuarios atualizados no workspace.</p>
                </div>
                <div class="section-actions">
                    <a class="button-secondary" href="{{ route('workspace.admin.users') }}">Ver usuarios</a>
                </div>
            </div>

            @if ($recentUsers->isEmpty())
                @include('web.partials.empty-state', [
                    'title' => 'Sem usuarios recentes',
                    'description' => 'Os proximos cadastros aparecerao aqui.',
                ])
            @else
                <div class="admin-list">
                    @foreach ($recentUsers as $recentUser)
                        <article class="admin-list-item">
                            <strong>{{ $recentUser->full_name ?? $recentUser->email }}</strong>
                            <span>{{ $recentUser->email }}</span>
                            <span>{{ $recentUser->profile?->name ?? 'Sem perfil' }}</span>
                        </article>
                    @endforeach
                </div>
            @endif
        </section>

        <section class="surface-panel admin-card">
            <div class="section-header">
                <div>
                    <h2 class="section-title">Gravacoes recentes</h2>
                    <p class="section-copy">Acompanhe rapidamente o estado operacional dos ultimos registros.</p>
                </div>
                <div class="section-actions">
                    <a class="button-secondary" href="{{ route('workspace.admin.recordings') }}">Abrir gravacoes</a>
                </div>
            </div>

            @if ($recentRecordings->isEmpty())
                @include('web.partials.empty-state', [
                    'title' => 'Sem gravacoes recentes',
                    'description' => 'A fila administrativa aparecera aqui assim que houver movimento.',
                ])
            @else
                <div class="admin-list">
                    @foreach ($recentRecordings as $recentRecording)
                        <article class="admin-list-item">
                            <strong>{{ $recentRecording->title }}</strong>
                            <span>{{ $recentRecording->project?->name ?? 'Sem projeto' }}</span>
                            <div class="form-actions">
                                @include('web.partials.status-pill', ['status' => $recentRecording->status])
                                <a class="button-secondary" href="{{ route('workspace.admin.recordings.show', $recentRecording) }}">Detalhe</a>
                            </div>
                        </article>
                    @endforeach
                </div>
            @endif
        </section>
    </div>
@endsection
