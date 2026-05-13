<?php

namespace App\Modules\Integrations\SupabaseImport;

use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use InvalidArgumentException;
use RuntimeException;

class SupabaseToSqlServerSyncService
{
    /**
     * @var array<string, string>
     */
    private array $profileIdMap = [];

    private const TABLE_ORDER = [
        'profiles',
        'users',
        'projects',
        'project_members',
        'recordings',
        'transcript_segments',
        'summaries',
        'note_artifacts',
        'chat_sessions',
        'chat_messages',
    ];

    private const TABLE_SORT = [
        'profiles' => 'id.asc',
        'users' => 'id.asc',
        'projects' => 'id.asc',
        'project_members' => 'project_id.asc,user_id.asc',
        'recordings' => 'id.asc',
        'transcript_segments' => 'recording_id.asc,start_ms.asc,id.asc',
        'summaries' => 'recording_id.asc',
        'note_artifacts' => 'recording_id.asc',
        'chat_sessions' => 'recording_id.asc',
        'chat_messages' => 'chat_session_id.asc,created_at.asc,id.asc',
    ];

    public function availableTables(): array
    {
        return self::TABLE_ORDER;
    }

    /**
     * @param  array<int, string>  $tables
     * @param  callable(string, string, int): void|null  $progress
     * @return array<string, array{fetched:int,persisted:int}>
     */
    public function sync(
        array $tables = [],
        ?string $connection = null,
        int $pageSize = 500,
        bool $dryRun = false,
        ?callable $progress = null,
    ): array {
        if ($pageSize < 1) {
            throw new InvalidArgumentException('O page-size deve ser maior que zero.');
        }

        $selectedTables = $this->resolveTables($tables);
        $connection ??= config('database.default');
        $summary = [];
        $this->profileIdMap = [];

        foreach ($selectedTables as $table) {
            $rows = $this->fetchRows($table, $pageSize);
            $fetched = count($rows);
            $summary[$table] = ['fetched' => $fetched, 'persisted' => 0];

            if ($progress) {
                $progress('fetched', $table, $fetched);
            }

            if ($dryRun || $rows === []) {
                continue;
            }

            $persisted = $this->persistRows($connection, $table, $rows);
            $summary[$table]['persisted'] = $persisted;

            if ($progress) {
                $progress('persisted', $table, $persisted);
            }
        }

        return $summary;
    }

