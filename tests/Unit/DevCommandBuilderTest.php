<?php

namespace Tests\Unit;

use App\Support\DevCommandBuilder;
use PHPUnit\Framework\TestCase;

class DevCommandBuilderTest extends TestCase
{
    public function test_it_skips_pail_when_pcntl_is_not_available(): void
    {
        $command = DevCommandBuilder::build(
            pcntlAvailable: false,
            isWindows: true,
        );

        $this->assertSame('npx.cmd', $command['executable']);
        $this->assertSame([
            'concurrently',
            '-c',
            '#93c5fd,#c4b5fd,#fdba74',
            'php artisan serve',
            'php artisan queue:listen --tries=1 --timeout=0',
            'npm run dev',
            '--names',
            'server,queue,vite',
            '--kill-others',
        ], $command['arguments']);
        $this->assertSame([
            'php artisan pail --timeout=0',
        ], $command['skipped']);
    }

    public function test_it_keeps_pail_when_pcntl_is_available(): void
    {
        $command = DevCommandBuilder::build(
            pcntlAvailable: true,
            isWindows: false,
        );

        $this->assertSame('npx', $command['executable']);
        $this->assertSame([
            'concurrently',
            '-c',
            '#93c5fd,#c4b5fd,#fb7185,#fdba74',
            'php artisan serve',
            'php artisan queue:listen --tries=1 --timeout=0',
            'php artisan pail --timeout=0',
            'npm run dev',
            '--names',
            'server,queue,logs,vite',
            '--kill-others',
        ], $command['arguments']);
        $this->assertSame([], $command['skipped']);
    }
}
