import { buildApp } from './http/build-app.js';
import { config } from './lib/config.js';
import { MemoryRecordingRepository } from './repositories/memory-recording-repository.js';
import { demoRecordings } from './seed/demo-recordings.js';
import { PlainTextExportProvider } from './services/export-provider.js';
import { MockAiProvider } from './services/mock-ai-provider.js';
import { OpenAiProvider } from './services/openai-ai-provider.js';
import { PushNotificationService } from './services/push-notification-service.js';
import { RecordingService } from './services/recording-service.js';

const repository = new MemoryRecordingRepository(demoRecordings);
const aiProvider = config.AI_PROVIDER === 'openai' ? new OpenAiProvider() : new MockAiProvider();
const exportProvider = new PlainTextExportProvider();
const pushNotificationService = new PushNotificationService();
const recordingService = new RecordingService(
  repository,
  aiProvider,
  exportProvider,
  pushNotificationService,
);

const app = buildApp(recordingService, {
  pushNotificationService,
});

app.listen(config.PORT, () => {
  console.log(`plaude-like-backend listening on ${config.APP_BASE_URL}`);
});
