@extends('layouts.app-shell')

@php
    $messages = $recording->chatSession?->messages ?? collect();
    $canChat = $recording->status === 'ready' && $recording->transcriptSegments->isNotEmpty();
    $quickPrompts = [
        'Resuma a reuniao em 5 pontos.',
        'Quais foram os proximos passos combinados?',
        'Liste os riscos e dependencias citados.',
        'Quais clientes, marcas ou projetos apareceram na conversa?',
    ];
@endphp

@section('topbar-actions')
    <a class="button-secondary" href="{{ route('workspace.recordings.show', $recording) }}">Voltar ao detalhe</a>
    <a class="button-secondary" href="{{ route('workspace.library') }}">Library</a>
@endsection

@section('content')
    <div class="detail-grid">
        <section class="surface-panel">
            <div class="section-header">
                <div>
                    <h2 class="section-title">Chat contextual</h2>
                    <p class="section-copy">Perguntas guiadas pelo transcript atual, persistidas no historico desta gravacao.</p>
                </div>
                @include('web.partials.status-pill', ['status' => $recording->status])
            </div>

            @if (! $canChat)
                @include('web.partials.empty-state', [
                    'title' => 'Chat temporariamente bloqueado',
                    'description' => 'A conversa e liberada quando a gravacao estiver pronta e com transcript disponivel.',
                ])
            @endif

            <div class="chat-thread">
                @if ($messages->isEmpty())
                    @include('web.partials.empty-state', [
                        'title' => 'Nenhuma mensagem ainda',
                        'description' => 'Use um prompt rapido ou escreva sua primeira pergunta sobre esta gravacao.',
                    ])
                @else
                    @foreach ($messages as $message)
                        <article class="chat-bubble {{ $message->role }}">
                            <div class="meta-row">
                                <span class="meta-chip">{{ $message->role === 'assistant' ? 'Assistente' : 'Usuario' }}</span>
                                <span class="meta-chip">{{ optional($message->created_at)->format('d/m/Y H:i') ?? 'Sem data' }}</span>
                            </div>
                            <p class="recording-card-copy">{{ $message->content }}</p>
                            @if (! empty($message->citations))
                                <div class="detail-block">
                                    <span class="caption">Citacoes</span>
                                    <ul class="list-plain">
                                        @foreach ($message->citations as $citation)
                                            <li>{{ is_array($citation) ? json_encode($citation) : $citation }}</li>
                                        @endforeach
                                    </ul>
                                </div>
                            @endif
                        </article>
                    @endforeach
                @endif
            </div>

            <div class="chip-list">
                @foreach ($quickPrompts as $prompt)
                    <form class="quick-chip" method="POST" action="{{ route('workspace.recordings.chat.send', $recording) }}">
                        @csrf
                        <input type="hidden" name="message" value="{{ $prompt }}">
                        <button type="submit" @disabled(! $canChat)>{{ $prompt }}</button>
                    </form>
                @endforeach
            </div>

            <form class="stack-form" method="POST" action="{{ route('workspace.recordings.chat.send', $recording) }}">
                @csrf
                <div class="field-grid">
                    <label for="chat-message">Pergunta</label>
                    <textarea class="field-textarea" id="chat-message" name="message" placeholder="Pergunte sobre contexto, resumo, riscos ou acoes..." @disabled(! $canChat)>{{ old('message') }}</textarea>
                </div>
                <div class="form-actions">
                    <button class="button-primary" type="submit" @disabled(! $canChat)>Enviar mensagem</button>
                </div>
            </form>
        </section>

        <div class="detail-stack">
            <section class="surface-panel detail-block">
                <h2 class="section-title">Contexto da gravacao</h2>
                <div class="info-grid">
                    <div class="info-card">
                        <span>Titulo</span>
                        <strong>{{ $recording->title }}</strong>
                    </div>
                    <div class="info-card">
                        <span>Projeto</span>
                        <strong>{{ $recording->project?->name ?? 'Sem projeto' }}</strong>
                    </div>
                    <div class="info-card">
                        <span>Origem</span>
                        <strong>{{ \App\Modules\Recordings\Support\WebUi::recordingSourceDetail($recording) }}</strong>
                    </div>
                    <div class="info-card">
                        <span>Segmentos</span>
                        <strong>{{ $recording->transcriptSegments->count() }}</strong>
                    </div>
                </div>
            </section>

            <section class="surface-panel detail-block">
                <h2 class="section-title">Resumo disponivel</h2>
                @if ($recording->summary?->overview)
                    <div class="detail-item">
                        <span>Overview</span>
                        <strong>{{ $recording->summary->overview }}</strong>
                    </div>
                @else
                    @include('web.partials.empty-state', [
                        'title' => 'Sem overview',
                        'description' => 'O resumo desta gravacao ainda nao esta pronto.',
                    ])
                @endif
            </section>
        </div>
    </div>
@endsection
