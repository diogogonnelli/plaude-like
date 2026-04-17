<?php

namespace Tests\Feature;

use App\Providers\AppServiceProvider;
use App\Support\PublicAssetUrl;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\URL;
use Tests\TestCase;

class WebAccessTest extends TestCase
{
    public function test_guest_root_redirects_to_login(): void
    {
        $response = $this->get('/');

        $response->assertRedirect('/login');
    }

    public function test_guest_root_redirect_uses_https_when_request_is_forwarded_over_tls(): void
    {
        $response = $this->withServerVariables([
            'REMOTE_ADDR' => '10.0.0.10',
            'HTTP_HOST' => 'sonora.spotpromo.com.br',
            'HTTP_X_FORWARDED_FOR' => '203.0.113.25',
            'HTTP_X_FORWARDED_HOST' => 'sonora.spotpromo.com.br',
            'HTTP_X_FORWARDED_PORT' => '443',
            'HTTP_X_FORWARDED_PROTO' => 'https',
        ])->get('http://sonora.spotpromo.com.br/');

        $response->assertRedirect('https://sonora.spotpromo.com.br/login');
    }

    public function test_guest_root_redirect_uses_https_in_production_even_without_forwarded_proto(): void
    {
        config(['app.url' => 'https://sonora.spotpromo.com.br']);

        $originalEnvironment = $this->app['env'];
        $this->app['env'] = 'production';
        URL::forceScheme(null);
        (new AppServiceProvider($this->app))->boot();

        try {
            $response = $this->withServerVariables([
                'HTTP_HOST' => 'sonora.spotpromo.com.br',
            ])->get('http://sonora.spotpromo.com.br/');

            $response->assertRedirect('https://sonora.spotpromo.com.br/login');
        } finally {
            URL::forceScheme(null);
            $this->app['env'] = $originalEnvironment;
        }
    }

    public function test_login_page_renders(): void
    {
        $this->fakeBuiltAssets();

        $response = $this->get('/login');

        $response->assertOk()
            ->assertSee('Sonora');
    }

    public function test_root_index_wrapper_exists(): void
    {
        $this->assertFileExists(base_path('index.php'));
        $this->assertStringContainsString(
            "require __DIR__.'/public/index.php';",
            File::get(base_path('index.php'))
        );
    }

    public function test_login_page_uses_public_prefixed_build_asset_urls_when_request_comes_from_root_wrapper(): void
    {
        config(['app.public_prefix' => '']);
        $this->fakeBuiltAssets([
            'resources/css/app.css' => ['file' => 'assets/app-test.css'],
            'resources/js/app.js' => ['file' => 'assets/app-test.js'],
        ]);

        $response = $this->withServerVariables([
            'SCRIPT_FILENAME' => base_path('index.php'),
        ])->get('/login');

        $response->assertOk()
            ->assertSee('/public/build/assets/app-test.css', false)
            ->assertSee('/public/build/assets/app-test.js', false);
    }

    public function test_login_page_uses_direct_build_asset_urls_when_request_comes_from_public_entry(): void
    {
        config(['app.public_prefix' => '']);
        $this->fakeBuiltAssets([
            'resources/css/app.css' => ['file' => 'assets/app-test.css'],
            'resources/js/app.js' => ['file' => 'assets/app-test.js'],
        ]);

        $response = $this->withServerVariables([
            'SCRIPT_FILENAME' => public_path('index.php'),
        ])->get('/login');

        $response->assertOk()
            ->assertSee('/build/assets/app-test.css', false)
            ->assertSee('/build/assets/app-test.js', false);
    }

    public function test_public_asset_url_prefixes_public_when_request_uses_root_wrapper(): void
    {
        $this->withServerVariables([
            'SCRIPT_FILENAME' => base_path('index.php'),
        ])->get('/login');

        $this->assertSame('/public/build/app.js', PublicAssetUrl::toUrl('build/app.js'));
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
