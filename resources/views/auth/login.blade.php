@extends('layouts.base')

@section('body')
<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-shell-dark via-shell to-accent">
    <div class="bg-surface rounded-lg shadow-xl p-xxl w-full max-w-[448px]">
        <div class="text-center mb-xl">
            <span class="font-display text-3xl font-black tracking-tight text-shell-dark">Sonora</span>
            <p class="text-text-muted mt-xs">Gravacao inteligente em uma unica pagina.</p>
        </div>

        @if ($errors->any())
            <div class="bg-red-50 border border-accent text-accent rounded-sm p-md mb-md text-sm">
                @foreach ($errors->all() as $error)
                    <p>{{ $error }}</p>
                @endforeach
            </div>
        @endif

        <form method="POST" action="{{ route('login') }}">
            @csrf
            <div class="mb-md">
                <label for="email" class="block text-sm font-bold text-text mb-xs">E-mail</label>
                <input type="email" name="email" id="email" value="{{ old('email') }}" required autofocus
                    class="w-full rounded-md border border-stroke px-md py-sm focus:border-accent focus:ring-1 focus:ring-accent outline-none">
            </div>
            <div class="mb-lg">
                <label for="password" class="block text-sm font-bold text-text mb-xs">Senha</label>
                <input type="password" name="password" id="password" required
                    class="w-full rounded-md border border-stroke px-md py-sm focus:border-accent focus:ring-1 focus:ring-accent outline-none">
            </div>
            <button type="submit"
                class="w-full bg-accent hover:bg-accent-soft text-white font-bold py-sm rounded-md transition-colors duration-200">
                Entrar
            </button>
        </form>
    </div>
</div>
@endsection
