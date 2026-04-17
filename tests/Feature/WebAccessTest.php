<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\File;
use Tests\TestCase;

class WebAccessTest extends TestCase
{
    public function test_guest_root_redirects_to_login(): void
    {
        $response = $this->get('/');

        $response->assertRedirect('/login');
    }

    public function test_login_page_renders(): void
    {
        $this->fakeBuiltAssets();

        $response = $this->get('/login');

        $response->assertOk()
            ->assertSee('Sonora');
    }

    public function test_login_page_uses_root_public_build_asset_urls(): void
    {
        config(['app.public_prefix' => '']);
        $this->fakeBuiltAssets([
            'resources/css/app.css' => ['file' => 'assets/app-test.css'],
            'resources/js/app.js' => ['file' => 'assets/app-test.js'],
        ]);

        $response = $this->get('/login');

        $response->assertOk()
            ->assertSee('/build/assets/app-test.css', false)
            ->assertSee('/build/assets/app-test.js', false);
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
