<?php

namespace Tests\Feature;

use App\Models\Profile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(\Database\Seeders\ProfileSeeder::class);
    }

    private function createUser(string $email = 'test@sonora.app', string $password = 'password'): User
    {
        $profile = Profile::where('code', 'user')->first();

        return User::create([
            'email' => $email,
            'full_name' => 'Test User',
            'profile_id' => $profile->id,
            'password' => $password,
            'is_active' => true,
        ]);
    }

    public function test_health_endpoint_returns_ok(): void
    {
        $response = $this->getJson('/api/health');

        $response->assertOk()
            ->assertJson(['status' => 'ok']);
    }

    public function test_login_with_valid_credentials(): void
    {
        $this->createUser();

        $response = $this->postJson('/api/auth/login', [
            'email' => 'test@sonora.app',
            'password' => 'password',
            'device_name' => 'phpunit',
        ]);

        $response->assertOk()
            ->assertJsonStructure([
                'data' => ['token', 'user' => ['id', 'email', 'full_name']],
            ]);
    }

    public function test_login_with_invalid_credentials(): void
    {
        $this->createUser();

        $response = $this->postJson('/api/auth/login', [
            'email' => 'test@sonora.app',
            'password' => 'wrong',
            'device_name' => 'phpunit',
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);
    }

    public function test_me_returns_authenticated_user(): void
    {
        $user = $this->createUser();
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->getJson('/api/auth/me', [
            'Authorization' => "Bearer {$token}",
        ]);

        $response->assertOk()
            ->assertJsonPath('data.email', 'test@sonora.app');
    }

    public function test_unauthenticated_request_returns_401(): void
    {
        $response = $this->getJson('/api/recordings');

        $response->assertUnauthorized();
    }

    public function test_logout_revokes_token(): void
    {
        $user = $this->createUser();
        $token = $user->createToken('test')->plainTextToken;
        [$tokenId] = explode('|', $token, 2);

        $this->assertNotNull(PersonalAccessToken::find($tokenId));

        $this->postJson('/api/auth/logout', [], [
            'Authorization' => "Bearer {$token}",
        ])->assertOk();

        $this->assertNull(PersonalAccessToken::find($tokenId));
    }
}
