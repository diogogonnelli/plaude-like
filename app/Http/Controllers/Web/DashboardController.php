<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\Profile;
use App\Models\Recording;
use App\Models\User;
use App\Services\ChatService;
use App\Services\RecordingService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function __construct(
        private RecordingService $recordingService,
        private ChatService $chatService,
    ) {}

    public function index(Request $request): View
    {
        $user = $request->user();

        if (! $user) {
            return view('home', [
                'user' => null,
                'recordings' => collect(),
                'projects' => collect(),
                'adminOverview' => null,
                'selectedTab' => 'home',
                'activeProject' => null,
                'filters' => [
                    'query' => '',
                    'project' => 'all',
                    'status' => 'all',
                ],
                'recordingBuckets' => [
                    'processing' => collect(),
                    'ready' => collect(),
                    'failed' => collect(),
                ],
                'selectedRecording' => null,
                'summaryStats' => [
                    'total' => 0,
                    'processing' => 0,
                    'failed' => 0,
                    'ready' => 0,
                ],
            ]);
        }

        $user->loadMissing('profile', 'projects');

        $projects = $user->projects()
            ->withCount('recordings')
            ->orderBy('name')
            ->get();

        $selectedTab = $this->normalizeTab($request->string('tab')->toString(), $user->isAdmin());
        $filters = [
            'query' => trim($request->string('query')->toString()),
            'project' => $this->normalizeProjectFilter($request->string('project', 'all')->toString(), $projects),
            'status' => $this->normalizeStatusFilter($request->string('status', 'all')->toString()),
        ];

        $activeProjectId = $this->normalizeActiveProjectId(
            $request->session()->get('web.active_project_id'),
            $projects,
        );

        $request->session()->put('web.active_project_id', $activeProjectId);

        $baseQuery = $user->recordings()
            ->with([
                'project',
                'summary',
                'noteArtifact',
                'transcriptSegments',
                'chatSession.messages',
            ])
            ->orderByDesc('created_at');

        if ($filters['project'] === 'none') {
            $baseQuery->whereNull('project_id');
        } elseif ($filters['project'] !== 'all') {
            $baseQuery->where('project_id', $filters['project']);
        }

        if ($filters['status'] !== 'all') {
            $baseQuery->where('status', $filters['status']);
        }

        if ($filters['query'] !== '') {
            $like = '%'.$filters['query'].'%';
            $baseQuery->where(function ($query) use ($like): void {
                $query->where('title', 'like', $like)
                    ->orWhereHas('summary', fn ($summaryQuery) => $summaryQuery->where('overview', 'like', $like))
                    ->orWhereHas('noteArtifact', fn ($artifactQuery) => $artifactQuery->where('title', 'like', $like));
            });
        }

        $recordings = $baseQuery->limit(60)->get();
        $selectedRecording = $this->resolveSelectedRecording($recordings, $request->string('recording')->toString());
        $statsRecordings = $user->recordings()->get(['status']);

        return view('home', [
            'user' => $user,
            'recordings' => $recordings,
            'projects' => $projects,
            'adminOverview' => $this->adminOverviewFor($user),
            'selectedTab' => $selectedTab,
            'activeProject' => $projects->firstWhere('id', $activeProjectId),
            'filters' => $filters,
            'recordingBuckets' => [
                'processing' => $recordings->whereIn('status', ['uploaded', 'processing_transcript', 'processing_summary', 'indexing'])->values(),
                'ready' => $recordings->where('status', 'ready')->values(),
                'failed' => $recordings->where('status', 'failed')->values(),
            ],
            'selectedRecording' => $selectedRecording,
            'summaryStats' => [
                'total' => $statsRecordings->count(),
                'processing' => $statsRecordings->whereIn('status', ['uploaded', 'processing_transcript', 'processing_summary', 'indexing'])->count(),
                'failed' => $statsRecordings->where('status', 'failed')->count(),
                'ready' => $statsRecordings->where('status', 'ready')->count(),
            ],
        ]);
    }

    public function submit(Request $request): RedirectResponse
    {
        $intent = $request->string('intent')->toString();

        return match ($intent) {
            'login' => $this->login($request),
            'logout' => $this->logout($request),
            'select-active-project' => $this->selectActiveProject($request),
            'create-project' => $this->createProject($request),
            'upload-audio' => $this->uploadAudio($request),
            'update-recording-project' => $this->updateRecordingProject($request),
            'reprocess-recording' => $this->reprocessRecording($request),
            'send-chat' => $this->sendChat($request),
            default => $this->redirectToShell($request)->withErrors([
                'intent' => 'Acao web invalida.',
            ]),
        };
    }

    private function adminOverviewFor(User $user): ?array
    {
        if (! $user->isAdmin()) {
            return null;
        }

        return [
            'usersCount' => User::query()->count(),
            'profilesCount' => Profile::query()->count(),
            'recentUsers' => User::query()
                ->with('profile')
                ->orderByDesc('created_at')
                ->limit(5)
                ->get(),
            'profiles' => Profile::query()
                ->withCount('users')
                ->orderBy('name')
                ->get(),
        ];
    }

    private function login(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (Auth::attempt($credentials, $request->boolean('remember'))) {
            $request->session()->regenerate();

            return $this->redirectToShell($request, ['tab' => 'home']);
        }

        return back()->withErrors([
            'email' => 'Credenciais invalidas.',
        ])->onlyInput('email');
    }

    private function logout(Request $request): RedirectResponse
    {
        if (Auth::check()) {
            Auth::logout();
        }

        $request->session()->forget('web.active_project_id');
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('home');
    }

    private function selectActiveProject(Request $request): RedirectResponse
    {
        $user = $request->user();

        abort_unless($user, 403);

        $projectId = $request->input('project_id');

        if ($projectId === null || $projectId === '') {
            $request->session()->forget('web.active_project_id');
        } else {
            $this->findAccessibleProject($user, $projectId);
            $request->session()->put('web.active_project_id', $projectId);
        }

        return $this->redirectToShell($request)->with('status', 'Projeto ativo atualizado.');
    }

    private function createProject(Request $request): RedirectResponse
    {
        $user = $request->user();

        abort_unless($user, 403);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
        ]);

        $project = Project::query()->create([
            'name' => $validated['name'],
            'slug' => Str::slug($validated['name']).'-'.Str::lower(Str::random(6)),
            'status' => 'active',
        ]);

        $project->members()->create([
            'user_id' => $user->id,
            'role' => 'owner',
        ]);

        $request->session()->put('web.active_project_id', $project->id);

        return $this->redirectToShell($request, [
            'tab' => 'system',
        ])->with('status', 'Projeto criado com sucesso.');
    }

    private function uploadAudio(Request $request): RedirectResponse
    {
        $user = $request->user();

        abort_unless($user, 403);

        $validated = $request->validate([
            'title' => 'nullable|string|max:255',
            'source_type' => 'required|in:microphone,upload',
            'project_id' => 'nullable|uuid',
            'audio' => 'required|file|max:512000',
        ]);

        $projectId = $validated['project_id'] ?? null;
        if ($projectId) {
            $this->findAccessibleProject($user, $projectId);
        }

        $file = $request->file('audio');
        $title = $validated['title'] ?: pathinfo($file->getClientOriginalName(), PATHINFO_FILENAME);

        $recording = $this->recordingService->create($user->id, [
            'project_id' => $projectId,
            'title' => $title,
            'source_type' => $validated['source_type'],
        ]);

        $path = $file->store($recording->id, 'recordings');
        $recording->update(['audio_path' => $path]);

        try {
            $this->recordingService->startProcessing($recording);
            $notice = 'Audio enviado. O processamento foi iniciado.';
        } catch (\Throwable $exception) {
            $recording->update([
                'status' => 'failed',
                'last_error' => $exception->getMessage(),
            ]);
            $notice = 'Audio enviado, mas o processamento falhou ao iniciar.';
        }

        return $this->redirectToShell($request, [
            'tab' => 'library',
            'recording' => $recording->id,
        ])->with('status', $notice);
    }

    private function updateRecordingProject(Request $request): RedirectResponse
    {
        $user = $request->user();

        abort_unless($user, 403);

        $validated = $request->validate([
            'recording_id' => 'required|uuid',
            'project_id' => 'nullable|uuid',
        ]);

        $recording = $this->findAccessibleRecording($user, $validated['recording_id']);
        $projectId = $validated['project_id'] ?? null;

        if ($projectId) {
            $this->findAccessibleProject($user, $projectId);
        }

        $recording->update(['project_id' => $projectId]);

        return $this->redirectToShell($request, [
            'tab' => 'library',
            'recording' => $recording->id,
        ])->with('status', 'Projeto da gravacao atualizado.');
    }

    private function reprocessRecording(Request $request): RedirectResponse
    {
        $user = $request->user();

        abort_unless($user, 403);

        $validated = $request->validate([
            'recording_id' => 'required|uuid',
        ]);

        $recording = $this->findAccessibleRecording($user, $validated['recording_id']);
        $this->recordingService->reprocess($recording);

        return $this->redirectToShell($request, [
            'tab' => 'library',
            'recording' => $recording->id,
        ])->with('status', 'Reprocessamento iniciado.');
    }

    private function sendChat(Request $request): RedirectResponse
    {
        $user = $request->user();

        abort_unless($user, 403);

        $validated = $request->validate([
            'recording_id' => 'required|uuid',
            'message' => 'required|string|max:4000',
        ]);

        $recording = $this->findAccessibleRecording($user, $validated['recording_id']);

        try {
            $this->chatService->send($recording, $validated['message']);

            return $this->redirectToShell($request, [
                'tab' => 'library',
                'recording' => $recording->id,
            ])->with('status', 'Mensagem enviada ao chat da gravacao.');
        } catch (\Throwable $exception) {
            return $this->redirectToShell($request, [
                'tab' => 'library',
                'recording' => $recording->id,
            ])->withErrors([
                'chat' => 'Nao foi possivel responder ao chat desta gravacao.',
            ]);
        }
    }

    private function normalizeTab(string $tab, bool $isAdmin): string
    {
        $allowed = ['home', 'library', 'system'];

        if ($isAdmin) {
            $allowed[] = 'admin';
        }

        return in_array($tab, $allowed, true) ? $tab : 'home';
    }

    private function normalizeProjectFilter(string $projectFilter, $projects): string
    {
        if ($projectFilter === 'all' || $projectFilter === 'none') {
            return $projectFilter;
        }

        return $projects->contains('id', $projectFilter) ? $projectFilter : 'all';
    }

    private function normalizeStatusFilter(string $status): string
    {
        $allowed = ['all', 'uploaded', 'processing_transcript', 'processing_summary', 'indexing', 'ready', 'failed'];

        return in_array($status, $allowed, true) ? $status : 'all';
    }

    private function normalizeActiveProjectId(mixed $activeProjectId, $projects): ?string
    {
        if (! is_string($activeProjectId) || ! $projects->contains('id', $activeProjectId)) {
            return null;
        }

        return $activeProjectId;
    }

    private function resolveSelectedRecording($recordings, string $selectedRecordingId): ?Recording
    {
        if ($selectedRecordingId === '') {
            return null;
        }

        return $recordings->firstWhere('id', $selectedRecordingId);
    }

    private function redirectToShell(Request $request, array $overrides = []): RedirectResponse
    {
        $query = array_merge([
            'tab' => $request->input('tab', $request->query('tab', 'home')),
            'recording' => $request->input('recording', $request->query('recording')),
            'project' => $request->input('project', $request->query('project')),
            'status' => $request->input('status', $request->query('status')),
            'query' => $request->input('query', $request->query('query')),
        ], $overrides);

        $query = array_filter($query, fn ($value) => $value !== null && $value !== '');

        return redirect()->route('home', $query);
    }

    private function findAccessibleProject(User $user, string $projectId): Project
    {
        return $user->projects()->whereKey($projectId)->firstOrFail();
    }

    private function findAccessibleRecording(User $user, string $recordingId): Recording
    {
        return $user->recordings()
            ->with(['summary', 'noteArtifact', 'project', 'transcriptSegments', 'chatSession.messages'])
            ->whereKey($recordingId)
            ->firstOrFail();
    }
}
