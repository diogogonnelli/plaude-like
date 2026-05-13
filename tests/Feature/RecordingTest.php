<?php

namespace Tests\Feature;

use App\Modules\Identity\Models\Profile;
use App\Modules\Projects\Models\Project;
use App\Modules\Recordings\Models\Recording;
use App\Modules\Identity\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Tests\TestCase;

class RecordingTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private string $token;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(\Database\Seeders\ProfileSeeder::class);

        $profile = Profile::where('code', 'user')->first();
        $this->user = User::create([
            'email' => 'recorder@sonora.app',
            'full_name' => 'Recorder',
            'profile_id' => $profile->id,
            'password' => 'password',
            'is_active' => true,
        ]);
        $this->token = $this->user->createToken('test')->plainTextToken;
    }

    private function authHeaders(): array
    {
        return [
            'Authorization' => "Bearer {$this->token}",
            'Accept' => 'application/json',
        ];
    }

    public function test_list_recordings_empty(): void
    {
        $response = $this->getJson('/api/recordings', $this->authHeaders());

        $response->assertOk()
            ->assertJsonPath('data', []);
    }

    public function test_create_recording(): void
    {
        $response = $this->postJson('/api/recordings', [
            'title' => 'Reunião de teste',
            'source_type' => 'microphone',
        ], $this->authHeaders());

        $response->assertCreated()
            ->assertJsonPath('data.title', 'Reunião de teste')
            ->assertJsonPath('data.status', 'uploaded');
    }

    public function test_create_recording_rejects_project_when_user_is_not_a_member(): void
    {
        $project = $this->createProject('Projeto privado');

        $response = $this->postJson('/api/recordings', [
            'title' => 'Tentativa fora do projeto',
            'project_id' => $project->id,
            'source_type' => 'upload',
        ], $this->authHeaders());

        $response->assertForbidden();
        $this->assertDatabaseMissing('recordings', [
            'title' => 'Tentativa fora do projeto',
        ]);
    }

    public function test_get_recording_detail(): void
    {
        $recording = Recording::create([
            'user_id' => $this->user->id,
            'created_by_user_id' => $this->user->id,
            'title' => 'Test Detail',
            'source_type' => 'upload',
            'status' => 'ready',
        ]);

        $response = $this->getJson("/api/recordings/{$recording->id}", $this->authHeaders());

        $response->assertOk()
            ->assertJsonPath('data.title', 'Test Detail');
    }

    public function test_update_recording_title(): void
    {
        $recording = Recording::create([
            'user_id' => $this->user->id,
            'created_by_user_id' => $this->user->id,
            'title' => 'Original',
            'source_type' => 'upload',
            'status' => 'uploaded',
        ]);

        $response = $this->patchJson("/api/recordings/{$recording->id}", [
            'title' => 'Updated Title',
        ], $this->authHeaders());

        $response->assertOk()
            ->assertJsonPath('data.title', 'Updated Title');
    }

    public function test_update_recording_rejects_project_when_user_is_not_a_member(): void
    {
        $recording = Recording::create([
            'user_id' => $this->user->id,
            'created_by_user_id' => $this->user->id,
            'title' => 'Original',
            'source_type' => 'upload',
            'status' => 'uploaded',
        ]);
        $project = $this->createProject('Projeto alheio');

        $response = $this->patchJson("/api/recordings/{$recording->id}", [
            'project_id' => $project->id,
        ], $this->authHeaders());

        $response->assertForbidden();

        $recording->refresh();
        $this->assertNull($recording->project_id);
    }

    public function test_delete_recording(): void
    {
        $recording = Recording::create([
            'user_id' => $this->user->id,
            'created_by_user_id' => $this->user->id,
            'title' => 'To Delete',
            'source_type' => 'upload',
            'status' => 'uploaded',
        ]);

        $response = $this->deleteJson("/api/recordings/{$recording->id}", [], $this->authHeaders());

        $response->assertNoContent();
        $this->assertDatabaseMissing('recordings', ['id' => $recording->id]);
    }

    public function test_upload_recording_with_file(): void
    {
        Storage::fake('recordings');

        $recording = Recording::create([
            'user_id' => $this->user->id,
            'created_by_user_id' => $this->user->id,
            'title' => 'Uploaded Recording',
            'source_type' => 'upload',
            'status' => 'uploaded',
        ]);

        $file = UploadedFile::fake()->create('audio.wav', 1024);

        $response = $this->post("/api/recordings/{$recording->id}/upload", [
            'audio' => $file,
        ], $this->authHeaders());

        $response->assertOk()
            ->assertJsonPath('data.title', 'Uploaded Recording');

        $recording->refresh();

        $this->assertNotNull($recording->audio_path);
        Storage::disk('recordings')->assertExists($recording->audio_path);
    }

    public function test_cannot_access_other_users_recording(): void
    {
        $otherProfile = Profile::where('code', 'user')->first();
        $otherUser = User::create([
            'email' => 'other@sonora.app',
            'full_name' => 'Other',
            'profile_id' => $otherProfile->id,
            'password' => 'password',
            'is_active' => true,
        ]);

        $recording = Recording::create([
            'user_id' => $otherUser->id,
            'created_by_user_id' => $otherUser->id,
            'title' => 'Private',
            'source_type' => 'upload',
            'status' => 'ready',
        ]);

        $response = $this->patchJson("/api/recordings/{$recording->id}", [
            'title' => 'Hacked',
        ], $this->authHeaders());

        $response->assertForbidden();
    }

    private function createProject(string $name): Project
    {
        return Project::create([
            'name' => $name,
            'slug' => Str::slug($name).'-'.Str::lower(Str::random(8)),
            'status' => 'active',
        ]);
    }
}
