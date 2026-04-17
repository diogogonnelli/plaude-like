<?php

namespace App\Services;

use App\Models\Recording;
use Illuminate\Support\Facades\Log;
use OpenAI\Laravel\Facades\OpenAI;

class SummaryService
{
    public function generate(Recording $recording): void
    {
        $recording->load('transcriptSegments');

        if ($recording->transcriptSegments->isEmpty()) {
            $recording->update(['status' => 'ready']);
            return;
        }

        $transcriptText = $recording->transcriptSegments
            ->map(fn ($s) => "[{$s->speaker_label}]: {$s->text}")
            ->implode("\n");

        try {
            $recording->update(['status' => 'processing_summary']);

            // Generate summary
            $summaryResponse = OpenAI::chat()->create([
                'model' => 'gpt-4o-mini',
                'response_format' => ['type' => 'json_object'],
                'messages' => [
                    [
                        'role' => 'system',
                        'content' => 'You are a meeting summarizer. Given a transcript, produce a JSON object with: {"overview": "string (2-3 paragraph summary in Portuguese)", "chapters": [{"heading": "string", "body": "string"}]}',
                    ],
                    [
                        'role' => 'user',
                        'content' => $transcriptText,
                    ],
                ],
            ]);

            $summaryData = json_decode($summaryResponse->choices[0]->message->content, true);

            $recording->summary()->updateOrCreate(
                ['recording_id' => $recording->id],
                [
                    'overview' => $summaryData['overview'] ?? '',
                    'chapters' => $summaryData['chapters'] ?? [],
                ],
            );

            // Generate note artifacts
            $notesResponse = OpenAI::chat()->create([
                'model' => 'gpt-4o-mini',
                'response_format' => ['type' => 'json_object'],
                'messages' => [
                    [
                        'role' => 'system',
                        'content' => 'You are a meeting note extractor. Given a transcript, produce a JSON object with: {"title": "string (concise title in Portuguese)", "tags": ["string"], "highlights": ["string (key points)"], "action_items": ["string (tasks/next steps)"]}',
                    ],
                    [
                        'role' => 'user',
                        'content' => $transcriptText,
                    ],
                ],
            ]);

            $notesData = json_decode($notesResponse->choices[0]->message->content, true);

            $recording->noteArtifact()->updateOrCreate(
                ['recording_id' => $recording->id],
                [
                    'title' => $notesData['title'] ?? $recording->title,
                    'tags' => $notesData['tags'] ?? [],
                    'highlights' => $notesData['highlights'] ?? [],
                    'action_items' => $notesData['action_items'] ?? [],
                ],
            );

            $recording->update(['status' => 'ready']);
        } catch (\Throwable $e) {
            Log::error("Summary generation failed for recording {$recording->id}: {$e->getMessage()}");
            $recording->update([
                'status' => 'failed',
                'last_error' => $e->getMessage(),
            ]);
        }
    }
}
