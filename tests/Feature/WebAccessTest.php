<?php

namespace Tests\Feature;

use App\Modules\Chat\Models\ChatMessage;
use App\Modules\Chat\Models\ChatSession;
use App\Modules\Recordings\Models\NoteArtifact;
use App\Modules\Identity\Models\Profile;
use App\Modules\Projects\Models\Project;
use App\Modules\Recordings\Models\Recording;
use App\Modules\Recordings\Models\Summary;
use App\Modules\Recordings\Models\TranscriptSegment;
use App\Modules\Identity\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Tests\TestCase;

class WebAccessTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_root_renders_new_login_page(): void
    {
        $this->fakeBuiltAssets();

        $response = $this->get('/');

        $response->assertOk()
            ->assertSee('Entre na sessao')
            ->assertSee('Onde a estrategia')
            ->assertSee('a execucao');
    }

    public function test_guest_login_route_redirects_to_root(): void
    {
        $response = $this->get('/login');

        $response->assertRedirect('/');
    }

    public function test_guest_can_authenticate_from_login_route(): void
    {
        $user = $this->createUserWithProfile('user', [
            'email' => 'user@example.com',
            'password' => 'secret-1234',
        ]);

        $response = $this->post('/login', [
            'email' => $user->email,
            'password' => 'secret-1234',
        ]);

        $response->assertRedirect('/');
        $this->assertAuthenticatedAs($user);
    }

    public function test_authenticated_root_redirects_to_home_route(): void
    {
        $user = $this->createUserWithProfile('user');
        $this->actingAs($user);

        $response = $this->get('/');

        $response->assertRedirect('/home');
    }

    public function test_authenticated_user_can_access_workspace_routes(): void
    {
        $this->fakeBuiltAssets();

        $user = $this->createUserWithProfile('user');
        $project = $this->createProjectForUser($user, 'Projeto Demo');
        $recording = $this->createRecordingForUser($user, $project, 'Ata semanal');

        $this->actingAs($user);

        $this->get('/home')->assertOk()->assertSee('Grave agora. Execute depois.');
        $this->get('/library')->assertOk()->assertSee('Indice de gravacoes');
        $this->get(route('workspace.recordings.show', $recording))->assertOk()->assertSee('Ata semanal');
        $this->get(route('workspace.recordings.chat', $recording))->assertOk()->assertSee('Ata semanal');
        $this->get('/settings')->assertOk()->assertSee('Sessao e organizacao');
    }

    public function test_admin_user_can_access_admin_routes(): void
    {
        $this->fakeBuiltAssets();

        $admin = $this->createUserWithProfile('admin');
        $project = $this->createProjectForUser($admin, 'Projeto Admin');
        $recording = $this->createRecordingForUser($admin, $project, 'Gravacao Admin');

        $this->actingAs($admin);

        $this->get('/admin')->assertOk();
        $this->get('/admin/users')->assertOk();
        $this->get('/admin/profiles')->assertOk();
        $this->get('/admin/projects')->assertOk();
        $this->get(route('workspace.admin.projects.members', $project))->assertOk();
        $this->get('/admin/recordings')->assertOk();
        $this->get(route('workspace.admin.recordings.show', $recording))->assertOk();
        $this->get('/admin/jobs')->assertOk();
    }

    public function test_non_admin_user_is_blocked_from_admin_routes(): void
    {
        $user = $this->createUserWithProfile('user');
        $this->actingAs($user);

        $response = $this->get('/admin');

        $response->assertForbidden();
    }

    public function test_legacy_library_query_redirects_to_new_library_route(): void
    {
        $user = $this->createUserWithProfile('user');
        $this->actingAs($user);

        $response = $this->get('/?tab=library&project=all&status=ready&query=ata');

        $response->assertRedirect('/library?project=all&status=ready&query=ata');
    }

    public function test_legacy_recording_query_redirects_to_new_recording_detail_route(): void
    {
        $user = $this->createUserWithProfile('user');
        $project = $this->createProjectForUser($user, 'Projeto Redirect');
        $recording = $this->createRecordingForUser($user, $project, 'Gravacao Redirect');
        $this->actingAs($user);

        $response = $this->get('/?tab=library&recording='.$recording->id);

        $response->assertRedirect(route('workspace.recordings.show', $recording, false));
    }

    public function test_authenticated_user_can_select_active_project(): void
    {
        $user = $this->createUserWithProfile('user');
        $project = $this->createProjectForUser($user, 'Projeto Ativo');
        $this->actingAs($user);

        $response = $this->post(route('workspace.projects.active'), [
            'project_id' => $project->id,
        ]);

        $response->assertRedirect();
        $response->assertSessionHas('web.active_project_id', $project->id);
    }

    public function test_authenticated_user_can_upload_audio_from_workspace(): void
    {
        Storage::fake('recordings');

        $user = $this->createUserWithProfile('user');
        $project = $this->createProjectForUser($user, 'Projeto Upload');
        $this->actingAs($user);

        $response = $this->post(route('workspace.recordings.upload'), [
            'title' => 'Audio do workspace',
            'source_type' => 'upload',
            'project_id' => $project->id,
            'audio' => UploadedFile::fake()->create('workspace.wav', 256),
        ]);

        $response->assertRedirect();

        $recording = Recording::query()->where('title', 'Audio do workspace')->first();

        $this->assertNotNull($recording);
        $this->assertSame($project->id, $recording->project_id);
        $this->assertNotNull($recording->audio_path);
        Storage::disk('recordings')->assertExists($recording->audio_path);
    }

    public function test_root_page_uses_direct_build_asset_urls(): void
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

    private function createRecordingForUser(User $user, ?Project $project, string $title): Recording
    {
        $recording = Recording::query()->create([
            'user_id' => $user->id,
            'created_by_user_id' => $user->id,
            'project_id' => $project?->id,
            'title' => $title,
            'source_type' => 'upload',
            'status' => 'ready',
            'transcription_provider' => 'mock',
            'transcription_job_id' => 'job-'.Str::lower(Str::random(8)),
            'transcription_started_at' => now()->subMinutes(2),
            'transcription_completed_at' => now()->subMinute(),
        ]);

        Summary::query()->create([
            'recording_id' => $recording->id,
            'overview' => 'Resumo executivo do audio de teste.',
            'chapters' => [
                ['heading' => 'Contexto', 'body' => 'Visao geral do encontro.'],
                ['heading' => 'Proximos passos', 'body' => 'Encaminhamentos combinados.'],
            ],
        ]);

        NoteArtifact::query()->create([
            'recording_id' => $recording->id,
            'title' => 'Nota estruturada',
            'tags' => ['teste'],
            'highlights' => ['Ponto importante 1', 'Ponto importante 2'],
            'action_items' => ['Acao 1', 'Acao 2'],
        ]);

        TranscriptSegment::query()->create([
            'recording_id' => $recording->id,
            'speaker_label' => 'Speaker 1',
            'start_ms' => 0,
            'end_ms' => 12000,
            'text' => 'Trecho inicial do transcript de teste.',
        ]);

        $chatSession = ChatSession::query()->create([
            'recording_id' => $recording->id,
        ]);

        ChatMessage::query()->create([
            'chat_session_id' => $chatSession->id,
            'role' => 'assistant',
            'content' => 'Resposta de exemplo do chat contextual.',
            'citations' => [],
        ]);

        return $recording;
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
