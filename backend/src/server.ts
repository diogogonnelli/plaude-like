import { buildApp } from './http/build-app.js';
import { config } from './lib/config.js';
import { MemoryRecordingRepository } from './repositories/memory-recording-repository.js';
import { demoRecordings } from './seed/demo-recordings.js';
import { PlainTextExportProvider } from './services/export-provider.js';
import { MockAiProvider } from './services/mock-ai-provider.js';
import { OpenAiProvider } from './services/openai-ai-provider.js';
import { RecordingService } from './services/recording-service.js';

const repository = new MemoryRecordingRepository(demoRecordings);
const aiProvider = config.AI_PROVIDER === 'openai' ? new OpenAiProvider() : new MockAiProvider();
const exportProvider = new PlainTextExportProvider();
const recordingService = new RecordingService(repository, aiProvider, exportProvider);

const app = buildApp(recordingService);

app.listen(config.PORT, () => {
  console.log(`plaude-like-backend listening on ${config.APP_BASE_URL}`);
});
