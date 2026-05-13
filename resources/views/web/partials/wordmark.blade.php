@php
    $resolvedBrandName = $brandName ?? config('app.name', 'Sonora');
    $resolvedSubtitle = $subtitle ?? 'SPOT endorsed workflow';
    $resolvedHref = $href ?? route('home');
    $initial = \Illuminate\Support\Str::upper(\Illuminate\Support\Str::substr($resolvedBrandName, 0, 1));
@endphp

<a class="wordmark" href="{{ $resolvedHref }}">
    <span class="wordmark-mark">{{ $initial }}</span>
    <span class="wordmark-copy">
        <span class="wordmark-title">{{ $resolvedBrandName }}</span>
        <span class="wordmark-subtitle">{{ $resolvedSubtitle }}</span>
    </span>
</a>
