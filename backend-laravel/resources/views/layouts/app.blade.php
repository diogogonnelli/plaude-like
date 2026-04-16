@extends('layouts.base')

@section('body')
<div class="flex min-h-screen">
    {{-- Sidebar --}}
    <aside class="w-64 bg-shell-dark text-white flex flex-col">
        <div class="p-xl">
            <span class="font-display text-2xl font-black tracking-tight">Sonora</span>
        </div>
        <nav class="flex-1 px-md space-y-xs">
            @yield('sidebar')
        </nav>
    </aside>

    {{-- Main --}}
    <div class="flex-1 flex flex-col">
        <header class="h-16 bg-surface border-b border-stroke flex items-center px-xl justify-between">
            <h1 class="text-lg font-bold">@yield('page-title')</h1>
            <div class="flex items-center gap-md">
                @yield('header-actions')
            </div>
        </header>

        <main class="flex-1 p-xl overflow-y-auto">
            @yield('content')
        </main>
    </div>
</div>
@endsection
