@extends('layouts.admin-shell')

@section('topbar-actions')
    <a class="button-secondary" href="{{ route('workspace.admin.projects') }}">Voltar para projetos</a>
@endsection

@section('content')
    <section class="surface-panel">
        <div class="section-header">
            <div>
                <div class="eyebrow">Projeto <span class="mono">{{ $project->id }}</span></div>
                <h2 class="section-title">{{ $project->name }}</h2>
                <p class="section-copy">Gerencie acessos diretos ao projeto e a role de cada membro.</p>
            </div>
            <div class="section-actions">
                @include('web.partials.status-pill', ['status' => $project->status])
            </div>
        </div>

        <div class="summary-grid">
            <article class="summary-card">
                <span class="eyebrow">Membros</span>
                <strong>{{ $project->members_count }}</strong>
                <p class="muted-copy">Vinculos diretos no projeto atual.</p>
            </article>
            <article class="summary-card">
                <span class="eyebrow">Gravacoes</span>
                <strong>{{ $project->recordings_count }}</strong>
                <p class="muted-copy">Historico de gravacoes associadas.</p>
            </article>
            <article class="summary-card">
                <span class="eyebrow">Slug</span>
                <strong class="mono">{{ $project->slug }}</strong>
                <p class="muted-copy">Identificador estavel do projeto.</p>
            </article>
        </div>
    </section>

    <div class="admin-grid">
        <section class="surface-panel admin-card">
            <h2 class="section-title">Membros atuais</h2>

            @if ($members->isEmpty())
                @include('web.partials.empty-state', [
                    'title' => 'Sem membros vinculados',
                    'description' => 'Adicione usuarios para compartilhar este projeto.',
                ])
            @else
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Pessoa</th>
                                <th>Perfil</th>
                                <th>Role</th>
                                <th>Desde</th>
                                <th>Acoes</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($members as $member)
                                <tr>
                                    <td>
                                        <div class="table-primary">{{ $member->user?->full_name ?? $member->user?->email ?? $member->user_id }}</div>
                                        <div class="table-secondary">{{ $member->user?->email ?? $member->user_id }}</div>
                                    </td>
                                    <td>{{ $member->user?->profile?->name ?? 'Sem perfil' }}</td>
                                    <td>@include('web.partials.status-pill', ['status' => $member->role])</td>
                                    <td>{{ optional($member->created_at)->format('d/m/Y H:i') ?? 'Sem data' }}</td>
                                    <td>
                                        <form method="POST" action="{{ route('workspace.admin.projects.members.destroy', ['project' => $project, 'user' => $member->user_id]) }}">
                                            @csrf
                                            @method('DELETE')
                                            <button class="button-danger" type="submit">Remover</button>
                                        </form>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </section>

        <section class="surface-panel admin-card">
            <h2 class="section-title">Adicionar ou atualizar membro</h2>
            <form class="stack-form" method="POST" action="{{ route('workspace.admin.projects.members.store', $project) }}">
                @csrf
                <div class="field-grid">
                    <label for="member-user-id">Usuario</label>
                    <select class="field-select" id="member-user-id" name="user_id" required>
                        <option value="" disabled selected>Selecione um usuario</option>
                        @foreach ($users as $userOption)
                            <option value="{{ $userOption->id }}">{{ $userOption->full_name ?? $userOption->email }} - {{ $userOption->profile?->name ?? 'Sem perfil' }}</option>
                        @endforeach
                    </select>
                </div>

                <div class="field-grid">
                    <label for="member-role">Role</label>
                    <select class="field-select" id="member-role" name="role" required>
                        <option value="owner">Owner</option>
                        <option value="member">Member</option>
                    </select>
                </div>

                <div class="form-actions">
                    <button class="button-primary" type="submit">Salvar membro</button>
                </div>
            </form>
        </section>
    </div>
@endsection
