<?php

namespace App\Modules\Admin\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Modules\Identity\Models\Profile;
use App\Modules\Projects\Models\Project;
use App\Modules\Recordings\Models\Recording;
use App\Modules\Identity\Models\User;
use App\Modules\Recordings\Services\RecordingService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AdminController extends Controller
{
    public function __construct(
        private RecordingService $recordingService,
    ) {}

    public function dashboard(Request $request): View
    {
        return view('web.admin.dashboard', $this->baseData($request, [
            'pageTitle' => 'Administração',
            'pageSubtitle' => 'Usuários, perfis, projetos, gravações e jobs na mesma superfície web.',
            'stats' => [
                'users' => User::query()->count(),
                'profiles' => Profile::query()->count(),
                'projects' => Project::query()->count(),
                'recordings' => Recording::query()->count(),
                'processing' => Recording::query()->whereIn('status', ['uploaded', 'processing_transcript', 'processing_summary', 'indexing'])->count(),
                'failed' => Recording::query()->where('status', 'failed')->count(),
            ],
            'recentUsers' => User::query()->with('profile')->orderByDesc('created_at')->limit(6)->get(),
            'recentRecordings' => Recording::query()->with(['project', 'createdByUser'])->orderByDesc('created_at')->limit(6)->get(),
        ]));
    }

    public function users(Request $request): View
    {
        $filters = [
            'query' => trim($request->string('query')->toString()),
            'profile_id' => $request->string('profile_id')->toString(),
            'is_active' => $request->string('is_active')->toString(),
            'edit' => $request->string('edit')->toString(),
        ];

        $query = User::query()->with('profile')->orderByDesc('created_at');

        if ($filters['query'] !== '') {
            $like = '%'.$filters['query'].'%';
            $query->where(function ($builder) use ($like): void {
                $builder->where('email', 'like', $like)
                    ->orWhere('full_name', 'like', $like);
            });
        }

        if ($filters['profile_id'] !== '') {
            $query->where('profile_id', $filters['profile_id']);
        }

        if ($filters['is_active'] !== '') {
            $query->where('is_active', $filters['is_active'] === '1');
        }

        $users = $query->get();
        $editingUser = $filters['edit'] !== '' ? $users->firstWhere('id', $filters['edit']) ?? User::query()->with('profile')->find($filters['edit']) : null;

        return view('web.admin.users.index', $this->baseData($request, [
            'pageTitle' => 'Usuários',
            'pageSubtitle' => 'Diretório de pessoas, perfil efetivo e ativação operacional.',
            'users' => $users,
            'profiles' => Profile::query()->orderBy('name')->get(),
            'filters' => $filters,
            'editingUser' => $editingUser,
        ]));
    }

    public function storeUser(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'email' => 'required|email|unique:users',
            'full_name' => 'required|string|max:255',
            'profile_id' => 'required|uuid|exists:profiles,id',
            'password' => 'required|string|min:8',
            'is_active' => 'nullable|boolean',
        ]);

        User::query()->create([
            'email' => $validated['email'],
            'full_name' => $validated['full_name'],
            'profile_id' => $validated['profile_id'],
            'password' => $validated['password'],
            'is_active' => (bool) ($validated['is_active'] ?? false),
        ]);

        return redirect()->route('workspace.admin.users')->with('status', 'Usuário criado com sucesso.');
    }

    public function updateUser(Request $request, User $user): RedirectResponse
    {
        $validated = $request->validate([
            'email' => 'required|email|unique:users,email,'.$user->id.',id',
            'full_name' => 'required|string|max:255',
            'profile_id' => 'required|uuid|exists:profiles,id',
            'password' => 'nullable|string|min:8',
            'is_active' => 'nullable|boolean',
        ]);

        $payload = [
            'email' => $validated['email'],
            'full_name' => $validated['full_name'],
            'profile_id' => $validated['profile_id'],
            'is_active' => (bool) ($validated['is_active'] ?? false),
        ];

        if (! empty($validated['password'])) {
            $payload['password'] = $validated['password'];
        }

        $user->update($payload);

        return redirect()->route('workspace.admin.users')->with('status', 'Usuário atualizado.');
    }

    public function destroyUser(User $user): RedirectResponse
    {
        $user->delete();

        return redirect()->route('workspace.admin.users')->with('status', 'Usuário removido.');
    }

    public function profiles(Request $request): View
    {
        $filters = [
            'edit' => $request->string('edit')->toString(),
        ];

        $profiles = Profile::query()->withCount('users')->orderBy('name')->get();
        $editingProfile = $filters['edit'] !== '' ? $profiles->firstWhere('id', $filters['edit']) : null;

        return view('web.admin.profiles.index', $this->baseData($request, [
            'pageTitle' => 'Perfis',
            'pageSubtitle' => 'Papéis de acesso, perfis sistêmicos e catálogo de permissões.',
            'profiles' => $profiles,
            'filters' => $filters,
            'editingProfile' => $editingProfile,
        ]));
    }

    public function storeProfile(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'code' => 'required|string|regex:/^[a-z0-9_]+$/|unique:profiles,code',
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
        ]);

        Profile::query()->create($validated + ['is_system' => false]);

        return redirect()->route('workspace.admin.profiles')->with('status', 'Perfil criado com sucesso.');
    }

    public function updateProfile(Request $request, Profile $profile): RedirectResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
        ]);

        $profile->update($validated);

        return redirect()->route('workspace.admin.profiles')->with('status', 'Perfil atualizado.');
    }

    public function destroyProfile(Profile $profile): RedirectResponse
    {
        if ($profile->is_system) {
            return redirect()->route('workspace.admin.profiles')->withErrors([
                'profile' => 'Perfis sistêmicos não podem ser removidos.',
            ]);
        }

        $profile->delete();

        return redirect()->route('workspace.admin.profiles')->with('status', 'Perfil removido.');
    }

    public function projects(Request $request): View
    {
        $filters = [
            'query' => trim($request->string('query')->toString()),
            'status' => $request->string('status')->toString(),
            'edit' => $request->string('edit')->toString(),
        ];

        $query = Project::query()->withCount(['recordings', 'members'])->orderByDesc('created_at');

        if ($filters['query'] !== '') {
            $like = '%'.$filters['query'].'%';
            $query->where(function ($builder) use ($like): void {
                $builder->where('name', 'like', $like)
                    ->orWhere('slug', 'like', $like);
            });
        }

        if ($filters['status'] !== '') {
            $query->where('status', $filters['status']);
        }

        $projects = $query->get();
        $editingProject = $filters['edit'] !== '' ? $projects->firstWhere('id', $filters['edit']) : null;

        return view('web.admin.projects.index', $this->baseData($request, [
            'pageTitle' => 'Projetos',
            'pageSubtitle' => 'Lista, criação, edição e gestão de vínculos operacionais.',
            'projects' => $projects,
            'filters' => $filters,
            'editingProject' => $editingProject,
        ]));
    }

    public function storeProject(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'slug' => 'nullable|string|max:255|unique:projects,slug',
            'status' => 'nullable|in:active,archived',
        ]);

        $name = $validated['name'];
        $slug = $validated['slug'] ?: Str::slug($name).'-'.Str::lower(Str::random(6));

        Project::query()->create([
            'name' => $name,
            'slug' => $slug,
            'status' => $validated['status'] ?? 'active',
        ]);

        return redirect()->route('workspace.admin.projects')->with('status', 'Projeto criado com sucesso.');
    }

    public function updateProject(Request $request, Project $project): RedirectResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'slug' => 'required|string|max:255|unique:projects,slug,'.$project->id.',id',
            'status' => 'required|in:active,archived',
        ]);

        $project->update($validated);

        return redirect()->route('workspace.admin.projects')->with('status', 'Projeto atualizado.');
    }

    public function members(Request $request, Project $project): View
    {
        $project->loadCount(['recordings', 'members']);
        $members = $project->members()->with('user.profile')->orderBy('created_at')->get();

        return view('web.admin.projects.members', $this->baseData($request, [
            'pageTitle' => 'Membros do projeto',
            'pageSubtitle' => 'Vínculos de acesso, role por projeto e trilha operacional.',
            'project' => $project,
            'members' => $members,
            'users' => User::query()->with('profile')->orderBy('full_name')->get(),
        ]));
    }

    public function addMember(Request $request, Project $project): RedirectResponse
    {
        $validated = $request->validate([
            'user_id' => 'required|uuid|exists:users,id',
            'role' => 'required|in:owner,member',
        ]);

        $project->members()->updateOrCreate(
            ['user_id' => $validated['user_id']],
            ['role' => $validated['role']],
        );

        return redirect()->route('workspace.admin.projects.members', $project)->with('status', 'Membro vinculado ao projeto.');
    }

    public function removeMember(Project $project, string $user): RedirectResponse
    {
        $project->members()->where('user_id', $user)->delete();

        return redirect()->route('workspace.admin.projects.members', $project)->with('status', 'Membro removido do projeto.');
    }

    public function recordings(Request $request): View
    {
        $filters = [
            'query' => trim($request->string('query')->toString()),
            'project_id' => $request->string('project_id')->toString(),
            'status' => $request->string('status')->toString(),
            'user_id' => $request->string('user_id')->toString(),
            'source_app' => $request->string('source_app')->toString(),
            'platform' => $request->string('platform')->toString(),
        ];

        $query = Recording::query()
            ->with(['createdByUser.profile', 'project', 'summary', 'noteArtifact'])
            ->orderByDesc('created_at');

        if ($filters['project_id'] !== '') {
            if ($filters['project_id'] === 'none') {
                $query->whereNull('project_id');
            } else {
                $query->where('project_id', $filters['project_id']);
            }
        }

        if ($filters['status'] !== '') {
            $query->where('status', $filters['status']);
        }

        if ($filters['user_id'] !== '') {
            $query->where('created_by_user_id', $filters['user_id']);
        }

        $recordings = $query->get();

        if ($filters['query'] !== '') {
            $like = Str::lower($filters['query']);
            $recordings = $recordings->filter(function (Recording $recording) use ($like): bool {
                $haystack = Str::lower(implode(' ', [
                    $recording->title,
                    $recording->summary?->overview ?? '',
                    $recording->noteArtifact?->title ?? '',
                ]));

                return str_contains($haystack, $like)
                    || $recording->transcriptSegments()->where('text', 'like', '%'.$like.'%')->exists();
            })->values();
        }

        if ($filters['source_app'] !== '') {
            $recordings = $recordings->filter(fn (Recording $recording) => data_get($recording->capture_metadata, 'sourceApp') === $filters['source_app'])->values();
        }

        if ($filters['platform'] !== '') {
            $recordings = $recordings->filter(fn (Recording $recording) => data_get($recording->capture_metadata, 'platform') === $filters['platform'])->values();
        }

        return view('web.admin.recordings.index', $this->baseData($request, [
            'pageTitle' => 'Gravações',
            'pageSubtitle' => 'Filtros reais, detalhe administrativo, transcript, exportação e reprocessamento.',
            'recordings' => $recordings,
            'projects' => Project::query()->orderBy('name')->get(),
            'users' => User::query()->with('profile')->orderBy('full_name')->get(),
            'filters' => $filters,
        ]));
    }

    public function recording(Request $request, Recording $recording): View
    {
        $recording->load(['transcriptSegments', 'summary', 'noteArtifact', 'chatSession.messages', 'createdByUser.profile', 'project']);

        return view('web.admin.recordings.show', $this->baseData($request, [
            'pageTitle' => 'Detalhe administrativo',
            'pageSubtitle' => 'Metadados, transcript, summary, action items, erro e reprocessamento.',
            'recording' => $recording,
            'projects' => Project::query()->orderBy('name')->get(),
        ]));
    }

    public function updateRecordingProject(Request $request, Recording $recording): RedirectResponse
    {
        $validated = $request->validate([
            'project_id' => 'nullable|uuid|exists:projects,id',
        ]);

        $recording->update([
            'project_id' => $validated['project_id'] ?? null,
        ]);

        return redirect()->route('workspace.admin.recordings.show', $recording)->with(
            'status',
            ($validated['project_id'] ?? null) ? 'Projeto da gravação atualizado.' : 'Vínculo com projeto removido.',
        );
    }

    public function reprocessRecording(Recording $recording): RedirectResponse
    {
        $this->recordingService->reprocess($recording);

        return back()->with('status', 'Reprocessamento disparado.');
    }

    public function exportRecording(Recording $recording, string $format): StreamedResponse
    {
        abort_unless(in_array($format, ['txt', 'md'], true), 404);

        $artifact = $this->recordingService->export($recording, $format);

        return response()->streamDownload(function () use ($artifact): void {
            echo $artifact['body'];
        }, $artifact['file_name'], [
            'Content-Type' => $artifact['content_type'],
        ]);
    }

    public function jobs(Request $request): View
    {
        $filters = [
            'query' => trim($request->string('query')->toString()),
            'project_id' => $request->string('project_id')->toString(),
            'status' => $request->string('status')->toString(),
            'user_id' => $request->string('user_id')->toString(),
            'source_app' => $request->string('source_app')->toString(),
            'platform' => $request->string('platform')->toString(),
        ];

        $query = Recording::query()
            ->with(['project', 'createdByUser'])
            ->orderByDesc('created_at');

        if ($filters['project_id'] !== '') {
            if ($filters['project_id'] === 'none') {
                $query->whereNull('project_id');
            } else {
                $query->where('project_id', $filters['project_id']);
            }
        }

        if ($filters['status'] !== '') {
            $query->where('status', $filters['status']);
        }

        if ($filters['user_id'] !== '') {
            $query->where('created_by_user_id', $filters['user_id']);
        }

        $jobs = $query->get();

        if ($filters['query'] !== '') {
            $like = Str::lower($filters['query']);
            $jobs = $jobs->filter(function (Recording $recording) use ($like): bool {
                return str_contains(Str::lower($recording->title), $like)
                    || str_contains(Str::lower((string) $recording->transcription_job_id), $like)
                    || str_contains(Str::lower((string) $recording->last_error), $like);
            })->values();
        }

        if ($filters['source_app'] !== '') {
            $jobs = $jobs->filter(fn (Recording $recording) => data_get($recording->capture_metadata, 'sourceApp') === $filters['source_app'])->values();
        }

        if ($filters['platform'] !== '') {
            $jobs = $jobs->filter(fn (Recording $recording) => data_get($recording->capture_metadata, 'platform') === $filters['platform'])->values();
        }

        return view('web.admin.jobs.index', $this->baseData($request, [
            'pageTitle' => 'Jobs operacionais',
            'pageSubtitle' => 'Monitoramento de provider, job id, timestamps e erros do pipeline.',
            'jobs' => $jobs,
            'projects' => Project::query()->orderBy('name')->get(),
            'users' => User::query()->with('profile')->orderBy('full_name')->get(),
            'filters' => $filters,
        ]));
    }

    private function baseData(Request $request, array $data = []): array
    {
        return array_merge([
            'brandName' => config('app.name', 'GravAção'),
            'currentUser' => $request->user(),
            'adminStats' => [
                'users' => User::query()->count(),
                'profiles' => Profile::query()->count(),
                'projects' => Project::query()->count(),
                'recordings' => Recording::query()->count(),
            ],
        ], $data);
    }
}
