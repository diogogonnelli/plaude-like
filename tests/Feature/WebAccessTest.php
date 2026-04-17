<?php

namespace Tests\Feature;

use App\Models\Profile;
use App\Models\Project;
use App\Models\Recording;
use App\Models\User;
use App\Support\PublicAssetUrl;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;
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
            ->assertSee('Entrar')
            ->assertSee('Fluxo web');
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

        $response->assertRedirect('/?tab=home');
        $this->assertAuthenticatedAs($user);
    }

    public function test_authenticated_root_renders_one_page_dashboard_for_regular_user(): void
    {
        $user = $this->createUserWithProfile('user');
        $project = $this->createProjectForUser($user, 'Projeto Demo');
        Recording::query()->create([
            'user_id' => $user->id,
            'created_by_user_id' => $user->id,
            'project_id' => $project->id,
            'title' => 'Ata da semana',
            'source_type' => 'upload',
            'status' => 'ready',
        ]);
        $this->actingAs($user);
        $this->fakeBuiltAssets();

        $response = $this->get('/');

        $response->assertOk()
            ->assertSee('Biblioteca')
            ->assertSee('Sistema')
            ->assertSee('Iniciar capta')
            ->assertSee('Enviar')
            ->assertDontSee('Administracao');
    }

    public function test_authenticated_root_renders_admin_navigation_for_admin_user(): void
    {
        $user = $this->createUserWithProfile('admin');
        $this->actingAs($user);
        $this->fakeBuiltAssets();

        $response = $this->get('/?tab=admin');

        $response->assertOk()
            ->assertSee('Administracao')
            ->assertSee('Usuarios')
            ->assertSee('Perfis');
    }

    public function test_authenticated_user_can_select_active_project_from_root_shell(): void
    {
        $user = $this->createUserWithProfile('user');
        $project = $this->createProjectForUser($user, 'Projeto Shell');
        $this->actingAs($user);
        $this->fakeBuiltAssets();

        $response = $this->post('/', [
            'intent' => 'select-active-project',
            'project_id' => $project->id,
            'tab' => 'home',
        ]);

        $response->assertRedirect('/?tab=home');
        $response->assertSessionHas('web.active_project_id', $project->id);
    }

    public function test_authenticated_user_can_upload_audio_from_root_shell(): void
    {
        Storage::fake('recordings');

        $user = $this->createUserWithProfile('user');
        $project = $this->createProjectForUser($user, 'Projeto Upload');
        $this->actingAs($user);
        $this->fakeBuiltAssets();

        $response = $this->post('/', [
            'intent' => 'upload-audio',
            'tab' => 'library',
            'title' => 'Audio do front',
            'source_type' => 'upload',
            'project_id' => $project->id,
            'audio' => UploadedFile::fake()->create('front-shell.wav', 256),
        ]);

        $response->assertRedirect();

        $recording = Recording::query()->where('title', 'Audio do front')->first();

        $this->assertNotNull($recording);
        $this->assertSame($project->id, $recording->project_id);
        $this->assertNotNull($recording->audio_path);
        Storage::disk('recordings')->assertExists($recording->audio_path);
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

    private function createProjectForUser(User $user, string $name): Project
    {
        $project = Project::query()->create([
            'name' => $name,
            'slug' => Str::slug($name).'-'.Str::lower((string) Str::uuid()),
            'status' => 'active',
        ]);

        $project->members()->create([
            'user_id' => $user->id,
            'role' => 'owner',
        ]);

        return $project;
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
