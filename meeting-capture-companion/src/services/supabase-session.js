import { createClient } from '@supabase/supabase-js';

export class SupabaseSessionService {
  constructor(config, store) {
    this.config = config;
    this.store = store;
    this.client = createClient(config.supabaseUrl, config.supabaseAnonKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });
  }

  async bootstrap() {
    const session = this.store.getSession();
    if (!session?.accessToken || !session?.refreshToken) {
      return null;
    }

    const { data, error } = await this.client.auth.setSession({
      access_token: session.accessToken,
      refresh_token: session.refreshToken,
    });

    if (error || !data.session || !data.user) {
      await this.store.clearSession();
      return null;
    }

    const nextSession = {
      accessToken: data.session.access_token,
      refreshToken: data.session.refresh_token,
      email: data.user.email ?? null,
      userId: data.user.id,
      expiresAt: data.session.expires_at ?? null,
    };

    await this.store.setSession(nextSession);
    return nextSession;
  }

  getSession() {
    return this.store.getSession();
  }

  getAccessToken() {
    return this.store.getSession()?.accessToken ?? null;
  }

  async signIn(email, password) {
    const { data, error } = await this.client.auth.signInWithPassword({ email, password });
    if (error || !data.session || !data.user) {
      throw new Error(error?.message ?? 'Failed to sign in.');
    }

    const session = {
      accessToken: data.session.access_token,
      refreshToken: data.session.refresh_token,
      email: data.user.email ?? email,
      userId: data.user.id,
      expiresAt: data.session.expires_at ?? null,
    };

    await this.store.setSession(session);
    return session;
  }

  async signOut() {
    const accessToken = this.getAccessToken();
    if (accessToken) {
      await this.client.auth.signOut().catch(() => undefined);
    }

    await this.store.clearSession();
  }
}
