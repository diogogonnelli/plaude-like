<?php

namespace Tests\Feature;

use App\Modules\Identity\Models\Profile;
use App\Modules\Identity\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;
    private User $regularUser;
    private string $adminToken;
    private string $userToken;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(\Database\Seeders\ProfileSeeder::class);

        $adminProfile = Profile::where('code', 'admin')->first();
        $userProfile = Profile::where('code', 'user')->first();

        $this->admin = User::create([
            'email' => 'admin@sonora.app',
            'full_name' => 'Admin',
            'profile_id' => $adminProfile->id,
            'password' => 'password',
            'is_active' => true,
        ]);

        $this->regularUser = User::create([
            'email' => 'user@sonora.app',
            'full_name' => 'Regular User',
            'profile_id' => $userProfile->id,
            'password' => 'password',
            'is_active' => true,
        ]);

        $this->adminToken = $this->admin->createToken('test')->plainTextToken;
        $this->userToken = $this->regularUser->createToken('test')->plainTextToken;
    }

    public function test_admin_can_list_users(): void
    {
        $response = $this->getJson('/api/admin/users', [
            'Authorization' => "Bearer {$this->adminToken}",
        ]);

        $response->assertOk()
            ->assertJsonStructure(['data', 'meta']);
    }

    public function test_regular_user_cannot_access_admin(): void
    {
        $response = $this->getJson('/api/admin/users', [
            'Authorization' => "Bearer {$this->userToken}",
        ]);

        $response->assertForbidden();
    }

    public function test_admin_can_create_user(): void
    {
        $userProfile = Profile::where('code', 'user')->first();

        $response = $this->postJson('/api/admin/users', [
            'email' => 'new@sonora.app',
            'full_name' => 'New User',
            'password' => 'securepassword',
            'profile_id' => $userProfile->id,
        ], [
            'Authorization' => "Bearer {$this->adminToken}",
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.email', 'new@sonora.app');
    }

    public function test_admin_can_list_profiles(): void
    {
        $response = $this->getJson('/api/admin/profiles', [
            'Authorization' => "Bearer {$this->adminToken}",
        ]);

        $response->assertOk();
        $this->assertCount(2, $response->json('data'));
    }
}
