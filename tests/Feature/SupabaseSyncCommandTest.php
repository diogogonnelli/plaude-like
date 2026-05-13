<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class SupabaseSyncCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_imports_core_data_from_supabase_into_the_target_connection(): void
    {
        config()->set('services.supabase.url', 'https://example.supabase.co');
        config()->set('services.supabase.service_role_key', 'service-role-key');
        config()->set('services.supabase.schema', 'public');

        Http::preventStrayRequests();
        Http::fake([
            'https://example.supabase.co/rest/v1/profiles*' => Http::response([
                [
                    'id' => '11111111-1111-1111-1111-111111111111',
                    'code' => 'user',
                    'name' => 'Usuario',
                    'description' => 'Perfil padrao',
                    'is_system' => true,
                    'created_at' => '2026-04-17T10:00:00+00:00',
                    'updated_at' => '2026-04-17T10:00:00+00:00',
                ],
            ], 200),
            'https://example.supabase.co/rest/v1/users*' => Http::response([
                [
                    'id' => '22222222-2222-2222-2222-222222222222',
                    'email' => 'user@example.com',
                    'full_name' => 'Usuario Teste',
                    'profile_id' => '11111111-1111-1111-1111-111111111111',
                    'is_active' => true,
                    'created_at' => '2026-04-17T10:01:00+00:00',
                    'updated_at' => '2026-04-17T10:01:00+00:00',
                ],
            ], 200),
            'https://example.supabase.co/rest/v1/projects*' => Http::response([
                [
                    'id' => '33333333-3333-3333-3333-333333333333',
                    'name' => 'Projeto Sonora',
                    'slug' => 'projeto-sonora',
                    'status' => 'active',
                    'created_at' => '2026-04-17T10:02:00+00:00',
                    'updated_at' => '2026-04-17T10:02:00+00:00',
                ],
            ], 200),
            'https://example.supabase.co/rest/v1/project_members*' => Http::response([
                [
                    'project_id' => '33333333-3333-3333-3333-333333333333',
                    'user_id' => '22222222-2222-2222-2222-222222222222',
                    'role' => 'owner',
                    'created_at' => '2026-04-17T10:03:00+00:00',
                ],
            ], 200),
            'https://example.supabase.co/rest/v1/recordings*' => Http::response([
                [
                    'id' => '44444444-4444-4444-4444-444444444444',
                    'user_id' => '22222222-2222-2222-2222-222222222222',
                    'created_by_user_id' => '22222222-2222-2222-2222-222222222222',
                    'project_id' => '33333333-3333-3333-3333-333333333333',
                    'title' => 'Reuniao de status',
                    'source_type' => 'desktop_meeting',
                    'status' => 'ready',
                    'duration_ms' => 120000,
                    'audio_path' => 'recordings/status.mp3',
                    'capture_metadata' => ['platform' => 'windows'],
                    'transcription_provider' => 'assemblyai',
                    'transcription_job_id' => 'job-123',
                    'transcription_started_at' => '2026-04-17T10:04:00+00:00',
                    'transcription_completed_at' => '2026-04-17T10:05:00+00:00',
                    'last_error' => null,
                    'created_at' => '2026-04-17T10:04:00+00:00',
                    'updated_at' => '2026-04-17T10:05:00+00:00',
                ],
            ], 200),
            'https://example.supabase.co/rest/v1/transcript_segments*' => Http::response([
                [
                    'id' => '55555555-5555-5555-5555-555555555555',
                    'recording_id' => '44444444-4444-4444-4444-444444444444',
                    'speaker_label' => 'Pessoa 1',
                    'start_ms' => 0,
                    'end_ms' => 1200,
                    'text' => 'Resumo inicial',
                ],
            ], 200),
            'https://example.supabase.co/rest/v1/summaries*' => Http::response([
                [
                    'recording_id' => '44444444-4444-4444-4444-444444444444',
                    'overview' => 'Tudo certo para seguir.',
                    'chapters' => [['title' => 'Inicio']],
                ],
            ], 200),
            'https://example.supabase.co/rest/v1/note_artifacts*' => Http::response([
                [
                    'recording_id' => '44444444-4444-4444-4444-444444444444',
                    'title' => 'Ata da reuniao',
                    'tags' => ['status'],
                    'highlights' => ['Prazo confirmado'],
                    'action_items' => ['Enviar ata'],
                ],
            ], 200),
            'https://example.supabase.co/rest/v1/chat_sessions*' => Http::response([
                [
                    'id' => '66666666-6666-6666-6666-666666666666',
                    'recording_id' => '44444444-4444-4444-4444-444444444444',
                    'created_at' => '2026-04-17T10:06:00+00:00',
                ],
            ], 200),
            'https://example.supabase.co/rest/v1/chat_messages*' => Http::response([
                [
                    'id' => '77777777-7777-7777-7777-777777777777',
                    'chat_session_id' => '66666666-6666-6666-6666-666666666666',
                    'role' => 'assistant',
                    'content' => 'Resumo entregue.',
                    'citations' => [['recordingId' => '44444444-4444-4444-4444-444444444444']],
                    'created_at' => '2026-04-17T10:07:00+00:00',
                ],
            ], 200),
        ]);

        $this->artisan('data:sync-supabase', [
            '--connection' => 'sqlite',
        ])->assertExitCode(0);

        $this->assertDatabaseHas('profiles', [
            'id' => '11111111-1111-1111-1111-111111111111',
            'code' => 'user',
        ]);

        $this->assertDatabaseHas('users', [
            'id' => '22222222-2222-2222-2222-222222222222',
            'email' => 'user@example.com',
            'full_name' => 'Usuario Teste',
        ]);

        $this->assertDatabaseHas('projects', [
            'id' => '33333333-3333-3333-3333-333333333333',
            'slug' => 'projeto-sonora',
        ]);

        $this->assertDatabaseHas('project_members', [
            'project_id' => '33333333-3333-3333-3333-333333333333',
            'user_id' => '22222222-2222-2222-2222-222222222222',
            'role' => 'owner',
        ]);

        $this->assertDatabaseHas('recordings', [
            'id' => '44444444-4444-4444-4444-444444444444',
            'title' => 'Reuniao de status',
            'source_type' => 'desktop_meeting',
        ]);

        $this->assertDatabaseHas('summaries', [
            'recording_id' => '44444444-4444-4444-4444-444444444444',
            'overview' => 'Tudo certo para seguir.',
        ]);

        $this->assertDatabaseHas('note_artifacts', [
            'recording_id' => '44444444-4444-4444-4444-444444444444',
            'title' => 'Ata da reuniao',
        ]);

        $this->assertDatabaseHas('chat_messages', [
            'id' => '77777777-7777-7777-7777-777777777777',
            'content' => 'Resumo entregue.',
        ]);
    }

    public function test_it_can_dry_run_supabase_import_without_persisting_rows(): void
    {
        config()->set('services.supabase.url', 'https://example.supabase.co');
        config()->set('services.supabase.service_role_key', 'service-role-key');
        config()->set('services.supabase.schema', 'public');

        Http::preventStrayRequests();
        Http::fake([
            'https://example.supabase.co/rest/v1/profiles*' => Http::response([
                [
                    'id' => '11111111-1111-1111-1111-111111111111',
                    'code' => 'user',
                    'name' => 'Usuario',
                    'description' => 'Perfil padrao',
                    'is_system' => true,
                    'created_at' => '2026-04-17T10:00:00+00:00',
                    'updated_at' => '2026-04-17T10:00:00+00:00',
                ],
            ], 200),
        ]);

        $this->artisan('data:sync-supabase', [
            '--connection' => 'sqlite',
            '--table' => ['profiles'],
            '--dry-run' => true,
        ])->assertExitCode(0);

        $this->assertDatabaseMissing('profiles', [
            'id' => '11111111-1111-1111-1111-111111111111',
        ]);
    }
}
