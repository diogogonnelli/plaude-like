<?php

namespace App\Modules\Ai\Services;

use App\Modules\Recordings\Models\Recording;
use App\Modules\Recordings\Services\RecordingService;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class TranscriptionService
{
    public function submit(Recording $recording): void
    {
        $apiKey = config('services.assemblyai.api_key');

        if (!$apiKey) {
            Log::error("AssemblyAI transcription unavailable for recording {$recording->id}: API key not configured.");
            $this->markAsFailed($recording, 'AssemblyAI API key not configured.');
            return;
        }

        try {
            $audioPath = Storage::disk('recordings')->path($recording->audio_path);

            $uploadResponse = Http::withHeaders([
                'authorization' => $apiKey,
            ])->attach('file', file_get_contents($audioPath), basename($audioPath))
                ->post('https://api.assemblyai.com/v2/upload');

            if ($uploadResponse->failed()) {
                Log::error("AssemblyAI upload failed for recording {$recording->id}.", [
                    'status' => $uploadResponse->status(),
                    'body' => $uploadResponse->body(),
                ]);
                $this->markAsFailed($recording, "AssemblyAI upload failed with status {$uploadResponse->status()}.");
                return;
            }

            $audioUrl = $uploadResponse->json('upload_url');

            if (!is_string($audioUrl) || trim($audioUrl) === '') {
                Log::error("AssemblyAI upload did not return an upload_url for recording {$recording->id}.", [
                    'body' => $uploadResponse->json(),
                ]);
                $this->markAsFailed($recording, 'AssemblyAI upload did not return upload_url.');
                return;
            }

            $transcriptPayload = [
                'audio_url' => $audioUrl,
                'speaker_labels' => true,
                'language_code' => 'pt',
                'webhook_url' => config('services.assemblyai.webhook_url'),
            ];

            $webhookSecret = (string) config('services.assemblyai.webhook_secret', '');
            if ($webhookSecret !== '') {
                $transcriptPayload['webhook_auth_header_name'] = 'X-AssemblyAI-Webhook-Secret';
                $transcriptPayload['webhook_auth_header_value'] = $webhookSecret;
            }

            $transcriptResponse = Http::withHeaders([
                'authorization' => $apiKey,
                'content-type' => 'application/json',
            ])->post('https://api.assemblyai.com/v2/transcript', $transcriptPayload);

            if ($transcriptResponse->failed()) {
                Log::error("AssemblyAI transcript creation failed for recording {$recording->id}.", [
                    'status' => $transcriptResponse->status(),
                    'body' => $transcriptResponse->body(),
                ]);
                $this->markAsFailed($recording, "AssemblyAI transcript creation failed with status {$transcriptResponse->status()}.");
                return;
            }

            $transcriptId = $transcriptResponse->json('id');

            if (!is_string($transcriptId) || trim($transcriptId) === '') {
                Log::error("AssemblyAI transcript creation did not return an id for recording {$recording->id}.", [
                    'body' => $transcriptResponse->json(),
                ]);
                $this->markAsFailed($recording, 'AssemblyAI transcript creation did not return an id.');
                return;
            }

            $recording->update([
                'transcription_provider' => 'assemblyai',
                'transcription_job_id' => $transcriptId,
                'transcription_started_at' => now(),
                'last_error' => null,
            ]);
        } catch (\Throwable $exception) {
            Log::error("AssemblyAI submit failed for recording {$recording->id}: {$exception->getMessage()}");
            $this->markAsFailed($recording, $exception->getMessage());
        }
    }

    public function handleWebhook(array $payload): void
    {
        $transcriptId = $payload['transcript_id'] ?? null;
        $status = $payload['status'] ?? null;

        if (!$transcriptId) {
            return;
        }

        $recording = Recording::where('transcription_job_id', $transcriptId)->first();

        if (!$recording) {
            Log::warning("Recording not found for transcript ID: {$transcriptId}");
            return;
        }

        if ($status === 'completed') {
            $this->fetchAndStoreTranscript($recording, $transcriptId);
        } elseif ($status === 'error') {
            $recording->update([
                'status' => 'failed',
                'last_error' => $payload['error'] ?? 'Transcription failed',
            ]);
        }
    }

    private function fetchAndStoreTranscript(Recording $recording, string $transcriptId): void
    {
        $apiKey = config('services.assemblyai.api_key');

        $response = Http::withHeaders([
            'authorization' => $apiKey,
        ])->get("https://api.assemblyai.com/v2/transcript/{$transcriptId}");

        $data = $response->json();
        $utterances = $data['utterances'] ?? [];

        $segments = collect($utterances)->map(fn ($u) => [
            'speaker_label' => $u['speaker'] ?? 'Speaker',
            'start_ms' => $u['start'],
            'end_ms' => $u['end'],
            'text' => $u['text'],
        ])->toArray();

        app(RecordingService::class)->completeTranscription($recording, $segments);
    }

    private function markAsFailed(Recording $recording, string $message): void
    {
        $recording->update([
            'status' => 'failed',
            'last_error' => $message,
        ]);
    }
}
