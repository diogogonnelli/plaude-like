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
          `Status: ${recording.status}`,
          '',
          '## Overview',
          recording.summary?.overview ?? 'No summary',
          '',
          '## Highlights',
          ...(recording.noteArtifact?.highlights ?? []).map((item) => `- ${item}`),
          '',
          '## Action items',
          ...(recording.noteArtifact?.actionItems ?? []).map((item) => `- ${item}`),
          '',
          '## Transcript',
          '```text',
          transcript,
          '```',
        ].join('\n')
      : [
          recording.noteArtifact?.title ?? recording.title,
          '',
          `Status: ${recording.status}`,
          '',
          'Overview',
          recording.summary?.overview ?? 'No summary',
          '',
          'Transcript',
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