    /**
     * @param  array<int, string>  $tables
     * @return array<int, string>
     */
    private function resolveTables(array $tables): array
    {
        if ($tables === []) {
            return self::TABLE_ORDER;
        }

        $normalized = array_values(array_unique(array_map(
            static fn (string $table): string => Str::lower(trim($table)),
            $tables,
        )));

        $invalid = array_values(array_diff($normalized, self::TABLE_ORDER));
        if ($invalid !== []) {
            throw new InvalidArgumentException(sprintf(
                'Tabela(s) invalida(s): %s. Opcoes: %s.',
                implode(', ', $invalid),
                implode(', ', self::TABLE_ORDER),
            ));
        }

        return array_values(array_filter(
            self::TABLE_ORDER,
            static fn (string $table): bool => in_array($table, $normalized, true),
        ));
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    private function fetchRows(string $table, int $pageSize): array
    {
        $baseUrl = rtrim((string) config('services.supabase.url'), '/');
        $serviceRoleKey = (string) config('services.supabase.service_role_key');
        $schema = (string) config('services.supabase.schema', 'public');
        $verifyTls = (bool) config('services.supabase.verify_tls', true);

        if ($baseUrl === '' || $serviceRoleKey === '') {
            throw new RuntimeException('SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY precisam estar configurados no Laravel.');
        }

        $offset = 0;
        $rows = [];

        do {
            $response = Http::acceptJson()
                ->withHeaders([
                    'apikey' => $serviceRoleKey,
                    'Authorization' => sprintf('Bearer %s', $serviceRoleKey),
                    'Accept-Profile' => $schema,
                ])
                ->withOptions(['verify' => $verifyTls])
                ->timeout(60)
                ->retry(3, 250)
                ->get(sprintf('%s/rest/v1/%s', $baseUrl, $table), [
                    'select' => '*',
                    'order' => self::TABLE_SORT[$table] ?? 'id.asc',
                    'limit' => $pageSize,
                    'offset' => $offset,
                ]);

            if ($response->failed()) {
                throw new RuntimeException(sprintf(
                    'Falha ao consultar a tabela %s no Supabase (%d): %s',
                    $table,
                    $response->status(),
                    $response->body(),
                ));
            }

            $page = $response->json();
            if (! is_array($page)) {
                throw new RuntimeException(sprintf('Resposta invalida do Supabase para a tabela %s.', $table));
            }

            foreach ($page as $item) {
                if (is_array($item)) {
                    $rows[] = $item;
                }
            }

            $offset += $pageSize;
        } while (count($page) === $pageSize);

        return $rows;
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     */
    private function persistRows(string $connection, string $table, array $rows): int
    {
        return DB::connection($connection)->transaction(function () use ($connection, $table, $rows): int {
            return match ($table) {
                'profiles' => $this->persistProfiles($connection, $rows),
                'users' => $this->persistUsers($connection, $rows),
                'projects' => $this->persistProjects($connection, $rows),
                'project_members' => $this->persistProjectMembers($connection, $rows),
                'recordings' => $this->persistRecordings($connection, $rows),
                'transcript_segments' => $this->persistTranscriptSegments($connection, $rows),
                'summaries' => $this->persistSummaries($connection, $rows),
                'note_artifacts' => $this->persistNoteArtifacts($connection, $rows),
                'chat_sessions' => $this->persistChatSessions($connection, $rows),
                'chat_messages' => $this->persistChatMessages($connection, $rows),
                default => throw new InvalidArgumentException(sprintf('Tabela %s nao suportada.', $table)),
            };
        });
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     */
    private function persistProfiles(string $connection, array $rows): int
    {
        $existingProfiles = DB::connection($connection)
            ->table('profiles')
            ->select(['id', 'code'])
            ->get()
            ->keyBy('code');

        $payload = array_map(function (array $row) use ($existingProfiles): array {
            $remoteId = (string) $row['id'];
            $code = (string) $row['code'];
            $localId = isset($existingProfiles[$code])
                ? (string) $existingProfiles[$code]->id
                : $remoteId;

            $this->profileIdMap[$remoteId] = $localId;

            return [
                'id' => $localId,
                'code' => $code,
                'name' => (string) $row['name'],
                'description' => $this->stringOrNull($row['description'] ?? null),
                'is_system' => (bool) ($row['is_system'] ?? false),
                'created_at' => $this->timestampOrNull($row['created_at'] ?? null),
                'updated_at' => $this->timestampOrNull($row['updated_at'] ?? null),
            ];
        }, $rows);

        return $this->upsert($connection, 'profiles', $payload, ['code'], [
            'name',
            'description',
            'is_system',
            'updated_at',
        ]);
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     */
    private function persistUsers(string $connection, array $rows): int
    {
        $existingPasswords = DB::connection($connection)
            ->table('users')
            ->pluck('password', 'id')
            ->all();

        $payload = array_map(function (array $row) use ($existingPasswords): array {
            $id = (string) $row['id'];

            return [
                'id' => $id,
                'email' => $this->stringOrNull($row['email'] ?? null),
                'full_name' => $this->stringOrNull($row['full_name'] ?? null),
                'profile_id' => $this->mapProfileId((string) $row['profile_id']),
                'is_active' => (bool) ($row['is_active'] ?? true),
                'password' => $existingPasswords[$id] ?? Hash::make(Str::uuid()->toString()),
                'remember_token' => null,
                'created_at' => $this->timestampOrNull($row['created_at'] ?? null),
                'updated_at' => $this->timestampOrNull($row['updated_at'] ?? null),
            ];
        }, $rows);

        return $this->upsert($connection, 'users', $payload, ['id'], [
            'email',
            'full_name',
            'profile_id',
            'is_active',
            'updated_at',
        ]);
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     */
    private function persistProjects(string $connection, array $rows): int
    {
        $payload = array_map(function (array $row): array {
            return [
                'id' => (string) $row['id'],
                'name' => (string) $row['name'],
                'slug' => (string) $row['slug'],
                'status' => (string) ($row['status'] ?? 'active'),
                'created_at' => $this->timestampOrNull($row['created_at'] ?? null),
                'updated_at' => $this->timestampOrNull($row['updated_at'] ?? null),
            ];
        }, $rows);

        return $this->upsert($connection, 'projects', $payload, ['id'], [
            'name',
            'slug',
            'status',
            'created_at',
            'updated_at',
        ]);
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     */
    private function persistProjectMembers(string $connection, array $rows): int
    {
        $payload = array_map(function (array $row): array {
            return [
                'project_id' => (string) $row['project_id'],
                'user_id' => (string) $row['user_id'],
                'role' => (string) ($row['role'] ?? 'member'),
                'created_at' => $this->timestampOrNull($row['created_at'] ?? null),
            ];
        }, $rows);

        return $this->upsert($connection, 'project_members', $payload, ['project_id', 'user_id'], [
            'role',
            'created_at',
        ]);
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     */
    private function persistRecordings(string $connection, array $rows): int
    {
        $payload = array_map(function (array $row): array {
            return [
                'id' => (string) $row['id'],
                'user_id' => (string) $row['user_id'],
                'created_by_user_id' => (string) $row['created_by_user_id'],
                'project_id' => $this->stringOrNull($row['project_id'] ?? null),
                'title' => (string) $row['title'],
                'source_type' => (string) $row['source_type'],
                'status' => (string) ($row['status'] ?? 'uploaded'),
                'duration_ms' => isset($row['duration_ms']) ? (int) $row['duration_ms'] : null,
                'audio_path' => $this->stringOrNull($row['audio_path'] ?? null),
                'capture_metadata' => $this->jsonOrNull($row['capture_metadata'] ?? null),
                'transcription_provider' => $this->stringOrNull($row['transcription_provider'] ?? null),
                'transcription_job_id' => $this->stringOrNull($row['transcription_job_id'] ?? null),
                'transcription_started_at' => $this->timestampOrNull($row['transcription_started_at'] ?? null),
                'transcription_completed_at' => $this->timestampOrNull($row['transcription_completed_at'] ?? null),
                'last_error' => $this->stringOrNull($row['last_error'] ?? null),
                'created_at' => $this->timestampOrNull($row['created_at'] ?? null),
                'updated_at' => $this->timestampOrNull($row['updated_at'] ?? null),
            ];
        }, $rows);

        return $this->upsert($connection, 'recordings', $payload, ['id'], [
            'user_id',
            'created_by_user_id',
            'project_id',
            'title',
            'source_type',
            'status',
            'duration_ms',
            'audio_path',
            'capture_metadata',
            'transcription_provider',
            'transcription_job_id',
            'transcription_started_at',
            'transcription_completed_at',
            'last_error',
            'created_at',
            'updated_at',
        ]);
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     */
    private function persistTranscriptSegments(string $connection, array $rows): int
    {
        $payload = array_map(function (array $row): array {
            return [
                'id' => (string) $row['id'],
                'recording_id' => (string) $row['recording_id'],
                'speaker_label' => (string) $row['speaker_label'],
                'start_ms' => (int) $row['start_ms'],
                'end_ms' => (int) $row['end_ms'],
                'text' => (string) $row['text'],
            ];
        }, $rows);

        return $this->upsert($connection, 'transcript_segments', $payload, ['id'], [
            'recording_id',
            'speaker_label',
            'start_ms',
            'end_ms',
            'text',
        ]);
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     */
    private function persistSummaries(string $connection, array $rows): int
    {
        $payload = array_map(function (array $row): array {
            return [
                'recording_id' => (string) $row['recording_id'],
                'overview' => (string) $row['overview'],
                'chapters' => $this->jsonOrArray($row['chapters'] ?? []),
            ];
        }, $rows);

        return $this->upsert($connection, 'summaries', $payload, ['recording_id'], [
            'overview',
            'chapters',
        ]);
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     */
    private function persistNoteArtifacts(string $connection, array $rows): int
    {
        $payload = array_map(function (array $row): array {
            return [
                'recording_id' => (string) $row['recording_id'],
                'title' => (string) $row['title'],
                'tags' => $this->jsonOrArray($row['tags'] ?? []),
                'highlights' => $this->jsonOrArray($row['highlights'] ?? []),
                'action_items' => $this->jsonOrArray($row['action_items'] ?? []),
            ];
        }, $rows);

        return $this->upsert($connection, 'note_artifacts', $payload, ['recording_id'], [
            'title',
            'tags',
            'highlights',
            'action_items',
        ]);
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     */
    private function persistChatSessions(string $connection, array $rows): int
    {
        $payload = array_map(function (array $row): array {
            return [
                'id' => (string) $row['id'],
                'recording_id' => (string) $row['recording_id'],
                'created_at' => $this->timestampOrNull($row['created_at'] ?? null),
            ];
        }, $rows);

        return $this->upsert($connection, 'chat_sessions', $payload, ['id'], [
            'recording_id',
            'created_at',
        ]);
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     */
    private function persistChatMessages(string $connection, array $rows): int
    {
        $payload = array_map(function (array $row): array {
            return [
                'id' => (string) $row['id'],
                'chat_session_id' => (string) $row['chat_session_id'],
                'role' => (string) $row['role'],
                'content' => (string) $row['content'],
                'citations' => $this->jsonOrNull($row['citations'] ?? null),
                'created_at' => $this->timestampOrNull($row['created_at'] ?? null),
            ];
        }, $rows);

        return $this->upsert($connection, 'chat_messages', $payload, ['id'], [
            'chat_session_id',
            'role',
            'content',
            'citations',
            'created_at',
        ]);
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     * @param  array<int, string>  $uniqueBy
     * @param  array<int, string>  $updateColumns
     */
    private function upsert(string $connection, string $table, array $rows, array $uniqueBy, array $updateColumns): int
    {
        if ($rows === []) {
            return 0;
        }

        $columnsPerRow = max(1, count($rows[0]));
        $maxRowsPerBatch = max(1, intdiv(2000, $columnsPerRow));

        foreach (array_chunk($rows, $maxRowsPerBatch) as $chunk) {
            DB::connection($connection)->table($table)->upsert($chunk, $uniqueBy, $updateColumns);
        }

        return count($rows);
    }

    private function mapProfileId(string $remoteProfileId): string
    {
        return $this->profileIdMap[$remoteProfileId] ?? $remoteProfileId;
    }

    private function stringOrNull(mixed $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        return (string) $value;
    }

    private function timestampOrNull(mixed $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        return CarbonImmutable::parse((string) $value)->utc()->format('Y-m-d H:i:s');
    }

    private function jsonOrNull(mixed $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        return $this->encodeJson($value);
    }

    private function jsonOrArray(mixed $value): string
    {
        if ($value === null || $value === '') {
            return '[]';
        }

        return $this->encodeJson($value);
    }

    private function encodeJson(mixed $value): string
    {
        $json = json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        if ($json === false) {
            throw new RuntimeException(sprintf('Falha ao serializar JSON: %s', json_last_error_msg()));
        }

        return $json;
    }
}