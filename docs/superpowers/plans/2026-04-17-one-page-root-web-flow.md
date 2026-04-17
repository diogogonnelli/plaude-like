# One-Page Root Web Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the Laravel web experience to a single root URL (`/`) that serves login for guests and a one-page authenticated dashboard for signed-in users, with the admin menu/content visible only to users whose profile code is `admin`.

**Architecture:** Keep the existing API surface intact and collapse the web surface to a single Blade-driven entry point. The root controller will branch on authentication state, the authenticated dashboard will render multiple sections inside one view, and the deploy smoke test will validate `/` instead of `/login`.

**Tech Stack:** Laravel 12, Blade, PHPUnit feature tests, Bitbucket Pipelines shell deploy script

---

### Task 1: Capture the new root-only web behavior in feature tests

**Files:**
- Modify: `tests/Feature/WebAccessTest.php`
- Test: `tests/Feature/WebAccessTest.php`

- [ ] **Step 1: Write the failing tests**

```php
public function test_guest_root_renders_login_page(): void
{
    $this->fakeBuiltAssets();

    $response = $this->get('/');

    $response->assertOk()
        ->assertSee('Sonora')
        ->assertSee('Entrar');
}

public function test_guest_login_route_redirects_to_root(): void
{
    $response = $this->get('/login');

    $response->assertRedirect('/');
}

public function test_authenticated_root_renders_one_page_dashboard(): void
{
    $user = $this->createUserWithProfile('user');
    $this->actingAs($user);
    $this->fakeBuiltAssets();

    $response = $this->get('/');

    $response->assertOk()
        ->assertSee('Resumo')
        ->assertSee('Gravações Recentes')
        ->assertDontSee('Administração');
}

public function test_admin_root_shows_admin_navigation_and_sections(): void
{
    $user = $this->createUserWithProfile('admin');
    $this->actingAs($user);
    $this->fakeBuiltAssets();

    $response = $this->get('/');

    $response->assertOk()
        ->assertSee('Administração')
        ->assertSee('Usuários')
        ->assertSee('Perfis');
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `php artisan test tests/Feature/WebAccessTest.php`
Expected: FAIL because `/` still redirects for guests, `/login` still renders directly, and the dashboard/admin sections do not yet exist in the expected form.

- [ ] **Step 3: Add test helpers for profile-backed users**

```php
private function createUserWithProfile(string $profileCode): User
{
    $profile = Profile::query()->firstOrCreate(
        ['code' => $profileCode],
        [
            'name' => $profileCode === 'admin' ? 'Administrador' : 'Usuário',
            'description' => 'Perfil de teste',
            'is_system' => true,
        ]
    );

    return User::query()->create([
        'email' => $profileCode.'-'.Str::uuid().'@example.com',
        'full_name' => ucfirst($profileCode).' Teste',
        'profile_id' => $profile->id,
        'password' => 'password',
        'is_active' => true,
    ]);
}
```

- [ ] **Step 4: Run tests again to keep the failure focused on behavior**

Run: `php artisan test tests/Feature/WebAccessTest.php`
Expected: FAIL on assertions about route behavior or rendered content, not on missing models/helpers.

### Task 2: Collapse the web routes and controller behavior to the root entry point

**Files:**
- Modify: `routes/web.php`
- Modify: `app/Http/Controllers/Web/AuthController.php`
- Modify: `app/Http/Controllers/Web/DashboardController.php`
- Test: `tests/Feature/WebAccessTest.php`

- [ ] **Step 1: Write the minimal route/controller changes**

```php
Route::get('/', [DashboardController::class, 'index'])->name('home');
Route::get('/login', fn () => redirect()->route('home'));
Route::post('/login', [AuthController::class, 'login'])->name('login');
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');
```

```php
public function index(Request $request): View
{
    if (! $request->user()) {
        return view('home', [
            'mode' => 'guest',
            'recordings' => collect(),
            'user' => null,
        ]);
    }

    $user = $request->user()->loadMissing('profile');
    $recordings = $user->recordings()
        ->with(['summary', 'noteArtifact', 'project'])
        ->orderByDesc('created_at')
        ->limit(10)
        ->get();

    return view('home', [
        'mode' => 'auth',
        'recordings' => $recordings,
        'user' => $user,
    ]);
}
```

- [ ] **Step 2: Run the targeted tests**

Run: `php artisan test tests/Feature/WebAccessTest.php`
Expected: Some assertions still fail because the unified view has not yet been updated.

### Task 3: Replace the dashboard/login split with a single one-page Blade view

**Files:**
- Create: `resources/views/home.blade.php`
- Modify: `resources/views/layouts/app.blade.php`
- Test: `tests/Feature/WebAccessTest.php`

- [ ] **Step 1: Build the unified page with guest/auth branches**

```blade
@extends('layouts.base')

@section('body')
@if ($mode === 'guest')
    {{-- login card --}}
@else
    {{-- summary, recordings, projects placeholder, admin section guarded by $user->isAdmin() --}}
@endif
@endsection
```

- [ ] **Step 2: Make the authenticated layout explicitly one-page**

```blade
<nav class="flex-1 px-md space-y-xs">
    <a href="#resumo">Resumo</a>
    <a href="#gravacoes">Gravações</a>
    <a href="#projetos">Projetos</a>
    @if($user->isAdmin())
        <a href="#administracao">Administração</a>
    @endif
</nav>
```

- [ ] **Step 3: Run the targeted tests**

Run: `php artisan test tests/Feature/WebAccessTest.php`
Expected: PASS for the root rendering and admin visibility assertions.

### Task 4: Align deploy smoke checks with the root-only web contract

**Files:**
- Modify: `bitbucket-pipelines.yml`
- Modify: `DEPLOY.md`
- Test: `bitbucket-pipelines.yml` smoke section via local inspection

- [ ] **Step 1: Update the smoke test to validate `/` instead of `/login`**

```bash
curl -fsS "$PUBLIC_BASE_URL/" -o "$HOME_HTML" || {
  log "ERROR: smoke check falhou em $PUBLIC_BASE_URL/."
  exit 32
}

if ! grep -q '/public/build/' "$HOME_HTML"; then
  log "ERROR: / nao esta referenciando assets em /public/build/."
  rm -f "$HOME_HTML"
  exit 34
fi
```

- [ ] **Step 2: Remove the redirect-specific assertions from the deploy script**

```bash
# remove / -> /login redirect expectation
# keep manifest and /api/health checks
```

- [ ] **Step 3: Refresh the deploy documentation**

```md
- `https://<dominio>/` responde `200`
- `/` renderiza o login para guests e a área principal para usuários autenticados
- `/public/build/manifest.json` responde `200`
- `/api/health` responde `200`
```

- [ ] **Step 4: Run focused verification**

Run: `php artisan test tests/Feature/WebAccessTest.php`
Expected: PASS

Run: `git diff -- bitbucket-pipelines.yml DEPLOY.md`
Expected: Smoke checks now describe the root-only flow clearly.
