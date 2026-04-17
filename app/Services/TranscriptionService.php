<?php

namespace App\Services;

use App\Models\Recording;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class TranscriptionService
{
    public function submit(Recording $recording): void
    {
        $apiKey = config('services.assemblyai.api_key');

        if (!$apiKey) {
            Log::warning('AssemblyAI API key not configured, skipping transcription');
            return;
        }

        // Upload audio to AssemblyAI
        $audioPath = Storage::disk('recordings')->path($recording->audio_path);

        $uploadResponse = Http::withHeaders([
            'authorization' => $apiKey,
        ])->attach('file', file_get_contents($audioPath), basename($audioPath))
          ->post('https://api.assemblyai.com/v2/upload');

        $audioUrl = $uploadResponse->json('upload_url');

        // Submit transcription job
        $transcriptResponse = Http::withHeaders([
            'authorization' => $apiKey,
            'content-type' => 'application/json',
        ])->post('https://api.assemblyai.com/v2/transcript', [
            'audio_url' => $audioUrl,
            'speaker_labels' => true,
            'language_code' => 'pt',
            'webhook_url' => config('services.assemblyai.webhook_url'),
        ]);

        $recording->update([
            'transcription_provider' => 'assemblyai',
            'transcription_job_id' => $transcriptResponse->json('id'),
            'transcription_started_at' => now(),
        ]);
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
}
