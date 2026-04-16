<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\TranscriptionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WebhookController extends Controller
{
    public function __construct(
        private TranscriptionService $transcriptionService,
    ) {}

    public function assemblyai(Request $request): JsonResponse
    {
        $payload = $request->all();

        $this->transcriptionService->handleWebhook($payload);

        return response()->json(['status' => 'ok']);
    }
}
