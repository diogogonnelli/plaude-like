@php
    $resolvedStatus = $status ?? null;
@endphp

<span class="status-pill {{ \App\Modules\Recordings\Support\WebUi::statusClass($resolvedStatus) }}">
    {{ \App\Modules\Recordings\Support\WebUi::statusLabel($resolvedStatus) }}
</span>
