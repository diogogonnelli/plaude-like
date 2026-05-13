<?php

namespace App\Modules\Recordings\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Modules\Projects\Models\Project;
use App\Modules\Recordings\Models\Recording;
use App\Modules\Identity\Models\User;
use App\Modules\Chat\Services\ChatService;
use App\Modules\Recordings\Services\RecordingService;
use App\Modules\Recordings\Support\WebUi;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AppController extends Controller
{
    public function __construct(
        private RecordingService $recordingService,
        private ChatService $chatService,
    ) {}

    public function entry(Request $request): View|RedirectResponse
    {
        $legacy = $this->legacyDestination($request);
        if ($legacy !== null) {
            return $legacy;
        }

        if (! $request->user()) {
            return view('web.auth.login', [
                'brandName' => config('app.name', 'GravAção'),
            ]);
        }

        return redirect()->route('workspace.home');
    }

    public function home(Request $request): View
    {
        $user = $request->user();
        abort_unless($user, 403);

        [$projects, $activeProject] = $this->projectsAndActiveProject($request, $user);
        $summaryStats = $this->summaryStats($user);

        return view('web.home', array_merge(
            $this->baseWorkspaceData($user, $projects, $activeProject),
            [
                'summaryStats' => $summaryStats,
                'pageTitle' => 'Início',
                'pageSubtitle' => 'Projeto ativo, captura, upload e leitura rápida da operação.',
            ],
        ));
    }

    public function library(Request $request): View
    {
        $user = $request->user();
        abort_unless($user, 403);

        [$projects, $activeProject] = $this->projectsAndActiveProject($request, $user);
        $filters = $this->workspaceFilters($request, $projects);
        $recordings = $this->workspaceRecordings($user, $filters);

        return view('web.library.index', array_merge(
            $this->baseWorkspaceData($user, $projects, $activeProject),
            [
                'pageTitle' => 'Biblioteca operacional',
                'pageSubtitle' => 'Busca, filtros por projeto e leitura densa do pipeline em uma superfície única.',
                'filters' => $filters,
                'recordings' => $recordings,
                'recordingBuckets' => $this->recordingBuckets($recordings),
            ],
        ));
    }

    public function recording(Request $request, Recording $recording): View
    {
        $user = $request->user();
        abort_unless($user, 403);

        [$projects, $activeProject] = $this->projectsAndActiveProject($request, $user);
        $recording = $this->findAccessibleRecording($user, $recording->id);

        return view('web.recordings.show', array_merge(
            $this->baseWorkspaceData($user, $projects, $activeProject),
            [
                'pageTitle' => 'Detalhe da gravação',
                'pageSubtitle' => 'Resumo, capítulos, highlights, action items, transcript, áudio e reprocessamento.',
                'recording' => $recording,
                'projectName' => $recording->project?->name ?? 'Sem projeto',
                'authorName' => $recording->createdByUser?->full_name ?? $recording->createdByUser?->email ?? 'Usuário',
                'sourceLabel' => WebUi::recordingSourceDetail($recording),
            ],
        ));
    }

    public function chat(Request $request, Recording $recording): View
    {
        $user = $request->user();
        abort_unless($user, 403);

        [$projects, $activeProject] = $this->projectsAndActiveProject($request, $user);
        $recording = $this->findAccessibleRecording($user, $recording->id);

        return view('web.recordings.chat', array_merge(
            $this->baseWorkspaceData($user, $projects, $activeProject),
            [
                'pageTitle' => 'Chat contextual',
                'pageSubtitle' => 'Perguntas guiadas pelo transcript atual, com respostas ancoradas na gravação.',
                'recording' => $recording,
            ],
        ));
    }

    public function settings(Request $request): View
    {
        $user = $request->user();
        abort_unless($user, 403);

        [$projects, $activeProject] = $this->projectsAndActiveProject($request, $user);

        return view('web.settings', array_merge(
            $this->baseWorkspaceData($user, $projects, $activeProject),
            [
                'pageTitle' => 'Sistema e ambiente',
                'pageSubtitle' => 'Sessão atual, projeto ativo e organização operacional.',
            ],
        ));
    }

    public function setActiveProject(Request $request): RedirectResponse
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

        return back()->with('status', 'Projeto ativo atualizado.');
    }

    public function storeProject(Request $request): RedirectResponse
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

        return redirect()->route('workspace.settings')->with('status', 'Projeto criado com sucesso.');
    }

    public function uploadAudio(Request $request): RedirectResponse
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
            $notice = 'Áudio enviado. O processamento foi iniciado.';
        } catch (\Throwable $exception) {
            $recording->update([
                'status' => 'failed',
                'last_error' => $exception->getMessage(),
            ]);
            $notice = 'Áudio enviado, mas o processamento falhou ao iniciar.';
        }

        return redirect()
            ->route('workspace.recordings.show', $recording)
            ->with('status', $notice);
    }

    public function updateRecordingProject(Request $request, Recording $recording): RedirectResponse
    {
        $user = $request->user();
        abort_unless($user, 403);

        $validated = $request->validate([
            'project_id' => 'nullable|uuid',
        ]);

        $recording = $this->findAccessibleRecording($user, $recording->id);
        $projectId = $validated['project_id'] ?? null;

        if ($projectId) {
            $this->findAccessibleProject($user, $projectId);
        }

        $recording->update(['project_id' => $projectId]);

        return redirect()
            ->route('workspace.recordings.show', $recording)
            ->with('status', $projectId ? 'Projeto da gravação atualizado.' : 'Vínculo com projeto removido.');
    }

    public function reprocessRecording(Request $request, Recording $recording): RedirectResponse
    {
        $user = $request->user();
        abort_unless($user, 403);

        $recording = $this->findAccessibleRecording($user, $recording->id);
        $this->recordingService->reprocess($recording);

        return back()->with('status', 'Reprocessamento iniciado.');
    }

    public function sendChat(Request $request, Recording $recording): RedirectResponse
    {
        $user = $request->user();
        abort_unless($user, 403);

        $validated = $request->validate([
            'message' => 'required|string|max:4000',
        ]);

        $recording = $this->findAccessibleRecording($user, $recording->id);

        try {
            $this->chatService->send($recording, $validated['message']);

            return redirect()
                ->route('workspace.recordings.chat', $recording)
                ->with('status', 'Mensagem enviada ao chat da gravação.');
        } catch (\Throwable) {
            return redirect()
                ->route('workspace.recordings.chat', $recording)
                ->withErrors(['chat' => 'Não foi possível responder ao chat desta gravação.']);
        }
    }

    public function export(Request $request, Recording $recording, string $format): StreamedResponse
    {
        $user = $request->user();
        abort_unless($user, 403);

        $recording = $this->findAccessibleRecording($user, $recording->id);
        abort_unless(in_array($format, ['txt', 'md'], true), 404);

        $artifact = $this->recordingService->export($recording, $format);

        return response()->streamDownload(function () use ($artifact): void {
            echo $artifact['body'];
        }, $artifact['file_name'], [
            'Content-Type' => $artifact['content_type'],
        ]);
    }

    public function audio(Request $request, Recording $recording)
    {
        $user = $request->user();
        abort_unless($user, 403);

        $recording = $this->findAccessibleRecording($user, $recording->id);

        abort_unless(
            $recording->audio_path && Storage::disk('recordings')->exists($recording->audio_path),
            404,
        );

        return Storage::disk('recordings')->response($recording->audio_path, basename($recording->audio_path));
    }

    private function legacyDestination(Request $request): ?RedirectResponse
    {
        $user = $request->user();
        if (! $user) {
            return null;
        }

        $tab = $request->string('tab')->toString();
        if ($tab === '') {
            return null;
        }

        return match ($tab) {
            'home' => redirect()->route('workspace.home'),
            'library' => $request->filled('recording')
                ? redirect()->route('workspace.recordings.show', ['recording' => $request->string('recording')->toString()])
                : redirect()->route('workspace.library', $this->legacyLibraryQuery($request)),
            'system' => redirect()->route('workspace.settings'),
            'admin' => $user->isAdmin() ? redirect()->route('workspace.admin.dashboard') : redirect()->route('workspace.home'),
            default => null,
        };
    }

    private function legacyLibraryQuery(Request $request): array
    {
        return array_filter([
            'project' => $request->query('project'),
            'status' => $request->query('status'),
            'query' => $request->query('query'),
        ], fn ($value) => $value !== null && $value !== '');
    }

    private function baseWorkspaceData(User $user, $projects, ?Project $activeProject): array
    {
        return [
            'brandName' => config('app.name', 'GravAção'),
            'user' => $user,
            'projects' => $projects,
            'activeProject' => $activeProject,
            'showAdminNav' => $user->isAdmin(),
        ];
    }

    private function projectsAndActiveProject(Request $request, User $user): array
    {
        $user->loadMissing('profile');

        $projects = $user->projects()
            ->withCount('recordings')
            ->orderBy('name')
            ->get();

        $activeProjectId = $this->normalizeActiveProjectId(
            $request->session()->get('web.active_project_id'),
            $projects,
        );

        $request->session()->put('web.active_project_id', $activeProjectId);

        return [$projects, $projects->firstWhere('id', $activeProjectId)];
    }

    private function workspaceFilters(Request $request, $projects): array
    {
        return [
            'query' => trim($request->string('query')->toString()),
            'project' => $this->normalizeProjectFilter($request->string('project', 'all')->toString(), $projects),
            'status' => $this->normalizeStatusFilter($request->string('status', 'all')->toString()),
        ];
    }

    private function workspaceRecordings(User $user, array $filters)
    {
        $query = $user->recordings()
            ->with(['project', 'summary', 'noteArtifact', 'transcriptSegments', 'chatSession.messages', 'createdByUser'])
            ->orderByDesc('created_at');

        if ($filters['project'] === 'none') {
            $query->whereNull('project_id');
        } elseif ($filters['project'] !== 'all') {
            $query->where('project_id', $filters['project']);
        }

        if ($filters['status'] !== 'all') {
            $query->where('status', $filters['status']);
        }

        if ($filters['query'] !== '') {
            $like = '%'.$filters['query'].'%';
            $query->where(function ($builder) use ($like): void {
                $builder->where('title', 'like', $like)
                    ->orWhereHas('summary', fn ($summaryQuery) => $summaryQuery->where('overview', 'like', $like))
                    ->orWhereHas('noteArtifact', fn ($artifactQuery) => $artifactQuery->where('title', 'like', $like))
                    ->orWhereHas('transcriptSegments', fn ($segmentQuery) => $segmentQuery->where('text', 'like', $like));
            });
        }

        return $query->limit(60)->get();
    }

    private function summaryStats(User $user): array
    {
        $statsRecordings = $user->recordings()->get(['status']);

        return [
            'total' => $statsRecordings->count(),
            'processing' => $statsRecordings->whereIn('status', ['uploaded', 'processing_transcript', 'processing_summary', 'indexing'])->count(),
            'failed' => $statsRecordings->where('status', 'failed')->count(),
            'ready' => $statsRecordings->where('status', 'ready')->count(),
        ];
    }

    private function recordingBuckets($recordings): array
    {
        return [
            'processing' => $recordings->whereIn('status', ['uploaded', 'processing_transcript', 'processing_summary', 'indexing'])->values(),
            'ready' => $recordings->where('status', 'ready')->values(),
            'failed' => $recordings->where('status', 'failed')->values(),
        ];
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

    private function findAccessibleProject(User $user, string $projectId): Project
    {
        return $user->projects()->whereKey($projectId)->firstOrFail();
    }

    private function findAccessibleRecording(User $user, string $recordingId): Recording
    {
        return $user->recordings()
            ->with(['summary', 'noteArtifact', 'project', 'transcriptSegments', 'chatSession.messages', 'createdByUser'])
            ->whereKey($recordingId)
            ->firstOrFail();
    }
}
