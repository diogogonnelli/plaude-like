<?php

declare(strict_types=1);

require __DIR__.'/../vendor/autoload.php';

use App\Support\DevCommandBuilder;
use Symfony\Component\Process\Process;

$command = DevCommandBuilder::build();

foreach ($command['skipped'] as $skippedCommand) {
    fwrite(STDOUT, "[dev] Skipping [{$skippedCommand}] because the pcntl extension is unavailable on this PHP runtime.".PHP_EOL);
}

$process = new Process(
    array_merge([$command['executable']], $command['arguments']),
    dirname(__DIR__),
);

$process->setTimeout(null);
$process->run(static function (string $type, string $buffer): void {
    echo $buffer;
});

exit($process->getExitCode() ?? 0);
