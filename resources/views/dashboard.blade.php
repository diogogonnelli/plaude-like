@extends('layouts.app')

@section('page-title', 'Dashboard')

@section('sidebar')
    <a href="{{ route('home') }}" class="block px-md py-sm rounded-sm bg-white/10 text-white font-bold">
        Dashboard
    </a>
@endsection

@section('content')
<div class="space-y-xl">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-md">
        <div class="bg-surface rounded-lg border border-stroke p-lg">
            <p class="text-text-muted text-sm font-bold">Total Gravações</p>
            <p class="text-2xl font-bold mt-xs">{{ $recordings->count() }}</p>
        </div>
        <div class="bg-surface rounded-lg border border-stroke p-lg">
            <p class="text-text-muted text-sm font-bold">Prontas</p>
            <p class="text-2xl font-bold mt-xs text-positive">{{ $recordings->where('status', 'ready')->count() }}</p>
        </div>
        <div class="bg-surface rounded-lg border border-stroke p-lg">
            <p class="text-text-muted text-sm font-bold">Processando</p>
            <p class="text-2xl font-bold mt-xs text-warning">{{ $recordings->whereIn('status', ['processing_transcript', 'processing_summary', 'indexing'])->count() }}</p>
        </div>
    </div>

    <div class="bg-surface rounded-lg border border-stroke">
        <div class="p-lg border-b border-stroke">
            <h2 class="font-bold text-lg">Gravações Recentes</h2>
        </div>
        <div class="divide-y divide-stroke">
            @forelse($recordings as $recording)
                <div class="p-lg flex items-center justify-between">
                    <div>
                        <p class="font-bold">{{ $recording->title }}</p>
                        <p class="text-sm text-text-muted">
                            {{ $recording->created_at->format('d/m/Y H:i') }}
                            @if($recording->project)
                                · {{ $recording->project->name }}
                            @endif
                        </p>
                    </div>
                    <span class="px-sm py-xxs rounded-pill text-xs font-bold
                        @if($recording->status === 'ready') bg-green-100 text-positive
                        @elseif($recording->status === 'failed') bg-red-100 text-accent
                        @else bg-yellow-100 text-warning
                        @endif">
                        {{ $recording->status }}
                    </span>
                </div>
            @empty
                <div class="p-lg text-center text-text-muted">
                    Nenhuma gravação encontrada.
                </div>
            @endforelse
        </div>
    </div>
</div>
@endsection
