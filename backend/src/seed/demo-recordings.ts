import { randomUUID } from 'node:crypto';

import type { Recording } from '../domain/types.js';

export const demoUserId = 'demo-user';

const recordingId = randomUUID();

export const demoRecordings: Recording[] = [
  {
    id: recordingId,
    userId: demoUserId,
    title: 'Sincronização de planejamento do lançamento',
    sourceType: 'upload',
    status: 'ready',
    createdAt: '2026-03-26T10:00:00.000Z',
    updatedAt: '2026-03-26T10:08:00.000Z',
    durationMs: 1920000,
    audioPath: 'demo/launch-planning.m4a',
    transcriptSegments: [
      {
        id: randomUUID(),
        recordingId,
        speakerLabel: 'Participante 1',
        startMs: 0,
        endMs: 18000,
        text: 'Vamos lançar o v1 com gravação, upload, resumo e chat sobre notas.',
      },
      {
        id: randomUUID(),
        recordingId,
        speakerLabel: 'Participante 2',
        startMs: 18000,
        endMs: 42000,
        text: 'Eu fico com a biblioteca, experiência de detalhe e exportação em markdown.',
      },
      {
        id: randomUUID(),
        recordingId,
        speakerLabel: 'Participante 1',
        startMs: 42000,
        endMs: 68000,
        text: 'Precisamos instrumentar falhas do pipeline e deixar retries claros para o usuário.',
      },
    ],
    summary: {
      overview:
        'A reunião alinhou um v1 enxuto com foco em captura de áudio, processamento e consulta posterior via chat.',
      chapters: [
        {
          heading: 'Escopo',
          body: 'O núcleo inclui gravação, upload, transcrição, resumo, biblioteca e chat contextual.',
        },
        {
          heading: 'Responsáveis',
          body: 'Biblioteca e exportação ficaram com um responsável dedicado para reduzir gargalos.',
        },
      ],
    },
    noteArtifact: {
      title: 'Sincronização de planejamento do lançamento',
      tags: ['lancamento', 'produto', 'ia'],
      highlights: [
        'v1 com gravação, upload, resumo e chat',
        'biblioteca e exportação em markdown como entregas críticas',
      ],
      actionItems: [
        'Instrumentar falhas do pipeline',
        'Adicionar retries claros para o usuário',
      ],
    },
    chatSession: {
      id: randomUUID(),
      recordingId,
      messages: [],
    },
  },
];
