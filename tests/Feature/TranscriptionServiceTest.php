<?php

namespace Tests\Feature;

use App\Modules\Identity\Models\Profile;
use App\Modules\Recordings\Models\Recording;
use App\Modules\Identity\Models\User;
use App\Modules\Ai\Services\TranscriptionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Tests\TestCase;

class TranscriptionServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_submit_marks_recording_as_failed_when_assemblyai_is_not_configured(): void
    {
        Storage::fake('recordings');

        config()->set('services.assemblyai.api_key', null);

        $user = $this->createUser();
        $recording = Recording::query()->create([
            'user_id' => $user->id,
            'created_by_user_id' => $user->id,
            'title' => 'Audio sem AssemblyAI',
            'source_type' => 'upload',
            'status' => 'processing_transcript',
            'audio_path' => 'recordings/audio.wav',
        ]);

        Storage::disk('recordings')->put($recording->audio_path, 'fake-audio');

        app(TranscriptionService::class)->submit($recording);

        $recording->refresh();

        $this->assertSame('failed', $recording->status);
        $this->assertSame('AssemblyAI API key not configured.', $recording->last_error);
        $this->assertNull($recording->transcription_provider);
        $this->assertNull($recording->transcription_job_id);
        $this->assertNull($recording->transcription_started_at);
    }

    public function test_assemblyai_webhook_rejects_invalid_secret(): void
    {
        config()->set('services.assemblyai.webhook_secret', 'expected-secret');

        $response = $this->postJson('/api/webhooks/assemblyai', [
            'transcript_id' => 'transcript-test',
            'status' => 'completed',
        ], [
            'X-AssemblyAI-Webhook-Secret' => 'wrong-secret',
        ]);

        $response->assertForbidden();
    }

    public function test_assemblyai_webhook_accepts_configured_secret(): void
    {
        config()->set('services.assemblyai.webhook_secret', 'expected-secret');

        $response = $this->postJson('/api/webhooks/assemblyai', [
            'status' => 'completed',
        ], [
            'X-AssemblyAI-Webhook-Secret' => 'expected-secret',
        ]);

        $response->assertOk()
            ->assertJsonPath('status', 'ok');
    }

    private function createUser(): User
    {
        $profile = Profile::query()->create([
            'code' => 'user',
            'name' => 'Usuario',
            'description' => 'Perfil de teste',
            'is_system' => true,
        ]);

        return User::query()->create([
            'email' => 'user-'.Str::uuid().'@example.com',
            'full_name' => 'Usuario Teste',
            'profile_id' => $profile->id,
            'password' => 'secret-1234',
            'is_active' => true,
        ]);
    }
}
