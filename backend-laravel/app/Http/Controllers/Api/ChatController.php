<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatSession;
use App\Models\Recording;
use App\Services\ChatService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function __construct(
        private ChatService $chatService,
    ) {}

    public function show(Request $request, Recording $recording): JsonResponse
    {
        $this->authorizeRecording($request, $recording);

        $session = $recording->chatSession()->with('messages')->first();

        if (!$session) {
            return response()->json(['data' => null]);
        }

        return response()->json([
            'data' => [
                'id' => $session->id,
                'recording_id' => $session->recording_id,
                'messages' => $session->messages->map(fn ($m) => [
                    'id' => $m->id,
                    'role' => $m->role,
                    'content' => $m->content,
                    'citations' => $m->citations ?? [],
                    'created_at' => $m->created_at?->toIso8601String(),
                ])->toArray(),
            ],
        ]);
    }

    public function send(Request $request, Recording $recording): JsonResponse
    {
        $this->authorizeRecording($request, $recording);

        $validated = $request->validate([
            'message' => 'required|string|max:4000',
        ]);

        $response = $this->chatService->send($recording, $validated['message']);

        return response()->json(['data' => $response]);
    }

    private function authorizeRecording(Request $request, Recording $recording): void
    {
        if ($recording->created_by_user_id !== $request->user()->id) {
            abort(403, 'Forbidden');
        }
    }
}
