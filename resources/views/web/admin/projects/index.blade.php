@extends('layouts.admin-shell')

@section('topbar-actions')
    <a class="button-secondary" href="{{ route('workspace.admin.dashboard') }}">Dashboard</a>
@endsection

@section('content')
    <div class="admin-grid">
        <section class="surface-panel admin-card">
            <div class="section-header">
                <div>
                    <h2 class="section-title">Projetos</h2>
                    <p class="section-copy">Lista, criacao, edicao e salto rapido para o gerenciamento de membros.</p>
                </div>
                <div class="section-actions">
                    <a class="button-secondary" href="{{ route('workspace.admin.projects') }}">Limpar</a>
                </div>
            </div>

            <form class="filters-grid" method="GET" action="{{ route('workspace.admin.projects') }}">
                <div class="field-grid grow">
                    <label for="projects-query">Buscar</label>
                    <input class="field-input" id="projects-query" type="text" name="query" value="{{ $filters['query'] }}" placeholder="Nome ou slug">
                </div>
                <div class="field-grid">
                    <label for="projects-status">Status</label>
                    <select class="field-select" id="projects-status" name="status">
                        <option value="">Todos</option>
                        <option value="active" @selected($filters['status'] === 'active')>Ativo</option>
                        <option value="archived" @selected($filters['status'] === 'archived')>Arquivado</option>
                    </select>
                </div>
                <div class="form-actions">
                    <button class="button-primary" type="submit">Aplicar</button>
                </div>
            </form>

            @if ($projects->isEmpty())
                @include('web.partials.empty-state', [
                    'title' => 'Nenhum projeto encontrado',
                    'description' => 'Use o formulario lateral para criar um novo projeto.',
                ])
            @else
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Projeto</th>
                                <th>Slug</th>
                                <th>Membros</th>
                                <th>Gravacoes</th>
                                <th>Status</th>
                                <th>Acoes</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($projects as $listedProject)
                                <tr>
                                    <td class="table-primary">{{ $listedProject->name }}</td>
                                    <td class="mono">{{ $listedProject->slug }}</td>
                                    <td>{{ $listedProject->members_count }}</td>
                                    <td>{{ $listedProject->recordings_count }}</td>
                                    <td>@include('web.partials.status-pill', ['status' => $listedProject->status])</td>
                                    <td>
                                        <div class="form-actions">
                                            <a class="button-secondary" href="{{ route('workspace.admin.projects', array_merge(request()->query(), ['edit' => $listedProject->id])) }}">Editar</a>
                                            <a class="button-secondary" href="{{ route('workspace.admin.projects.members', $listedProject) }}">Membros</a>
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
                    <h2 class="section-title">{{ $editingProject ? 'Editar projeto' : 'Novo projeto' }}</h2>
                    <p class="section-copy">Controle nome, slug e status dentro do Laravel modular.</p>
                </div>
                @if ($editingProject)
                    <div class="section-actions">
                        <a class="button-secondary" href="{{ route('workspace.admin.projects', request()->except('edit')) }}">Novo projeto</a>
                    </div>
                @endif
            </div>

            <form class="stack-form" method="POST" action="{{ $editingProject ? route('workspace.admin.projects.update', $editingProject) : route('workspace.admin.projects.store') }}">
                @csrf
                @if ($editingProject)
                    @method('PATCH')
                @endif

                <div class="field-grid">
                    <label for="project-name">Nome</label>
                    <input class="field-input" id="project-name" type="text" name="name" value="{{ old('name', $editingProject->name ?? '') }}" required>
                </div>

                <div class="field-grid">
                    <label for="project-slug">Slug</label>
                    <input class="field-input" id="project-slug" type="text" name="slug" value="{{ old('slug', $editingProject->slug ?? '') }}" {{ $editingProject ? 'required' : '' }}>
                </div>

                <div class="field-grid">
                    <label for="project-status">Status</label>
                    <select class="field-select" id="project-status" name="status">
                        <option value="active" @selected(old('status', $editingProject->status ?? 'active') === 'active')>Ativo</option>
                        <option value="archived" @selected(old('status', $editingProject->status ?? 'active') === 'archived')>Arquivado</option>
                    </select>
                </div>

                <div class="form-actions">
                    <button class="button-primary" type="submit">{{ $editingProject ? 'Salvar alteracoes' : 'Criar projeto' }}</button>
                </div>
            </form>
        </section>
    </div>
@endsection
