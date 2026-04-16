<?php

namespace App\Services;

use App\Models\Recording;
use App\Models\TranscriptSegment;
use Illuminate\Support\Str;

class RecordingService
{
    public function __construct(
        private TranscriptionService $transcriptionService,
        private SummaryService $summaryService,
    ) {}

    public function create(string $userId, array $data): Recording
    {
        $recording = Recording::create([
            'user_id' => $userId,
            'created_by_user_id' => $data['created_by_user_id'] ?? $userId,
            'project_id' => $data['project_id'] ?? null,
            'title' => $data['title'],
            'source_type' => $data['source_type'],
            'status' => 'uploaded',
            'duration_ms' => $data['duration_ms'] ?? null,
            'capture_metadata' => $data['capture_metadata'] ?? null,
        ]);

        return $recording;
    }

    public function startProcessing(Recording $recording): void
    {
        if (!$recording->audio_path) {
            throw new \RuntimeException('Recording has no audio file');
        }

        $recording->update(['status' => 'processing_transcript']);

        $this->transcriptionService->submit($recording);
    }

    public function reprocess(Recording $recording): void
    {
        $recording->transcriptSegments()->delete();
        $recording->summary()->delete();
        $recording->noteArtifact()->delete();
        $recording->update([
            'status' => 'processing_transcript',
            'last_error' => null,
        ]);

        $this->transcriptionService->submit($recording);
    }

    public function completeTranscription(Recording $recording, array $segments): void
    {
        foreach ($segments as $segment) {
            TranscriptSegment::create([
                'recording_id' => $recording->id,
                'speaker_label' => $segment['speaker_label'],
                'start_ms' => $segment['start_ms'],
                'end_ms' => $segment['end_ms'],
                'text' => $segment['text'],
            ]);
        }

        $recording->update([
            'status' => 'processing_summary',
            'transcription_completed_at' => now(),
        ]);

        $this->summaryService->generate($recording);
    }

    public function export(Recording $recording, string $format): array
    {
        $recording->load(['transcriptSegments', 'summary', 'noteArtifact']);

        $body = $this->buildExportBody($recording, $format);

        return [
            'format' => $format,
            'file_name' => Str::slug($recording->title) . '.' . $format,
            'content_type' => $format === 'md' ? 'text/markdown' : 'text/plain',
            'body' => $body,
        ];
    }

    private function buildExportBody(Recording $recording, string $format): string
    {
        $lines = [];

        if ($format === 'md') {
            $lines[] = "# {$recording->title}";
            $lines[] = '';
        } else {
            $lines[] = $recording->title;
            $lines[] = str_repeat('=', strlen($recording->title));
            $lines[] = '';
        }

        if ($recording->summary) {
            if ($format === 'md') {
                $lines[] = '## Resumo';
            } else {
                $lines[] = 'RESUMO';
            }
            $lines[] = '';
            $lines[] = $recording->summary->overview;
            $lines[] = '';

            if (!empty($recording->summary->chapters)) {
                foreach ($recording->summary->chapters as $chapter) {
                    if ($format === 'md') {
                        $lines[] = "### {$chapter['heading']}";
                    } else {
                        $lines[] = strtoupper($chapter['heading']);
                    }
                    $lines[] = $chapter['body'];
                    $lines[] = '';
                }
            }
        }

        if ($recording->noteArtifact) {
            if ($format === 'md') {
                $lines[] = '## Notas';
            } else {
                $lines[] = 'NOTAS';
            }
            $lines[] = '';

            if (!empty($recording->noteArtifact->highlights)) {
                $lines[] = $format === 'md' ? '### Destaques' : 'DESTAQUES';
                foreach ($recording->noteArtifact->highlights as $h) {
                    $lines[] = $format === 'md' ? "- {$h}" : "  * {$h}";
                }
                $lines[] = '';
            }

            if (!empty($recording->noteArtifact->action_items)) {
                $lines[] = $format === 'md' ? '### Ações' : 'AÇÕES';
                foreach ($recording->noteArtifact->action_items as $a) {
                    $lines[] = $format === 'md' ? "- [ ] {$a}" : "  * {$a}";
                }
                $lines[] = '';
            }
        }

        if ($recording->transcriptSegments->isNotEmpty()) {
            if ($format === 'md') {
                $lines[] = '## Transcrição';
            } else {
                $lines[] = 'TRANSCRIÇÃO';
            }
            $lines[] = '';

            foreach ($recording->transcriptSegments as $seg) {
                $ts = gmdate('H:i:s', (int) ($seg->start_ms / 1000));
                $lines[] = "[{$ts}] {$seg->speaker_label}: {$seg->text}";
            }
        }

        return implode("\n", $lines);
    }
}
