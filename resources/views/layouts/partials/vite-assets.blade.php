@php
    $manifestPath = public_path('build/manifest.json');
    $manifest = file_exists($manifestPath)
        ? json_decode((string) file_get_contents($manifestPath), true)
        : [];
    $usingViteHot = file_exists(public_path('hot'));
    $cssFile = $manifest['resources/css/app.css']['file'] ?? null;
    $jsFile = $manifest['resources/js/app.js']['file'] ?? null;
    $cssHref = $cssFile ? '/build/'.$cssFile : null;
    $jsHref = $jsFile ? '/build/'.$jsFile : null;
@endphp

@if ($usingViteHot)
    @vite(['resources/css/app.css', 'resources/js/app.js'])
@else
    @if ($cssHref)
        <link rel="preload" as="style" href="{{ $cssHref }}">
        <link rel="stylesheet" href="{{ $cssHref }}">
    @endif
    @if ($jsHref)
        <link rel="modulepreload" as="script" href="{{ $jsHref }}">
        <script type="module" src="{{ $jsHref }}"></script>
    @endif
@endif
