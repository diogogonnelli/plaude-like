<?php

namespace Tests\Feature;

use App\Models\Profile;
use App\Models\User;
use App\Support\PublicAssetUrl;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;
use Tests\TestCase;

class WebAccessTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_root_renders_login_page(): void
    {
        $this->fakeBuiltAssets();

        $response = $this->get('/');

        $response->assertOk()
            ->assertSee('Sonora')
            ->assertSee('max-w-[448px]', false)
            ->assertSee('Entrar');
    }

    public function test_guest_login_route_redirects_to_root(): void
    {
        $response = $this->get('/login');

        $response->assertRedirect('/');
    }

    public function test_guest_can_authenticate_from_root_form(): void
    {
        $user = $this->createUserWithProfile('user', [
            'email' => 'user@example.com',
            'password' => 'secret-1234',
        ]);
        $this->fakeBuiltAssets();

        $response = $this->post('/', [
            'intent' => 'login',
            'email' => $user->email,
            'password' => 'secret-1234',
        ]);

        $response->assertRedirect('/');
        $this->assertAuthenticatedAs($user);
    }

    public function test_authenticated_root_renders_one_page_dashboard_for_regular_user(): void
    {
        $user = $this->createUserWithProfile('user');
        $this->actingAs($user);
        $this->fakeBuiltAssets();

        $response = $this->get('/');

        $response->assertOk()
            ->assertSee('Resumo')
            ->assertSee('Gravacoes Recentes')
            ->assertSee('Projetos')
            ->assertDontSee('Administracao');
    }

    public function test_authenticated_root_renders_admin_navigation_for_admin_user(): void
    {
        $user = $this->createUserWithProfile('admin');
        $this->actingAs($user);
        $this->fakeBuiltAssets();

        $response = $this->get('/');

        $response->assertOk()
            ->assertSee('Administracao')
            ->assertSee('Usuarios')
            ->assertSee('Perfis');
    }

    public function test_root_index_wrapper_exists(): void
    {
        $this->assertFileExists(base_path('index.php'));
        $this->assertStringContainsString(
            "require __DIR__.'/public/index.php';",
            File::get(base_path('index.php'))
        );
    }

    public function test_root_page_uses_public_prefixed_build_asset_urls_when_request_comes_from_root_wrapper(): void
    {
        $this->fakeBuiltAssets([
            'resources/css/app.css' => ['file' => 'assets/app-test.css'],
            'resources/js/app.js' => ['file' => 'assets/app-test.js'],
        ]);

        $response = $this->withServerVariables([
            'SCRIPT_FILENAME' => base_path('index.php'),
        ])->get('/');

        $response->assertOk()
            ->assertSee('/public/build/assets/app-test.css', false)
            ->assertSee('/public/build/assets/app-test.js', false);
    }

    public function test_root_page_uses_direct_build_asset_urls_when_request_comes_from_public_entry(): void
    {
        $this->fakeBuiltAssets([
            'resources/css/app.css' => ['file' => 'assets/app-test.css'],
            'resources/js/app.js' => ['file' => 'assets/app-test.js'],
        ]);

        $response = $this->withServerVariables([
            'SCRIPT_FILENAME' => public_path('index.php'),
        ])->get('/');

        $response->assertOk()
            ->assertSee('/build/assets/app-test.css', false)
            ->assertSee('/build/assets/app-test.js', false);
    }

    public function test_public_asset_url_prefixes_public_when_request_uses_root_wrapper(): void
    {
        $this->fakeBuiltAssets();

        $this->withServerVariables([
            'SCRIPT_FILENAME' => base_path('index.php'),
        ])->get('/');

        $this->assertSame('/public/build/app.js', PublicAssetUrl::toUrl('build/app.js'));
    }

    private function createUserWithProfile(string $profileCode, array $overrides = []): User
    {
        $profile = Profile::query()->firstOrCreate(
            ['code' => $profileCode],
            [
                'name' => $profileCode === 'admin' ? 'Administrador' : 'Usuario',
                'description' => 'Perfil de teste',
                'is_system' => true,
            ]
        );

        return User::query()->create(array_merge([
            'email' => $profileCode.'-'.Str::uuid().'@example.com',
            'full_name' => ucfirst($profileCode).' Teste',
            'profile_id' => $profile->id,
            'password' => 'secret-1234',
            'is_active' => true,
        ], $overrides));
    }

    private function fakeBuiltAssets(?array $manifest = null): void
    {
        $manifest ??= [
            'resources/css/app.css' => ['file' => 'assets/app.css'],
            'resources/js/app.js' => ['file' => 'assets/app.js'],
        ];

        $buildPath = public_path('build');
        $manifestPath = $buildPath.'/manifest.json';
        $hotPath = public_path('hot');

        $originalManifest = File::exists($manifestPath) ? File::get($manifestPath) : null;
        $originalHot = File::exists($hotPath) ? File::get($hotPath) : null;

        File::ensureDirectoryExists($buildPath);
        File::put($manifestPath, json_encode($manifest, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));

        if (File::exists($hotPath)) {
            File::delete($hotPath);
        }

        $this->beforeApplicationDestroyed(function () use ($manifestPath, $originalManifest, $hotPath, $originalHot): void {
            if ($originalManifest === null) {
                File::delete($manifestPath);
            } else {
                File::put($manifestPath, $originalManifest);
            }

            if ($originalHot === null) {
                File::delete($hotPath);
            } else {
                File::put($hotPath, $originalHot);
            }
        });
    }
}
