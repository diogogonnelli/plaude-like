<?php

namespace Tests\Feature;

use App\Models\Profile;
use App\Models\Project;
use App\Models\Recording;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
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
        return ['Authorization' => "Bearer {$this->token}"];
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
            'source_type' => 'mic_capture',
        ], $this->authHeaders());

        $response->assertCreated()
            ->assertJsonPath('data.title', 'Reunião de teste')
            ->assertJsonPath('data.status', 'uploaded');
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

        $response->assertOk();
        $this->assertDatabaseMissing('recordings', ['id' => $recording->id]);
    }

    public function test_upload_recording_with_file(): void
    {
        Storage::fake('recordings');

        $file = UploadedFile::fake()->create('audio.wav', 1024);

        $response = $this->postJson('/api/recordings/upload', [
            'title' => 'Uploaded Recording',
            'source_type' => 'upload',
            'file' => $file,
        ], $this->authHeaders());

        $response->assertCreated()
            ->assertJsonPath('data.title', 'Uploaded Recording');
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
}
