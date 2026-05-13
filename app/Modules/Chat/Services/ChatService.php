<?php

namespace App\Modules\Chat\Services;

use App\Modules\Chat\Models\ChatMessage;
use App\Modules\Chat\Models\ChatSession;
use App\Modules\Recordings\Models\Recording;
use Illuminate\Support\Facades\Log;
use OpenAI\Laravel\Facades\OpenAI;

class ChatService
{
    public function send(Recording $recording, string $userMessage): array
    {
        $recording->load(['transcriptSegments', 'summary']);

        $session = ChatSession::firstOrCreate(
            ['recording_id' => $recording->id],
        );

        // Save user message
        $userMsg = ChatMessage::create([
            'chat_session_id' => $session->id,
            'role' => 'user',
            'content' => $userMessage,
        ]);

        // Build context
        $transcriptText = $recording->transcriptSegments
            ->map(fn ($s) => "[{$s->speaker_label} @ {$s->start_ms}ms]: {$s->text}")
            ->implode("\n");

        $summaryText = $recording->summary?->overview ?? '';

        $history = $session->messages()
            ->orderBy('created_at')
            ->limit(20)
            ->get()
            ->map(fn ($m) => ['role' => $m->role, 'content' => $m->content])
            ->toArray();

        $systemPrompt = <<<PROMPT
You are a helpful assistant that answers questions about a recorded meeting.
Answer in the same language the user writes in.
When referencing specific parts of the transcript, include citations as JSON in your response.

Summary: {$summaryText}

Transcript:
{$transcriptText}
PROMPT;

        try {
            $response = OpenAI::chat()->create([
                'model' => 'gpt-4o-mini',
                'messages' => [
                    ['role' => 'system', 'content' => $systemPrompt],
                    ...$history,
                ],
            ]);

            $assistantContent = $response->choices[0]->message->content;

            $assistantMsg = ChatMessage::create([
                'chat_session_id' => $session->id,
                'role' => 'assistant',
                'content' => $assistantContent,
                'citations' => [],
            ]);

            return [
                'id' => $assistantMsg->id,
                'role' => 'assistant',
                'content' => $assistantContent,
                'citations' => [],
                'created_at' => $assistantMsg->created_at?->toIso8601String(),
            ];
        } catch (\Throwable $e) {
            Log::error("Chat failed for recording {$recording->id}: {$e->getMessage()}");
            throw $e;
        }
    }
}
