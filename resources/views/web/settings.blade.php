@extends('layouts.app-shell', [
    'pageEyebrow' => 'Settings',
    'pageTitle' => 'Sessao e organizacao',
    'pageSubtitle' => 'Perfil, projeto ativo, carteira e encerramento.',
])

@section('content')
    <div style="display: grid; grid-template-columns: 220px minmax(0, 1fr); gap: var(--sp-7);">
        <nav aria-label="Secoes" style="display: flex; flex-direction: column; gap: var(--sp-2); position: sticky; top: 80px; align-self: start;">
            <a href="#perfil" class="type-mono" style="color: var(--ink-mute); padding: 6px 0;">I &middot; Perfil</a>
            <a href="#projeto-ativo" class="type-mono" style="color: var(--ink-mute); padding: 6px 0;">II &middot; Projeto ativo</a>
            <a href="#carteira" class="type-mono" style="color: var(--ink-mute); padding: 6px 0;">III &middot; Carteira</a>
            <a href="#novo-projeto" class="type-mono" style="color: var(--ink-mute); padding: 6px 0;">IV &middot; Novo projeto</a>
            <a href="#sessao" class="type-mono" style="color: var(--ink-mute); padding: 6px 0;">V &middot; Sessao</a>
        </nav>

        <div style="display: flex; flex-direction: column; gap: var(--sp-7);">
            <section id="perfil">
                <div class="kicker-row"><span class="dot"></span><span class="type-kicker">I &middot; Perfil</span></div>
                <h2 class="type-title">{{ $user->full_name ?? $user->email }}</h2>
                <div class="meta-stack" style="max-width: 480px; margin-top: var(--sp-4);">
                    <div><span>Email</span><strong>{{ $user->email }}</strong></div>
                    <div><span>Perfil</span><strong>{{ $user->profile?->name ?? 'Sem perfil' }}</strong></div>
                    <div><span>Admin</span><strong>{{ $showAdminNav ? 'Sim' : 'Nao' }}</strong></div>
                </div>
            </section>

            <div class="divider-rule"><span class="dot"></span></div>

            <section id="projeto-ativo">
                <div class="kicker-row"><span class="dot"></span><span class="type-kicker">II &middot; Projeto ativo</span></div>
                <h2 class="type-title">Projeto da sessao</h2>
                <p class="type-meta" style="max-width: 56ch; margin-top: var(--sp-2);">
                    O projeto ativo e usado como default ao gravar e ao enviar audio pela home.
                </p>

                <form method="POST" action="{{ route('workspace.projects.active') }}" style="margin-top: var(--sp-4); display: flex; gap: var(--sp-3); align-items: flex-end; max-width: 560px;">
                    @csrf
                    <div class="field-grid" style="flex: 1;">
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
                    <button class="btn-primary" type="submit">Salvar</button>
                </form>

                <p class="type-meta" style="margin-top: var(--sp-3);">
                    Selecionado: <strong style="color: var(--ink-loud);">{{ $activeProject?->name ?? 'Sem projeto' }}</strong>
                </p>
            </section>

            <div class="divider-rule"><span class="dot"></span></div>

            <section id="carteira">
                <div class="kicker-row"><span class="dot"></span><span class="type-kicker">III &middot; Carteira</span></div>
                <h2 class="type-title">Projetos acessiveis</h2>

                @if ($projects->isEmpty())
                    @include('web.partials.empty-state', [
                        'eyebrow' => 'Sem carteira',
                        'title' => 'Nenhum projeto disponivel.',
                        'description' => 'Crie um projeto abaixo ou receba acesso para comecar a organizar novas gravacoes.',
                    ])
                @else
                    <ul class="index-list" style="margin-top: var(--sp-4);">
                        @foreach ($projects as $projectOption)
                            <li class="index-item">
                                <span class="index-num">{{ str_pad($loop->iteration, 2, '0', STR_PAD_LEFT) }}</span>
                                <div>
                                    <strong class="index-title">{{ $projectOption->name }}</strong>
                                    <div class="index-meta">
                                        <span>{{ $projectOption->recordings_count ?? 0 }} gravacoes</span>
                                        <span>{{ $projectOption->status ?? 'ativo' }}</span>
                                    </div>
                                </div>
                                <span>
                                    @if (optional($activeProject)->id === $projectOption->id)
                                        <span class="chip chip--accent"><span class="dot-status dot-status--accent"></span> Ativo</span>
                                    @endif
                                </span>
                            </li>
                        @endforeach
                    </ul>
                @endif
            </section>

            <div class="divider-rule"><span class="dot"></span></div>

            <section id="novo-projeto">
                <div class="kicker-row"><span class="dot"></span><span class="type-kicker">IV &middot; Novo projeto</span></div>
                <h2 class="type-title">Criar projeto</h2>
                <form method="POST" action="{{ route('workspace.projects.store') }}" style="margin-top: var(--sp-4); display: flex; gap: var(--sp-3); align-items: flex-end; max-width: 560px;">
                    @csrf
                    <div class="field-grid" style="flex: 1;">
                        <label for="new-project-name">Nome do projeto</label>
                        <input class="field-input" id="new-project-name" type="text" name="name" placeholder="Ex.: Operacao Q2" required>
                    </div>
                    <button class="btn-primary" type="submit">Criar</button>
                </form>
            </section>

            <div class="divider-rule"><span class="dot"></span></div>

            <section id="sessao">
                <div class="kicker-row"><span class="dot"></span><span class="type-kicker">V &middot; Sessao</span></div>
                <h2 class="type-title">Encerrar acesso</h2>
                <p class="type-meta" style="max-width: 56ch; margin-top: var(--sp-2); margin-bottom: var(--sp-4);">
                    Encerra a sessao no navegador atual. Outros dispositivos permanecem conectados.
                </p>
                <form method="POST" action="{{ route('logout') }}">
                    @csrf
                    <button class="btn-ghost" type="submit">Sair da sessao</button>
                </form>
            </section>
        </div>
    </div>
@endsection
