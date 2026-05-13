<?php

namespace App\Modules\Admin\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Modules\Recordings\Models\Recording;
use App\Modules\Recordings\Services\RecordingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RecordingController extends Controller
{
    public function __construct(
        private RecordingService $recordingService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = Recording::with(['createdByUser', 'project', 'summary']);

        if ($request->has('status')) {
            $query->where('status', $request->string('status'));
        }

        if ($request->has('user_id')) {
            $query->where('created_by_user_id', $request->string('user_id'));
        }

        $recordings = $query->orderByDesc('created_at')
            ->paginate($request->integer('per_page', 25));

        return response()->json([
            'data' => $recordings->map(fn ($r) => [
                'id' => $r->id,
                'title' => $r->title,
                'status' => $r->status,
                'source_type' => $r->source_type,
                'duration_ms' => $r->duration_ms,
                'created_by_user' => $r->createdByUser ? [
                    'id' => $r->createdByUser->id,
                    'full_name' => $r->createdByUser->full_name,
                    'email' => $r->createdByUser->email,
                ] : null,
                'project' => $r->project ? [
                    'id' => $r->project->id,
                    'name' => $r->project->name,
                ] : null,
                'created_at' => $r->created_at->toIso8601String(),
                'updated_at' => $r->updated_at->toIso8601String(),
            ]),
            'meta' => [
                'current_page' => $recordings->currentPage(),
                'last_page' => $recordings->lastPage(),
                'total' => $recordings->total(),
            ],
        ]);
    }

    public function show(Recording $recording): JsonResponse
    {
        $recording->load(['transcriptSegments', 'summary', 'noteArtifact', 'chatSession.messages', 'createdByUser', 'project']);

        return response()->json(['data' => $recording]);
    }

    public function reprocess(Recording $recording): JsonResponse
    {
        $this->recordingService->reprocess($recording);

        return response()->json([
            'data' => $recording->fresh(['transcriptSegments', 'summary', 'noteArtifact']),
        ]);
    }
}
