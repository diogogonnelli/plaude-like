import type express from 'express';

import { requireSupabaseAdminClient, hasSupabasePersistenceConfig } from '../lib/supabase-admin.js';
import { ServiceError } from '../services/service-errors.js';

const userHeader = 'x-user-id';

export type AuthSource = 'supabase' | 'dev-header' | 'dev-default';

export interface RequestAuthProfile {
  id: string;
  code: string;
  name: string;
}

export interface RequestAuth {
  userId: string;
  email: string | null;
  fullName: string | null;
  isActive: boolean;
  profile: RequestAuthProfile | null;
  source: AuthSource;
}

export interface RequestAuthProvider {
  getRequestAuth(request: express.Request): Promise<RequestAuth>;
  ensureAdmin(auth: RequestAuth): Promise<void>;
  isAuthEnforced(): boolean;
}

export class SupabaseRequestAuthProvider implements RequestAuthProvider {
  isAuthEnforced(): boolean {
    return hasSupabasePersistenceConfig();
  }

  async getRequestAuth(request: express.Request): Promise<RequestAuth> {
    const cached = requestAuthCache.get(request);
    if (cached) {
      return cached;
    }

    const resolved = this.isAuthEnforced()
      ? await this.resolveSupabaseAuth(request)
      : this.resolveDevelopmentAuth(request);

    requestAuthCache.set(request, resolved);
    return resolved;
  }

  async ensureAdmin(auth: RequestAuth): Promise<void> {
    if (!this.isAuthEnforced()) {
      if (auth.userId !== 'demo-user') {
        throw new ServiceError('Admin access denied.', 403, 'admin_access_denied');
      }
      return;
    }

    if (!auth.isActive || auth.profile?.code !== 'admin') {
      throw new ServiceError('Admin access denied.', 403, 'admin_access_denied');
    }
  }

  private resolveDevelopmentAuth(request: express.Request): RequestAuth {
    const explicitUserId = request.header(userHeader)?.trim();
    if (explicitUserId) {
      return {
        userId: explicitUserId,
        email: null,
        fullName: explicitUserId === 'demo-user' ? 'Usuário demo' : null,
        isActive: true,
        profile: explicitUserId === 'demo-user'
          ? {
              id: 'profile-admin',
              code: 'admin',
              name: 'Administrador',
            }
          : null,
        source: 'dev-header',
      };
    }

    return {
      userId: 'demo-user',
      email: null,
      fullName: 'Usuário demo',
      isActive: true,
      profile: {
        id: 'profile-admin',
        code: 'admin',
        name: 'Administrador',
      },
      source: 'dev-default',
    };
  }

  private async resolveSupabaseAuth(request: express.Request): Promise<RequestAuth> {
    const authorization = request.header('authorization')?.trim();
    if (!authorization?.toLowerCase().startsWith('bearer ')) {
      throw new ServiceError('Authorization bearer token is required.', 401, 'auth_token_required');
    }

    const token = authorization.slice('Bearer '.length).trim();
    if (!token) {
      throw new ServiceError('Authorization bearer token is required.', 401, 'auth_token_required');
    }

    const supabase = requireSupabaseAdminClient();
    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data.user) {
      throw new ServiceError('Invalid or expired access token.', 401, 'auth_token_invalid');
    }

    const { data: directoryUser, error: directoryError } = await supabase
      .from('users')
      .select(
        'id,email,full_name,is_active,profile:profiles!users_profile_id_fkey(id,code,name)',
      )
      .eq('id', data.user.id)
      .maybeSingle();

    if (directoryError) {
      throw new ServiceError(
        `Failed to load user directory entry: ${directoryError.message}`,
        502,
        'user_directory_lookup_failed',
      );
    }

    if (!directoryUser) {
      throw new ServiceError('Authenticated user is not registered.', 403, 'auth_user_not_registered');
    }

    if (directoryUser.is_active === false) {
      throw new ServiceError('Authenticated user is inactive.', 403, 'auth_user_inactive');
    }

    const profile = normalizeProfile((directoryUser as { profile?: unknown }).profile);

    return {
      userId: data.user.id,
      email: (directoryUser.email as string | null | undefined) ?? data.user.email ?? null,
      fullName: (directoryUser.full_name as string | null | undefined) ?? null,
      isActive: directoryUser.is_active !== false,
      profile,
      source: 'supabase',
    };
  }
}

const requestAuthCache = new WeakMap<express.Request, RequestAuth>();

function normalizeProfile(value: unknown): RequestAuthProfile | null {
  const record = Array.isArray(value) ? value[0] : value;
  if (!record || typeof record !== 'object') {
    return null;
  }

  const profile = record as Record<string, unknown>;
  return {
    id: String(profile.id),
    code: String(profile.code),
    name: String(profile.name),
  };
}
