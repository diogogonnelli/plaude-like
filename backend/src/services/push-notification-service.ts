import { getApps, initializeApp, cert, type App as FirebaseAdminApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import type { SupabaseClient } from '@supabase/supabase-js';

import type { Recording } from '../domain/types.js';
import { createSupabaseAdminClient } from '../lib/supabase-admin.js';
import { config } from '../lib/config.js';
import { ServiceError } from './service-errors.js';

export type PushDevicePlatform = 'android' | 'ios';

interface PushDeviceRecord {
  userId: string;
  token: string;
  platform: PushDevicePlatform;
  updatedAt: string;
}

export interface PushNotificationServiceLike {
  registerDevice(userId: string, token: string, platform: PushDevicePlatform): Promise<void>;
  unregisterDevice(userId: string, token: string): Promise<void>;
  notifyRecordingReady(recording: Recording): Promise<void>;
}

export class NoopPushNotificationService implements PushNotificationServiceLike {
  async registerDevice(): Promise<void> {}
  async unregisterDevice(): Promise<void> {}
  async notifyRecordingReady(): Promise<void> {}
}

export class PushNotificationService implements PushNotificationServiceLike {
  private readonly memoryTokens = new Map<string, Map<string, PushDeviceRecord>>();
  private readonly supabase: SupabaseClient | null;
  private readonly firebaseApp: FirebaseAdminApp | null;

  constructor() {
    this.supabase = createSupabaseAdminClient();
    this.firebaseApp = createFirebaseAdminApp();
  }

  async registerDevice(userId: string, token: string, platform: PushDevicePlatform): Promise<void> {
    const record: PushDeviceRecord = {
      userId,
      token,
      platform,
      updatedAt: new Date().toISOString(),
    };

    if (!this.supabase || !isUuid(userId)) {
      this.upsertMemory(record);
      return;
    }

    const { error } = await this.supabase
      .from('push_devices')
      .upsert(
        {
          user_id: userId,
          token,
          platform,
        },
        {
          onConflict: 'token',
        },
      );

    if (error) {
      throw new ServiceError(
        `Falha ao registrar device token: ${error.message}`,
        502,
        'push_device_upsert_failed',
      );
    }
  }

  async unregisterDevice(userId: string, token: string): Promise<void> {
    if (!this.supabase || !isUuid(userId)) {
      const devices = this.memoryTokens.get(userId);
      devices?.delete(token);
      if (devices?.size === 0) {
        this.memoryTokens.delete(userId);
      }
      return;
    }

    const { error } = await this.supabase
      .from('push_devices')
      .delete()
      .eq('user_id', userId)
      .eq('token', token);

    if (error) {
      throw new ServiceError(
        `Falha ao remover device token: ${error.message}`,
        502,
        'push_device_delete_failed',
      );
    }
  }

  async notifyRecordingReady(recording: Recording): Promise<void> {
    if (!this.firebaseApp) {
      return;
    }

    const devices = await this.listDevices(recording.createdByUserId);
    if (devices.length === 0) {
      return;
    }

    const uniqueTokens = [...new Set(devices.map((device) => device.token))];
    const response = await getMessaging(this.firebaseApp).sendEachForMulticast({
      tokens: uniqueTokens,
      notification: {
        title: 'GravAção: nota pronta',
        body: `"${recording.title}" terminou o processamento.`,
      },
      data: {
        type: 'recording_ready',
        recordingId: recording.id,
        projectId: recording.projectId ?? '',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'recording_updates',
          sound: 'default',
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    });

    const staleTokens: string[] = [];
    response.responses.forEach((item, index) => {
      if (!item.success && item.error?.code) {
        if (
          item.error.code === 'messaging/registration-token-not-registered' ||
          item.error.code === 'messaging/invalid-registration-token'
        ) {
          staleTokens.push(uniqueTokens[index]!);
        }
      }
    });

    if (staleTokens.length > 0) {
      await Promise.all(
        staleTokens.map((token) =>
          this.unregisterDevice(recording.createdByUserId, token).catch(() => undefined),
        ),
      );
    }
  }

  private async listDevices(userId: string): Promise<PushDeviceRecord[]> {
    if (!this.supabase || !isUuid(userId)) {
      return [...(this.memoryTokens.get(userId)?.values() ?? [])];
    }

    const { data, error } = await this.supabase
      .from('push_devices')
      .select('user_id, token, platform, updated_at')
      .eq('user_id', userId);

    if (error) {
      throw new ServiceError(
        `Falha ao listar devices de push: ${error.message}`,
        502,
        'push_device_list_failed',
      );
    }

    return (data ?? []).map((item) => ({
      userId: String(item.user_id),
      token: String(item.token),
      platform: item.platform as PushDevicePlatform,
      updatedAt: String(item.updated_at),
    }));
  }

  private upsertMemory(record: PushDeviceRecord) {
    const current = this.memoryTokens.get(record.userId) ?? new Map<string, PushDeviceRecord>();
    current.set(record.token, record);
    this.memoryTokens.set(record.userId, current);
  }
}

function createFirebaseAdminApp(): FirebaseAdminApp | null {
  const credential = resolveFirebaseCredential();
  if (!credential) {
    return null;
  }

  const existing = getApps().find((app) => app.name === 'gravacao-push');
  if (existing) {
    return existing;
  }

  return initializeApp(
    {
      credential: cert(credential),
      projectId: credential.projectId,
    },
    'gravacao-push',
  );
}

function resolveFirebaseCredential():
  | { projectId: string; clientEmail: string; privateKey: string }
  | null {
  if (config.FIREBASE_SERVICE_ACCOUNT_JSON) {
    const parsed = JSON.parse(config.FIREBASE_SERVICE_ACCOUNT_JSON) as {
      project_id?: string;
      client_email?: string;
      private_key?: string;
    };
    if (parsed.project_id && parsed.client_email && parsed.private_key) {
      return {
        projectId: parsed.project_id,
        clientEmail: parsed.client_email,
        privateKey: parsed.private_key.replace(/\\n/g, '\n'),
      };
    }
  }

  if (
    config.FIREBASE_PROJECT_ID &&
    config.FIREBASE_CLIENT_EMAIL &&
    config.FIREBASE_PRIVATE_KEY
  ) {
    return {
      projectId: config.FIREBASE_PROJECT_ID,
      clientEmail: config.FIREBASE_CLIENT_EMAIL,
      privateKey: config.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    };
  }

  return null;
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}
