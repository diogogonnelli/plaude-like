import { randomUUID } from 'node:crypto';

import type { AiProcessingResult, AiProvider, ChatAnswer } from '../domain/contracts.js';
import type { ProcessRecordingInput, Recording, TranscriptSegment } from '../domain/types.js';

const defaultTranscript = `Speaker 1: Vamos fechar o cronograma do lançamento móvel até sexta-feira.
Speaker 2: Eu assumo o fluxo de onboarding e a tela de biblioteca.
Speaker 1: Precisamos validar integração com OpenAI, Deepgram e exportação em markdown.
Speaker 2: Também vou revisar métricas, empty states e tratamento de falhas do pipeline.`;

function chunkTranscript(recordingId: string, transcriptText: string): TranscriptSegment[] {
  const rawLines = transcriptText
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean);

  return rawLines.map((line, index) => {
    const [speaker, ...rest] = line.split(':');
    const text = rest.join(':').trim() || line;
    const startMs = index * 32_000;
    const endMs = startMs + 26_000;

    return {
      id: randomUUID(),
      recordingId,
      speakerLabel: text === line ? `Speaker ${(index % 2) + 1}` : speaker.trim(),
      startMs,
      endMs,
      text,
    };
  });
}

function deriveSummary(segments: TranscriptSegment[]): AiProcessingResult {
  const highlights = segments.slice(0, 3).map((segment) => segment.text);
  const actionItems = segments
    .filter((segment) => /vou|precisa|assumo|validar|review|revisar|fechar/i.test(segment.text))
    .map((segment) => segment.text)
    .slice(0, 4);

  const combined = segments.map((segment) => segment.text).join(' ');
  const tags = ['meeting', 'transcript', combined.toLowerCase().includes('openai') ? 'ai' : 'ops'];

  return {
    title: segments[0]?.text.slice(0, 56) || 'New recording',
    transcriptSegments: segments,
    overview:
      'Conversa processada com foco em decisões, próximos passos e contexto operacional. O resultado está pronto para consulta e follow-up.',
    chapters: [
      {
        heading: 'Decisões',
        body: highlights[0] ?? 'Nenhuma decisão principal detectada.',
      },
      {
        heading: 'Execução',
        body: highlights[1] ?? 'Nenhuma atividade operacional detectada.',
      },
      {
        heading: 'Riscos e próximos passos',
        body: actionItems[0] ?? highlights[2] ?? 'Sem riscos explícitos no mock.',
      },
    ],
    tags,
    highlights,
    actionItems,
  };
}

export class MockAiProvider implements AiProvider {
  async processRecording(recording: Recording, input?: ProcessRecordingInput): Promise<AiProcessingResult> {
    const transcriptText = input?.transcriptText?.trim() || defaultTranscript;
    const segments = chunkTranscript(recording.id, transcriptText);
    return deriveSummary(segments);
  }

  async answerQuestion(recording: Recording, question: string): Promise<ChatAnswer> {
    const lowered = question.toLowerCase();
    const matchingSegments = recording.transcriptSegments.filter((segment) => {
      if (lowered.includes('ação') || lowered.includes('action') || lowered.includes('próximo')) {
        return recording.noteArtifact?.actionItems.includes(segment.text) ?? false;
      }

      return segment.text.toLowerCase().includes(lowered.split(' ').find((word) => word.length > 4) ?? '');
    });

    const citations = (matchingSegments.length > 0 ? matchingSegments : recording.transcriptSegments.slice(0, 2)).map(
      (segment) => ({
        segmentId: segment.id,
        startMs: segment.startMs,
        endMs: segment.endMs,
        quote: segment.text,
      }),
    );

    const answer = matchingSegments.length > 0
      ? `Encontrei ${matchingSegments.length} trechos relevantes. O ponto central é: ${matchingSegments[0]!.text}`
      : `Nao encontrei correspondencia literal forte, mas o contexto mais proximo indica: ${recording.summary?.overview ?? 'sem resumo disponivel.'}`;

    return { answer, citations };
  }
}
