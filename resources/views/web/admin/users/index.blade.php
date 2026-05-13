@extends('layouts.admin-shell')

@section('topbar-actions')
    <a class="button-secondary" href="{{ route('workspace.admin.dashboard') }}">Dashboard</a>
@endsection

@section('content')
    <div class="admin-grid">
        <section class="surface-panel admin-card">
            <div class="section-header">
                <div>
                    <h2 class="section-title">Diretorio de usuarios</h2>
                    <p class="section-copy">Filtro por busca, perfil e estado ativo para manter a operacao clara.</p>
                </div>
                <div class="section-actions">
                    <a class="button-secondary" href="{{ route('workspace.admin.users') }}">Limpar</a>
                </div>
            </div>

            <form class="filters-grid" method="GET" action="{{ route('workspace.admin.users') }}">
                <div class="field-grid grow">
                    <label for="users-query">Buscar</label>
                    <input class="field-input" id="users-query" type="text" name="query" value="{{ $filters['query'] }}" placeholder="Nome ou email">
                </div>
                <div class="field-grid">
                    <label for="users-profile-id">Perfil</label>
                    <select class="field-select" id="users-profile-id" name="profile_id">
                        <option value="">Todos</option>
                        @foreach ($profiles as $profileOption)
                            <option value="{{ $profileOption->id }}" @selected($filters['profile_id'] === $profileOption->id)>
                                {{ $profileOption->name }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div class="field-grid">
                    <label for="users-is-active">Status</label>
                    <select class="field-select" id="users-is-active" name="is_active">
                        <option value="">Todos</option>
                        <option value="1" @selected($filters['is_active'] === '1')>Ativos</option>
                        <option value="0" @selected($filters['is_active'] === '0')>Inativos</option>
                    </select>
                </div>
                <div class="form-actions">
                    <button class="button-primary" type="submit">Aplicar</button>
                </div>
            </form>

            @if ($users->isEmpty())
                @include('web.partials.empty-state', [
                    'title' => 'Nenhum usuario encontrado',
                    'description' => 'Ajuste os filtros ou crie um novo cadastro ao lado.',
                ])
            @else
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Pessoa</th>
                                <th>Perfil</th>
                                <th>Status</th>
                                <th>Atualizado</th>
                                <th>Acoes</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($users as $listedUser)
                                <tr>
                                    <td>
                                        <div class="table-primary">{{ $listedUser->full_name ?? $listedUser->email }}</div>
                                        <div class="table-secondary">{{ $listedUser->email }}</div>
                                    </td>
                                    <td>
                                        <div class="table-primary">{{ $listedUser->profile?->name ?? 'Sem perfil' }}</div>
                                        <div class="table-secondary">{{ $listedUser->profile?->code ?? 'sem-codigo' }}</div>
                                    </td>
                                    <td>
                                        @include('web.partials.status-pill', ['status' => $listedUser->is_active ? 'active' : 'inactive'])
                                    </td>
                                    <td>{{ optional($listedUser->updated_at)->format('d/m/Y H:i') ?? 'Sem data' }}</td>
                                    <td>
                                        <div class="form-actions">
                                            <a class="button-secondary" href="{{ route('workspace.admin.users', array_merge(request()->query(), ['edit' => $listedUser->id])) }}">Editar</a>
                                            <form method="POST" action="{{ route('workspace.admin.users.destroy', $listedUser) }}">
                                                @csrf
                                                @method('DELETE')
                                                <button class="button-danger" type="submit">Remover</button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </section>

        <section class="surface-panel admin-card">
            <div class="section-header">
                <div>
                    <h2 class="section-title">{{ $editingUser ? 'Editar usuario' : 'Novo usuario' }}</h2>
                    <p class="section-copy">Email, nome, perfil, senha e estado de ativacao.</p>
                </div>
                @if ($editingUser)
                    <div class="section-actions">
                        <a class="button-secondary" href="{{ route('workspace.admin.users', request()->except('edit')) }}">Novo cadastro</a>
                    </div>
                @endif
            </div>

            <form class="stack-form" method="POST" action="{{ $editingUser ? route('workspace.admin.users.update', $editingUser) : route('workspace.admin.users.store') }}">
                @csrf
                @if ($editingUser)
                    @method('PATCH')
                @endif

                <div class="field-grid">
                    <label for="user-email">Email</label>
                    <input class="field-input" id="user-email" type="email" name="email" value="{{ old('email', $editingUser->email ?? '') }}" required>
                </div>

                <div class="field-grid">
                    <label for="user-full-name">Nome completo</label>
                    <input class="field-input" id="user-full-name" type="text" name="full_name" value="{{ old('full_name', $editingUser->full_name ?? '') }}" required>
                </div>

                <div class="field-grid">
                    <label for="user-profile">Perfil</label>
                    <select class="field-select" id="user-profile" name="profile_id" required>
                        <option value="" disabled @selected(! old('profile_id', $editingUser->profile_id ?? ''))>Selecione</option>
                        @foreach ($profiles as $profileOption)
                            <option value="{{ $profileOption->id }}" @selected(old('profile_id', $editingUser->profile_id ?? '') === $profileOption->id)>
                                {{ $profileOption->name }}
                            </option>
                        @endforeach
                    </select>
                </div>

                <div class="field-grid">
                    <label for="user-password">{{ $editingUser ? 'Nova senha' : 'Senha' }}</label>
                    <input class="field-input" id="user-password" type="password" name="password" {{ $editingUser ? '' : 'required' }}>
                </div>

                <div class="field-grid">
                    <label for="user-status">Status</label>
                    <select class="field-select" id="user-status" name="is_active">
                        <option value="1" @selected((string) old('is_active', ($editingUser && ! $editingUser->is_active) ? '0' : '1') === '1')>Ativo</option>
                        <option value="0" @selected((string) old('is_active', ($editingUser && ! $editingUser->is_active) ? '0' : '1') === '0')>Inativo</option>
                    </select>
                </div>

                <div class="form-actions">
                    <button class="button-primary" type="submit">{{ $editingUser ? 'Salvar alteracoes' : 'Criar usuario' }}</button>
                </div>
            </form>
        </section>
    </div>
@endsection
