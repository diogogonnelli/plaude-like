import type { ExportProvider } from '../domain/contracts.js';
import type { ExportArtifact, Recording } from '../domain/types.js';

export class PlainTextExportProvider implements ExportProvider {
  build(recording: Recording, format: 'txt' | 'md'): ExportArtifact {
    const transcript = recording.transcriptSegments
      .map((segment) => `${segment.speakerLabel} [${segment.startMs}-${segment.endMs}]: ${segment.text}`)
      .join('\n');

    const content = format === 'md'
      ? [
          `# ${recording.noteArtifact?.title ?? recording.title}`,
          '',
          `Status: ${translateStatus(recording.status)}`,
          '',
          '## Resumo',
          recording.summary?.overview ?? 'Sem resumo',
          '',
          '## Destaques',
          ...(recording.noteArtifact?.highlights ?? []).map((item) => `- ${item}`),
          '',
          '## Itens de ação',
          ...(recording.noteArtifact?.actionItems ?? []).map((item) => `- ${item}`),
          '',
          '## Transcrição',
          '```text',
          transcript,
          '```',
        ].join('\n')
      : [
          recording.noteArtifact?.title ?? recording.title,
          '',
          `Status: ${translateStatus(recording.status)}`,
          '',
          'Resumo',
          recording.summary?.overview ?? 'Sem resumo',
          '',
          'Transcrição',
          transcript,
        ].join('\n');

    return {
      format,
      fileName: `${recording.id}.${format}`,
      contentType: format === 'md' ? 'text/markdown' : 'text/plain',
      body: content,
    };
  }
}

function translateStatus(status: Recording['status']): string {
  switch (status) {
    case 'uploaded':
      return 'Enviado';
    case 'processing_transcript':
      return 'Transcrevendo';
    case 'processing_summary':
      return 'Resumindo';
    case 'indexing':
      return 'Indexando';
    case 'ready':
      return 'Pronto';
    case 'failed':
      return 'Falhou';
  }
}
