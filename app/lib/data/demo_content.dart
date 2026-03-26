import 'models.dart';

final demoNotes = <RecordingNote>[
  RecordingNote(
    id: 'demo-launch-sync',
    title: 'Launch planning sync',
    sourceType: 'upload',
    status: ProcessingStatus.ready,
    createdAt: DateTime.parse('2026-03-26T10:00:00.000Z'),
    updatedAt: DateTime.parse('2026-03-26T10:08:00.000Z'),
    durationMs: 1920000,
    audioPath: 'demo/launch-planning.m4a',
    transcriptSegments: const [
      TranscriptSegment(
        id: 'seg-1',
        recordingId: 'demo-launch-sync',
        speakerLabel: 'Speaker 1',
        startMs: 0,
        endMs: 18000,
        text: 'Vamos lançar o v1 com gravação, upload, resumo e chat sobre notas.',
      ),
      TranscriptSegment(
        id: 'seg-2',
        recordingId: 'demo-launch-sync',
        speakerLabel: 'Speaker 2',
        startMs: 18000,
        endMs: 42000,
        text: 'Eu fico com a biblioteca, experiência de detalhe e exportação em markdown.',
      ),
      TranscriptSegment(
        id: 'seg-3',
        recordingId: 'demo-launch-sync',
        speakerLabel: 'Speaker 1',
        startMs: 42000,
        endMs: 68000,
        text: 'Precisamos instrumentar falhas do pipeline e deixar retries claros para o usuário.',
      ),
    ],
    summary: const RecordingSummary(
      overview:
          'A reunião alinhou um v1 enxuto com foco em captura de áudio, processamento e consulta posterior via chat.',
      chapters: [
        SummaryChapter(
          heading: 'Escopo',
          body: 'O núcleo inclui gravação, upload, transcrição, resumo, biblioteca e chat contextual.',
        ),
        SummaryChapter(
          heading: 'Responsáveis',
          body: 'Biblioteca e exportação ficaram com um responsável dedicado para reduzir gargalos.',
        ),
      ],
    ),
    noteArtifact: const NoteArtifact(
      title: 'Launch planning sync',
      tags: ['launch', 'product', 'ai'],
      highlights: [
        'v1 com gravação, upload, resumo e chat',
        'biblioteca e exportação em markdown como entregas críticas',
      ],
      actionItems: [
        'Instrumentar falhas do pipeline',
        'Adicionar retries claros para o usuário',
      ],
    ),
    chatSession: const ChatSession(
      id: 'session-demo',
      recordingId: 'demo-launch-sync',
      messages: [],
    ),
  ),
];
