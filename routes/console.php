<?php

use App\Modules\Integrations\SupabaseImport\SupabaseToSqlServerSyncService;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Symfony\Component\Console\Command\Command as SymfonyCommand;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('data:sync-supabase
    {--table=* : Limita o sync para tabelas especificas do Supabase}
    {--connection= : Conexao Laravel de destino, padrao para o default atual}
    {--page-size=500 : Tamanho do lote paginado no REST do Supabase}
    {--dry-run : Busca do Supabase sem gravar no banco alvo}', function () {
    $connection = (string) ($this->option('connection') ?: config('database.default'));
    $pageSize = max(1, (int) $this->option('page-size'));
    $tables = array_values(array_filter((array) $this->option('table')));

    try {
        DB::connection($connection)->getPdo();

        $command = $this;
        $summary = app(SupabaseToSqlServerSyncService::class)->sync(
            tables: $tables,
            connection: $connection,
            pageSize: $pageSize,
            dryRun: (bool) $this->option('dry-run'),
            progress: static function (string $stage, string $table, int $count) use ($command): void {
                if ($stage === 'fetched') {
                    $command->line(sprintf('Supabase %s: %d registro(s) encontrados.', $table, $count));

                    return;
                }

                $command->line(sprintf('SQL %s: %d registro(s) persistidos.', $table, $count));
            },
        );
    } catch (\Throwable $exception) {
        $this->error($exception->getMessage());

        return SymfonyCommand::FAILURE;
    }

    $rows = [];
    foreach ($summary as $table => $stats) {
        $rows[] = [
            'Tabela' => $table,
            'Supabase' => $stats['fetched'],
            'Persistidos' => $stats['persisted'],
        ];
    }

    $this->newLine();
    $this->table(['Tabela', 'Supabase', 'Persistidos'], $rows);
    $this->info($this->option('dry-run')
        ? 'Dry run concluido sem gravar no banco alvo.'
        : sprintf('Sync concluido usando a conexao %s.', $connection));

    return SymfonyCommand::SUCCESS;
})->purpose('Puxa dados do Supabase e faz upsert na conexao SQL Server/Laravel alvo');
