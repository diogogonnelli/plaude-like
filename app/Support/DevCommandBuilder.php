<?php

namespace App\Support;

class DevCommandBuilder
{
    public static function build(?bool $pcntlAvailable = null, ?bool $isWindows = null): array
    {
        $pcntlAvailable ??= function_exists('pcntl_fork');
        $isWindows ??= PHP_OS_FAMILY === 'Windows';

        $commands = [
            'php artisan serve',
            'php artisan queue:listen --tries=1 --timeout=0',
        ];
        $names = ['server', 'queue'];
        $colors = ['#93c5fd', '#c4b5fd'];
        $skipped = [];

        if ($pcntlAvailable) {
            $commands[] = 'php artisan pail --timeout=0';
            $names[] = 'logs';
            $colors[] = '#fb7185';
        } else {
            $skipped[] = 'php artisan pail --timeout=0';
        }

        $commands[] = 'npm run dev';
        $names[] = 'vite';
        $colors[] = '#fdba74';

        return [
            'executable' => $isWindows ? 'npx.cmd' : 'npx',
            'arguments' => [
                'concurrently',
                '-c',
                implode(',', $colors),
                ...$commands,
                '--names',
                implode(',', $names),
                '--kill-others',
            ],
            'skipped' => $skipped,
        ];
    }
}
