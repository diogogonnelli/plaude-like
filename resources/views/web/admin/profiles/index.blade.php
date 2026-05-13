@extends('layouts.admin-shell')

@section('topbar-actions')
    <a class="button-secondary" href="{{ route('workspace.admin.dashboard') }}">Dashboard</a>
@endsection

@section('content')
    <div class="admin-grid">
        <section class="surface-panel admin-card">
            <div class="section-header">
                <div>
                    <h2 class="section-title">Perfis de acesso</h2>
                    <p class="section-copy">Codigos, nomes e descricoes dos papeis usados pelo workspace.</p>
                </div>
                <div class="section-actions">
                    <a class="button-secondary" href="{{ route('workspace.admin.profiles') }}">Limpar</a>
                </div>
            </div>

            @if ($profiles->isEmpty())
                @include('web.partials.empty-state', [
                    'title' => 'Nenhum perfil encontrado',
                    'description' => 'Crie um perfil administrativo ou operacional ao lado.',
                ])
            @else
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Perfil</th>
                                <th>Descricao</th>
                                <th>Usuarios</th>
                                <th>Sistema</th>
                                <th>Acoes</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($profiles as $listedProfile)
                                <tr>
                                    <td>
                                        <div class="table-primary">{{ $listedProfile->name }}</div>
                                        <div class="table-secondary mono">{{ $listedProfile->code }}</div>
                                    </td>
                                    <td>{{ $listedProfile->description ?? 'Sem descricao' }}</td>
                                    <td>{{ $listedProfile->users_count }}</td>
                                    <td>{{ $listedProfile->is_system ? 'Sim' : 'Nao' }}</td>
                                    <td>
                                        <div class="form-actions">
                                            <a class="button-secondary" href="{{ route('workspace.admin.profiles', ['edit' => $listedProfile->id]) }}">Editar</a>
                                            @unless ($listedProfile->is_system)
                                                <form method="POST" action="{{ route('workspace.admin.profiles.destroy', $listedProfile) }}">
                                                    @csrf
                                                    @method('DELETE')
                                                    <button class="button-danger" type="submit">Remover</button>
                                                </form>
                                            @endunless
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
                    <h2 class="section-title">{{ $editingProfile ? 'Editar perfil' : 'Novo perfil' }}</h2>
                    <p class="section-copy">Os codigos devem ficar em minusculas e com underscore.</p>
                </div>
                @if ($editingProfile)
                    <div class="section-actions">
                        <a class="button-secondary" href="{{ route('workspace.admin.profiles') }}">Novo perfil</a>
                    </div>
                @endif
            </div>

            <form class="stack-form" method="POST" action="{{ $editingProfile ? route('workspace.admin.profiles.update', $editingProfile) : route('workspace.admin.profiles.store') }}">
                @csrf
                @if ($editingProfile)
                    @method('PATCH')
                @endif

                @unless ($editingProfile)
                    <div class="field-grid">
                        <label for="profile-code">Codigo</label>
                        <input class="field-input" id="profile-code" type="text" name="code" value="{{ old('code') }}" placeholder="ex.: ops_manager" required>
                    </div>
                @else
                    <div class="detail-item">
                        <span>Codigo</span>
                        <strong class="mono">{{ $editingProfile->code }}</strong>
                    </div>
                @endunless

                <div class="field-grid">
                    <label for="profile-name">Nome</label>
                    <input class="field-input" id="profile-name" type="text" name="name" value="{{ old('name', $editingProfile->name ?? '') }}" required>
                </div>

                <div class="field-grid">
                    <label for="profile-description">Descricao</label>
                    <textarea class="field-textarea" id="profile-description" name="description">{{ old('description', $editingProfile->description ?? '') }}</textarea>
                </div>

                <div class="form-actions">
                    <button class="button-primary" type="submit">{{ $editingProfile ? 'Salvar alteracoes' : 'Criar perfil' }}</button>
                </div>
            </form>
        </section>
    </div>
@endsection
