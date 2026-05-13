<?php

namespace App\Modules\Recordings\Support;

use App\Modules\Recordings\Models\Recording;

class WebUi
{
    public static function statusLabel(?string $status): string
    {
        return match ($status) {
            'active' => 'Ativo',
            'inactive' => 'Inativo',
            'archived' => 'Arquivado',
            'owner' => 'Owner',
            'member' => 'Member',
            'uploaded' => 'Enviado',
            'processing_transcript' => 'Transcrevendo',
            'processing_summary' => 'Resumindo',
            'indexing' => 'Indexando',
            'ready' => 'Pronto',
            'failed' => 'Falhou',
            default => (string) $status,
        };
    }

    public static function statusClass(?string $status): string
    {
        return match ($status) {
            'active', 'ready', 'owner' => 'status-ready',
            'inactive' => 'status-inactive',
            'archived', 'indexing', 'member' => 'status-indexing',
            'uploaded', 'processing_transcript', 'processing_summary' => 'status-processing_transcript',
            'failed' => 'status-failed',
            default => 'status-neutral',
        };
    }

    public static function recordingSourceLabel(Recording $recording): string
    {
        if ($recording->source_type === 'desktop_meeting') {
            return self::sourceAppLabel(data_get($recording->capture_metadata, 'sourceApp'));
        }

        return match ($recording->source_type) {
            'microphone' => 'Microfone',
            'upload' => 'Upload',
            default => ucfirst((string) $recording->source_type),
        };
    }

    public static function recordingSourceDetail(Recording $recording): string
    {
        if ($recording->source_type !== 'desktop_meeting') {
            return self::recordingSourceLabel($recording);
        }

        $source = self::sourceAppLabel(data_get($recording->capture_metadata, 'sourceApp'));
        $platform = self::platformLabel(data_get($recording->capture_metadata, 'platform'));

        return $platform === '—' ? $source : "{$source} · {$platform}";
    }

    public static function sourceAppLabel(?string $sourceApp): string
    {
        return match ($sourceApp) {
            'teams' => 'Teams',
            'zoom' => 'Zoom',
            'meet' => 'Google Meet',
            'system_audio' => 'Áudio do sistema',
            null, '' => 'Reunião online',
            default => ucfirst((string) $sourceApp),
        };
    }

    public static function platformLabel(?string $platform): string
    {
        return match ($platform) {
            'windows' => 'Windows',
            'macos' => 'macOS',
            null, '' => '—',
            default => ucfirst((string) $platform),
        };
    }

    public static function formatTimestamp(int $milliseconds): string
    {
        $totalSeconds = (int) floor($milliseconds / 1000);
        $minutes = str_pad((string) floor($totalSeconds / 60), 2, '0', STR_PAD_LEFT);
        $seconds = str_pad((string) ($totalSeconds % 60), 2, '0', STR_PAD_LEFT);

        return "{$minutes}:{$seconds}";
    }
}
