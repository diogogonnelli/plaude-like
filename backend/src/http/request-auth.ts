import type express from 'express';

import { requireSupabaseAdminClient, hasSupabasePersistenceConfig } from '../lib/supabase-admin.js';
import { ServiceError } from '../services/service-errors.js';

const userHeader = 'x-user-id';

export type AuthSource = 'supabase' | 'dev-header' | 'dev-default';

export interface RequestAuth {
  userId: string;
  email: string | null;
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

    const supabase = requireSupabaseAdminClient();
    const { data, error } = await supabase
      .from('admin_users')
      .select('user_id')
      .eq('user_id', auth.userId)
      .maybeSingle();

    if (error) {
      throw new ServiceError(
        `Failed to validate admin access: ${error.message}`,
        502,
        'admin_auth_validation_failed',
      );
    }

    if (!data) {
      throw new ServiceError('Admin access denied.', 403, 'admin_access_denied');
    }
  }

  private resolveDevelopmentAuth(request: express.Request): RequestAuth {
    const explicitUserId = request.header(userHeader)?.trim();
    if (explicitUserId) {
      return {
        userId: explicitUserId,
        email: null,
        source: 'dev-header',
      };
    }

    return {
      userId: 'demo-user',
      email: null,
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

    return {
      userId: data.user.id,
      email: data.user.email ?? null,
      source: 'supabase',
    };
  }
}

const requestAuthCache = new WeakMap<express.Request, RequestAuth>();
