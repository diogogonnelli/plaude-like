import 'models.dart';

final demoNotes = <RecordingNote>[
  RecordingNote(
    id: 'demo-launch-sync',
    title: 'Sincronizacao de planejamento do lancamento',
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
        speakerLabel: 'Participante 1',
        startMs: 0,
        endMs: 18000,
        text: 'Vamos lancar o v1 com gravacao, upload, resumo e chat sobre notas.',
      ),
      TranscriptSegment(
        id: 'seg-2',
        recordingId: 'demo-launch-sync',
        speakerLabel: 'Participante 2',
        startMs: 18000,
        endMs: 42000,
        text: 'Eu fico com a biblioteca, experiencia de detalhe e exportacao em markdown.',
      ),
      TranscriptSegment(
        id: 'seg-3',
        recordingId: 'demo-launch-sync',
        speakerLabel: 'Participante 1',
        startMs: 42000,
        endMs: 68000,
        text: 'Precisamos instrumentar falhas do pipeline e deixar retries claros para o usuario.',
      ),
    ],
    summary: const RecordingSummary(
      overview:
          'A reuniao alinhou um v1 enxuto com foco em captura de audio, processamento e consulta posterior via chat.',
      chapters: [
        SummaryChapter(
          heading: 'Escopo',
          body: 'O nucleo inclui gravacao, upload, transcricao, resumo, biblioteca e chat contextual.',
        ),
        SummaryChapter(
          heading: 'Responsaveis',
          body: 'Biblioteca e exportacao ficaram com um responsavel dedicado para reduzir gargalos.',
        ),
      ],
    ),
    noteArtifact: const NoteArtifact(
      title: 'Sincronizacao de planejamento do lancamento',
      tags: ['lancamento', 'produto', 'ia'],
      highlights: [
        'v1 com gravacao, upload, resumo e chat',
        'biblioteca e exportacao em markdown como entregas criticas',
      ],
      actionItems: [
        'Instrumentar falhas do pipeline',
        'Adicionar retries claros para o usuario',
      ],
    ),
    chatSession: const ChatSession(
      id: 'session-demo',
      recordingId: 'demo-launch-sync',
      messages: [],
    ),
  ),
];
