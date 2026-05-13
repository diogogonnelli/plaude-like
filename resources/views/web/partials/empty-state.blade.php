@php
    $resolvedEyebrow = $eyebrow ?? null;
    $resolvedTitle = $title ?? 'Sem registros';
    $resolvedDescription = $description ?? ($copy ?? null);
    $resolvedCta = $cta ?? null;
@endphp

<div class="empty-state">
    @if ($resolvedEyebrow)
        <div class="kicker-row"><span class="dot"></span><span class="type-kicker">{{ $resolvedEyebrow }}</span></div>
    @endif
    <h3 class="type-title">{{ $resolvedTitle }}</h3>
    @if ($resolvedDescription)
        <p>{{ $resolvedDescription }}</p>
    @endif
    @if ($resolvedCta && is_array($resolvedCta) && isset($resolvedCta['route'], $resolvedCta['label']))
        <a class="btn-primary" href="{{ $resolvedCta['route'] }}">{{ $resolvedCta['label'] }}</a>
    @endif
</div>
