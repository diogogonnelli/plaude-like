<?php

namespace App\Modules\Recordings\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Modules\Recordings\Models\Recording;
use App\Modules\Recordings\Services\RecordingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class RecordingController extends Controller
{
    public function __construct(
        private RecordingService $recordingService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $recordings = Recording::where('created_by_user_id', $request->user()->id)
            ->with(['summary', 'noteArtifact'])
            ->orderByDesc('created_at')
            ->paginate($request->integer('per_page', 25));

        return response()->json([
            'data' => $recordings->map(fn ($r) => $this->formatRecording($r)),
            'meta' => [
                'current_page' => $recordings->currentPage(),
                'last_page' => $recordings->lastPage(),
                'total' => $recordings->total(),
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'project_id' => 'nullable|uuid|exists:projects,id',
            'source_type' => 'required|in:microphone,upload,desktop_meeting',
            'capture_metadata' => 'nullable|array',
            'duration_ms' => 'nullable|integer',
        ]);

        if (!empty($validated['project_id'])) {
            $this->authorizeProjectMembership($request, $validated['project_id']);
        }

        $recording = $this->recordingService->create(
            userId: $request->user()->id,
            data: $validated,
        );

        return response()->json([
            'data' => $this->formatRecordingFull($recording),
        ], 201);
    }

    public function show(Request $request, Recording $recording): JsonResponse
    {
        $this->authorizeRecording($request, $recording);

        $recording->load(['transcriptSegments', 'summary', 'noteArtifact', 'chatSession.messages']);

        return response()->json([
            'data' => $this->formatRecordingFull($recording),
        ]);
    }

    public function update(Request $request, Recording $recording): JsonResponse
    {
        $this->authorizeRecording($request, $recording);

        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'project_id' => 'sometimes|nullable|uuid|exists:projects,id',
        ]);

        if (array_key_exists('project_id', $validated) && $validated['project_id'] !== null) {
            $this->authorizeProjectMembership($request, $validated['project_id']);
        }

        $recording->update($validated);

        return response()->json([
            'data' => $this->formatRecordingFull($recording->fresh(['transcriptSegments', 'summary', 'noteArtifact', 'chatSession.messages'])),
        ]);
    }

    public function destroy(Request $request, Recording $recording): JsonResponse
    {
        $this->authorizeRecording($request, $recording);

        if ($recording->audio_path) {
            Storage::disk('recordings')->delete($recording->audio_path);
        }

        $recording->delete();

        return response()->json(null, 204);
    }

    public function upload(Request $request, Recording $recording): JsonResponse
    {
        $this->authorizeRecording($request, $recording);

        $request->validate([
            'audio' => 'required|file|max:512000', // 500MB max
        ]);

        $path = $request->file('audio')->store(
            $recording->id,
            'recordings'
        );

        $recording->update(['audio_path' => $path]);

        return response()->json([
            'data' => $this->formatRecordingFull($recording->fresh()),
        ]);
    }

    public function audio(Request $request, Recording $recording)
    {
        $this->authorizeRecording($request, $recording);

        if (!$recording->audio_path || !Storage::disk('recordings')->exists($recording->audio_path)) {
            return response()->json(['message' => 'Audio not found'], 404);
        }

        return Storage::disk('recordings')->response($recording->audio_path);
    }

    public function process(Request $request, Recording $recording): JsonResponse
    {
        $this->authorizeRecording($request, $recording);

        $this->recordingService->startProcessing($recording);

        return response()->json([
            'data' => $this->formatRecordingFull($recording->fresh(['transcriptSegments', 'summary', 'noteArtifact'])),
        ]);
    }

    public function reprocess(Request $request, Recording $recording): JsonResponse
    {
        $this->authorizeRecording($request, $recording);

        $this->recordingService->reprocess($recording);

        return response()->json([
            'data' => $this->formatRecordingFull($recording->fresh(['transcriptSegments', 'summary', 'noteArtifact'])),
        ]);
    }

    public function export(Request $request, Recording $recording, string $format): JsonResponse
    {
        $this->authorizeRecording($request, $recording);

        if (!in_array($format, ['txt', 'md'])) {
            return response()->json(['message' => 'Unsupported format'], 422);
        }

        $artifact = $this->recordingService->export($recording, $format);

        return response()->json(['data' => $artifact]);
    }

    private function authorizeRecording(Request $request, Recording $recording): void
    {
        if ($recording->created_by_user_id !== $request->user()->id) {
            abort(403, 'Forbidden');
        }
    }

    private function authorizeProjectMembership(Request $request, string $projectId): void
    {
        $isMember = $request->user()
            ->projects()
            ->whereKey($projectId)
            ->exists();

        if (!$isMember) {
            abort(403, 'Forbidden');
        }
    }

    private function formatRecording(Recording $recording): array
    {
        return [
            'id' => $recording->id,
            'user_id' => $recording->user_id,
            'created_by_user_id' => $recording->created_by_user_id,
            'project_id' => $recording->project_id,
            'title' => $recording->title,
            'source_type' => $recording->source_type,
            'status' => $recording->status,
            'duration_ms' => $recording->duration_ms,
            'audio_path' => $recording->audio_path,
            'capture_metadata' => $recording->capture_metadata,
            'created_at' => $recording->created_at->toIso8601String(),
            'updated_at' => $recording->updated_at->toIso8601String(),
            'summary' => $recording->summary ? [
                'overview' => $recording->summary->overview,
                'chapters' => $recording->summary->chapters,
            ] : null,
            'note_artifact' => $recording->noteArtifact ? [
                'title' => $recording->noteArtifact->title,
                'tags' => $recording->noteArtifact->tags,
                'highlights' => $recording->noteArtifact->highlights,
                'action_items' => $recording->noteArtifact->action_items,
            ] : null,
        ];
    }

    private function formatRecordingFull(Recording $recording): array
    {
        $data = $this->formatRecording($recording);

        $data['transcription_provider'] = $recording->transcription_provider;
        $data['transcription_job_id'] = $recording->transcription_job_id;
        $data['transcription_started_at'] = $recording->transcription_started_at?->toIso8601String();
        $data['transcription_completed_at'] = $recording->transcription_completed_at?->toIso8601String();
        $data['last_error'] = $recording->last_error;

        $data['transcript_segments'] = $recording->transcriptSegments->map(fn ($s) => [
            'id' => $s->id,
            'recording_id' => $s->recording_id,
            'speaker_label' => $s->speaker_label,
            'start_ms' => $s->start_ms,
            'end_ms' => $s->end_ms,
            'text' => $s->text,
        ])->toArray();

        $data['chat_session'] = $recording->chatSession ? [
            'id' => $recording->chatSession->id,
            'recording_id' => $recording->chatSession->recording_id,
            'messages' => $recording->chatSession->messages->map(fn ($m) => [
                'id' => $m->id,
                'role' => $m->role,
                'content' => $m->content,
                'citations' => $m->citations ?? [],
                'created_at' => $m->created_at?->toIso8601String(),
            ])->toArray(),
        ] : null;

        return $data;
    }
}
