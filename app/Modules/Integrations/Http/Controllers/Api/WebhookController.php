<?php

namespace App\Modules\Integrations\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Modules\Ai\Services\TranscriptionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WebhookController extends Controller
{
    public function __construct(
        private TranscriptionService $transcriptionService,
    ) {}

    public function assemblyai(Request $request): JsonResponse
    {
        $this->authorizeAssemblyAiWebhook($request);

        $payload = $request->all();

        $this->transcriptionService->handleWebhook($payload);

        return response()->json(['status' => 'ok']);
    }

    private function authorizeAssemblyAiWebhook(Request $request): void
    {
        $secret = (string) config('services.assemblyai.webhook_secret', '');

        if ($secret === '') {
            return;
        }

        $received = (string) $request->header('X-AssemblyAI-Webhook-Secret', '');

        if (!hash_equals($secret, $received)) {
            abort(403, 'Invalid AssemblyAI webhook secret.');
        }
    }
}
