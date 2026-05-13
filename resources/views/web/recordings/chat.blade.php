@extends('layouts.app-shell', [
    'pageEyebrow' => 'Chat',
    'pageTitle' => $recording->title ?: 'Gravacao sem titulo',
    'pageSubtitle' => 'Converse com a IA usando o transcript desta gravacao.',
])

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
    <a class="btn-quiet" href="{{ route('workspace.recordings.show', $recording) }}">&larr; Detalhe</a>
    <a class="btn-quiet" href="{{ route('workspace.library') }}">Library</a>
@endsection

@section('content')
    @if (! $canChat)
        @include('web.partials.empty-state', [
            'eyebrow' => 'Chat bloqueado',
            'title' => 'Chat temporariamente indisponivel.',
            'description' => 'A conversa e liberada quando a gravacao estiver pronta e com transcript disponivel.',
        ])
    @endif

    <div class="chat-thread">
        @if ($messages->isEmpty())
            <div class="chat-msg-assistant">
                <span class="dot" aria-hidden="true"></span>
                <div>
                    <p>Pergunte algo sobre esta gravacao. Posso resumir, buscar trechos, listar acoes ou desenhar uma timeline.</p>
                </div>
            </div>
        @else
            @foreach ($messages as $message)
                @if ($message->role === 'user')
                    <div class="chat-msg-user">
                        {{ $message->content }}
                        <div class="type-meta" style="margin-top: var(--sp-2); font-size: 0.7rem;">{{ optional($message->created_at)->format('H:i') }}</div>
                    </div>
                @else
                    <div class="chat-msg-assistant">
                        <span class="dot" aria-hidden="true"></span>
                        <div>
                            {!! nl2br(e($message->content)) !!}
                            @if (! empty($message->citations))
                                <div style="margin-top: var(--sp-3);">
                                    <span class="type-kicker"><span class="dot"></span> Citacoes</span>
                                    <ul style="list-style: none; padding: 0; margin: var(--sp-2) 0 0; display: flex; flex-direction: column; gap: 4px;">
                                        @foreach ($message->citations as $citation)
                                            <li class="type-meta">{{ is_array($citation) ? json_encode($citation) : $citation }}</li>
                                        @endforeach
                                    </ul>
                                </div>
                            @endif
                        </div>
                    </div>
                @endif
            @endforeach
        @endif
    </div>

    <div class="chip-row" style="justify-content: center; margin-top: var(--sp-5);">
        @foreach ($quickPrompts as $prompt)
            <form method="POST" action="{{ route('workspace.recordings.chat.send', $recording) }}">
                @csrf
                <input type="hidden" name="message" value="{{ $prompt }}">
                <button class="chip" type="submit" @disabled(! $canChat) style="cursor: pointer;">{{ $prompt }}</button>
            </form>
        @endforeach
    </div>

    <form class="chat-composer" method="POST" action="{{ route('workspace.recordings.chat.send', $recording) }}">
        @csrf
        <textarea name="message" placeholder="Pergunte sobre contexto, resumo, riscos ou acoes..." rows="1" required @disabled(! $canChat)>{{ old('message') }}</textarea>
        <button class="btn-primary" type="submit" aria-label="Enviar" @disabled(! $canChat) style="height: 44px; min-height: 44px; padding: 0 16px;">
            <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 12l18-9-9 18-2-7-7-2z"/></svg>
        </button>
    </form>
@endsection
