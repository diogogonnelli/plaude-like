import { createClient, type Session } from '@supabase/supabase-js';
import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type FormEvent,
  type ReactNode,
} from 'react';
import {
  BrowserRouter,
  Link,
  Navigate,
  NavLink,
  Outlet,
  Route,
  Routes,
  useLocation,
  useNavigate,
  useParams,
  useSearchParams,
} from 'react-router-dom';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8787';
const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL ?? '';
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY ?? '';
const HAS_SUPABASE_CONFIG = SUPABASE_URL.length > 0 && SUPABASE_ANON_KEY.length > 0;

const supabase = HAS_SUPABASE_CONFIG
  ? createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
      },
    })
  : null;

type ProjectStatus = 'active' | 'archived';
type MemberRole = 'owner' | 'member';
type RecordingStatus =
  | 'uploaded'
  | 'processing_transcript'
  | 'processing_summary'
  | 'indexing'
  | 'ready'
  | 'failed';

type Project = {
  id: string;
  name: string;
  slug: string;
  status: ProjectStatus;
  createdAt: string;
  updatedAt: string;
};

type ProjectMember = {
  projectId: string;
  userId: string;
  role: MemberRole;
  createdAt: string;
};

type TranscriptSegment = {
  id: string;
  recordingId: string;
  speakerLabel: string;
  startMs: number;
  endMs: number;
  text: string;
};

type SummaryChapter = {
  heading: string;
  body: string;
};

type RecordingSummary = {
  overview: string;
  chapters: SummaryChapter[];
};

type NoteArtifact = {
  title: string;
  tags: string[];
  highlights: string[];
  actionItems: string[];
};

type Recording = {
  id: string;
  userId: string;
  createdByUserId: string;
  projectId: string;
  title: string;
  sourceType: 'microphone' | 'upload';
  status: RecordingStatus;
  createdAt: string;
  updatedAt: string;
  durationMs?: number | null;
  audioPath?: string | null;
  transcriptionProvider?: string | null;
  transcriptionJobId?: string | null;
  transcriptionStartedAt?: string | null;
  transcriptionCompletedAt?: string | null;
  transcriptSegments: TranscriptSegment[];
  summary?: RecordingSummary | null;
  noteArtifact?: NoteArtifact | null;
  lastError?: string | null;
};

type JobRow = {
  recordingId: string;
  projectId: string;
  title: string;
  status: RecordingStatus;
  transcriptionProvider?: string | null;
  transcriptionJobId?: string | null;
  transcriptionStartedAt?: string | null;
  transcriptionCompletedAt?: string | null;
  lastError?: string | null;
};

type ProviderData = {
  aiProvider: string;
  transcriptionProvider: string;
  assemblyAiSpeechModel: string;
  supabasePersistenceMode: string;
  supabaseStorageBucket: string;
};

type AdminMe = {
  userId: string;
  email: string | null;
  source: string;
  authEnforced: boolean;
  isAdmin: boolean;
};

type ApiError = Error & {
  status: number;
  code?: string;
  details?: unknown;
};

type SessionContextValue = {
  session: Session | null;
  ready: boolean;
  hasSupabaseConfig: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
};

const SessionContext = createContext<SessionContextValue | null>(null);

export function App() {
  return (
    <SessionProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route element={<ProtectedAdminApp />}>
            <Route index element={<Navigate to="/projects" replace />} />
            <Route path="/projects" element={<ProjectsPage />} />
            <Route path="/projects/:projectId/members" element={<MembersPage />} />
            <Route path="/recordings" element={<RecordingsPage />} />
            <Route path="/recordings/:recordingId" element={<RecordingsPage />} />
            <Route path="/jobs" element={<JobsPage />} />
            <Route path="/providers" element={<ProvidersPage />} />
          </Route>
          <Route path="*" element={<Navigate to="/projects" replace />} />
        </Routes>
      </BrowserRouter>
    </SessionProvider>
  );
}

function SessionProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [ready, setReady] = useState(!HAS_SUPABASE_CONFIG);

  useEffect(() => {
    if (!supabase) {
      return;
    }

    let mounted = true;

    supabase.auth.getSession().then(({ data }) => {
      if (!mounted) return;
      setSession(data.session ?? null);
      setReady(true);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      if (!mounted) return;
      setSession(nextSession);
      setReady(true);
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  const value = useMemo<SessionContextValue>(
    () => ({
      session,
      ready,
      hasSupabaseConfig: HAS_SUPABASE_CONFIG,
      async signIn(email, password) {
        if (!supabase) {
          throw new Error('Supabase não está configurado no admin-web.');
        }

        const { error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) {
          throw error;
        }
      },
      async signOut() {
        if (!supabase) {
          return;
        }

        const { error } = await supabase.auth.signOut();
        if (error) {
          throw error;
        }
      },
    }),
    [ready, session],
  );

  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

function useSession() {
  const context = useContext(SessionContext);
  if (!context) {
    throw new Error('Session context is unavailable.');
  }
  return context;
}

async function apiRequest<T>(path: string, token: string, init: RequestInit = {}): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...init,
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${token}`,
      ...(init.headers ?? {}),
    },
  });

  const text = await response.text();
  const payload = text ? (JSON.parse(text) as Record<string, unknown>) : {};

  if (!response.ok) {
    const error = new Error(
      typeof payload.error === 'string' ? payload.error : `Request failed with ${response.status}`,
    ) as ApiError;
    error.status = response.status;
    error.code = typeof payload.code === 'string' ? payload.code : undefined;
    error.details = payload.details;
    throw error;
  }

  return payload as T;
}

function slugify(value: string) {
  return (
    value
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '')
      .slice(0, 60) || 'project'
  );
}

function formatDate(value?: string | null) {
  if (!value) return '—';
  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(value));
}

function formatTimestamp(milliseconds: number) {
  const minutes = Math.floor(milliseconds / 60000)
    .toString()
    .padStart(2, '0');
  const seconds = Math.floor((milliseconds % 60000) / 1000)
    .toString()
    .padStart(2, '0');
  return `${minutes}:${seconds}`;
}

function statusLabel(status: RecordingStatus | ProjectStatus | MemberRole) {
  switch (status) {
    case 'active':
      return 'Ativo';
    case 'archived':
      return 'Arquivado';
    case 'owner':
      return 'Owner';
    case 'member':
      return 'Member';
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

function useAccessToken() {
  const { session } = useSession();
  return session?.access_token ?? '';
}

function ProtectedAdminApp() {
  const { session, ready, hasSupabaseConfig, signOut } = useSession();
  const navigate = useNavigate();
  const [adminMe, setAdminMe] = useState<AdminMe | null>(null);
  const [status, setStatus] = useState<'checking' | 'allowed' | 'denied'>('checking');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!ready) {
      return;
    }

    if (!hasSupabaseConfig) {
      setStatus('denied');
      setError('Defina VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY para habilitar o admin autenticado.');
      return;
    }

    if (!session?.access_token) {
      setStatus('checking');
      setAdminMe(null);
      return;
    }

    let cancelled = false;
    setStatus('checking');
    setError(null);

    void apiRequest<{ data: AdminMe }>('/admin/me', session.access_token)
      .then((payload) => {
        if (cancelled) return;
        setAdminMe(payload.data);
        setStatus('allowed');
      })
      .catch((requestError: ApiError) => {
        if (cancelled) return;
        if (requestError.status === 401) {
          void signOut();
          return;
        }

        setAdminMe(null);
        setStatus('denied');
        setError(requestError.message);
      });

    return () => {
      cancelled = true;
    };
  }, [hasSupabaseConfig, ready, session?.access_token, signOut]);

  if (!ready) {
    return <FullscreenState title="Carregando sessão" description="Validando autenticação do backoffice." />;
  }

  if (!session) {
    return <Navigate to="/login" replace />;
  }

  if (status === 'checking') {
    return <FullscreenState title="Validando acesso" description="Confirmando permissões administrativas." />;
  }

  if (status === 'denied' || !adminMe) {
    return (
      <FullscreenState
        title="Acesso administrativo negado"
        description={error ?? 'Sua conta autenticada não está na allowlist de administradores.'}
        actions={
          <>
            <button className="button ghost" onClick={() => void signOut()}>
              Sair
            </button>
            <button className="button primary" onClick={() => navigate('/login', { replace: true })}>
              Trocar conta
            </button>
          </>
        }
      />
    );
  }

  return <AdminLayout adminMe={adminMe} onSignOut={signOut} />;
}

function FullscreenState(props: {
  title: string;
  description: string;
  actions?: ReactNode;
}) {
  return (
    <div className="auth-shell">
      <div className="auth-card">
        <div className="auth-kicker">Plaude Admin</div>
        <h1>{props.title}</h1>
        <p>{props.description}</p>
        {props.actions ? <div className="auth-actions">{props.actions}</div> : null}
      </div>
    </div>
  );
}

function LoginPage() {
  const { session, ready, hasSupabaseConfig, signIn } = useSession();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (ready && session) {
      navigate('/projects', { replace: true });
    }
  }, [navigate, ready, session]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setError(null);

    try {
      await signIn(email, password);
      navigate('/projects', { replace: true });
    } catch (signInError) {
      setError(signInError instanceof Error ? signInError.message : 'Falha ao autenticar.');
    } finally {
      setLoading(false);
    }
  }

  if (!ready) {
    return <FullscreenState title="Carregando sessão" description="Inicializando cliente de autenticação." />;
  }

  return (
    <div className="auth-shell">
      <div className="auth-card">
        <div className="auth-kicker">Backoffice operacional</div>
        <h1>Entrar no Plaude Admin</h1>
        <p>Use uma conta provisionada no Supabase Auth e já autorizada na tabela `admin_users`.</p>
        {!hasSupabaseConfig ? (
          <div className="inline-error">
            Configure `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY` para habilitar o login.
          </div>
        ) : null}
        {error ? <div className="inline-error">{error}</div> : null}
        <form className="auth-form" onSubmit={handleSubmit}>
          <label className="field">
            <span>Email</span>
            <input
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="admin@empresa.com"
              disabled={!hasSupabaseConfig || loading}
              required
            />
          </label>
          <label className="field">
            <span>Senha</span>
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder="••••••••"
              disabled={!hasSupabaseConfig || loading}
              required
            />
          </label>
          <button className="button primary wide" type="submit" disabled={!hasSupabaseConfig || loading}>
            {loading ? 'Entrando...' : 'Entrar'}
          </button>
        </form>
      </div>
    </div>
  );
}

function AdminLayout(props: { adminMe: AdminMe; onSignOut: () => Promise<void> }) {
  const location = useLocation();
  const navigate = useNavigate();

  const sectionTitle = useMemo(() => {
    if (location.pathname.startsWith('/recordings')) return 'Gravações';
    if (location.pathname.startsWith('/jobs')) return 'Jobs';
    if (location.pathname.startsWith('/providers')) return 'Providers';
    if (location.pathname.includes('/members')) return 'Membros';
    return 'Projetos';
  }, [location.pathname]);

  return (
    <div className="admin-shell">
      <aside className="sidebar">
        <div className="brand-card">
          <div className="brand-kicker">Plaude Admin</div>
          <h1>Operação de áudio</h1>
          <p>Projetos, membros, gravações e jobs com foco em leitura rápida e ação imediata.</p>
        </div>

        <nav className="nav-stack">
          <NavLink to="/projects" className={({ isActive }) => navClass(isActive)}>
            Projetos
          </NavLink>
          <NavLink to="/recordings" className={({ isActive }) => navClass(isActive)}>
            Gravações
          </NavLink>
          <NavLink to="/jobs" className={({ isActive }) => navClass(isActive)}>
            Jobs
          </NavLink>
          <NavLink to="/providers" className={({ isActive }) => navClass(isActive)}>
            Providers
          </NavLink>
        </nav>

        <div className="sidebar-foot">
          <div className="sidebar-meta">
            <strong>{props.adminMe.email ?? props.adminMe.userId}</strong>
            <span>{props.adminMe.authEnforced ? 'JWT Supabase ativo' : 'Modo local'}</span>
          </div>
          <button
            className="button ghost wide"
            onClick={() => {
              void props.onSignOut().finally(() => navigate('/login', { replace: true }));
            }}
          >
            Sair
          </button>
        </div>
      </aside>

      <main className="content-shell">
        <header className="topbar">
          <div>
            <div className="eyebrow">Admin operacional</div>
            <h2>{sectionTitle}</h2>
            <p>Superfícies roteadas, estados claros e ações administrativas com contexto por URL.</p>
          </div>
          <div className="topbar-badge">
            <span>API</span>
            <strong>{API_BASE_URL.replace(/^https?:\/\//, '')}</strong>
          </div>
        </header>

        <Outlet />
      </main>
    </div>
  );
}

function navClass(isActive: boolean) {
  return isActive ? 'nav-link active' : 'nav-link';
}

function PageCard(props: { title: string; subtitle?: string; actions?: ReactNode; children: ReactNode }) {
  return (
    <section className="page-card">
      <div className="section-header">
        <div>
          <h3>{props.title}</h3>
          {props.subtitle ? <p>{props.subtitle}</p> : null}
        </div>
        {props.actions ? <div className="section-actions">{props.actions}</div> : null}
      </div>
      {props.children}
    </section>
  );
}

function StatusPill(props: { status: RecordingStatus | ProjectStatus | MemberRole }) {
  return <span className={`status-pill status-${props.status}`}>{statusLabel(props.status as never)}</span>;
}

function TableEmpty(props: { title: string; description: string }) {
  return (
    <div className="empty-state">
      <strong>{props.title}</strong>
      <span>{props.description}</span>
    </div>
  );
}

function InlineFeedback(props: { tone: 'error' | 'success'; message: string }) {
  return <div className={`inline-${props.tone}`}>{props.message}</div>;
}

function ProjectsPage() {
  const token = useAccessToken();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<string | null>(null);
  const [editorState, setEditorState] = useState<{ mode: 'create' | 'edit'; project?: Project } | null>(null);

  const query = searchParams.get('query') ?? '';
  const status = (searchParams.get('status') as ProjectStatus | null) ?? '';

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);

    const params = new URLSearchParams();
    if (query) params.set('query', query);
    if (status) params.set('status', status);

    void apiRequest<{ data: Project[] }>(`/admin/projects?${params.toString()}`, token)
      .then((payload) => {
        if (cancelled) return;
        setProjects(payload.data);
      })
      .catch((requestError: ApiError) => {
        if (cancelled) return;
        setError(requestError.message);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [query, status, token]);

  function updateFilters(next: { query?: string; status?: string }) {
    const params = new URLSearchParams(searchParams);
    if (next.query !== undefined) {
      next.query ? params.set('query', next.query) : params.delete('query');
    }
    if (next.status !== undefined) {
      next.status ? params.set('status', next.status) : params.delete('status');
    }
    setSearchParams(params, { replace: true });
  }

  async function handleSaveProject(payload: { id?: string; name: string; slug: string; status: ProjectStatus }) {
    setFeedback(null);
    setError(null);
    try {
      if (payload.id) {
        await apiRequest<{ data: Project }>(`/admin/projects/${payload.id}`, token, {
          method: 'PATCH',
          body: JSON.stringify({
            name: payload.name,
            slug: payload.slug,
            status: payload.status,
          }),
        });
        setFeedback('Projeto atualizado com sucesso.');
      } else {
        await apiRequest<{ data: Project }>('/admin/projects', token, {
          method: 'POST',
          body: JSON.stringify({
            name: payload.name,
            slug: payload.slug,
          }),
        });
        setFeedback('Projeto criado com sucesso.');
      }
      setEditorState(null);
      updateFilters({});
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Falha ao salvar projeto.');
    }
  }

  return (
    <div className="page-stack">
      <PageCard
        title="Catálogo de projetos"
        subtitle="CRUD visual real com filtros por URL, slug editável e status operacional."
        actions={
          <button className="button primary" onClick={() => setEditorState({ mode: 'create' })}>
            Novo projeto
          </button>
        }
      >
        <div className="filters-row">
          <label className="field grow">
            <span>Buscar</span>
            <input value={query} onChange={(event) => updateFilters({ query: event.target.value })} placeholder="Nome, slug ou id" />
          </label>
          <label className="field">
            <span>Status</span>
            <select value={status} onChange={(event) => updateFilters({ status: event.target.value })}>
              <option value="">Todos</option>
              <option value="active">Ativo</option>
              <option value="archived">Arquivado</option>
            </select>
          </label>
        </div>

        {feedback ? <InlineFeedback tone="success" message={feedback} /> : null}
        {error ? <InlineFeedback tone="error" message={error} /> : null}

        {loading ? (
          <TableEmpty title="Carregando projetos" description="Buscando catálogo administrativo." />
        ) : projects.length === 0 ? (
          <TableEmpty title="Nenhum projeto encontrado" description="Ajuste os filtros ou crie um novo projeto." />
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Nome</th>
                  <th>Slug</th>
                  <th>Status</th>
                  <th>Atualizado</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {projects.map((project) => (
                  <tr key={project.id}>
                    <td>
                      <div className="table-primary">{project.name}</div>
                      <div className="table-secondary">{project.id}</div>
                    </td>
                    <td>{project.slug}</td>
                    <td>
                      <StatusPill status={project.status} />
                    </td>
                    <td>{formatDate(project.updatedAt)}</td>
                    <td>
                      <div className="row-actions">
                        <button className="button ghost small" onClick={() => setEditorState({ mode: 'edit', project })}>
                          Editar
                        </button>
                        <button className="button ghost small" onClick={() => navigate(`/projects/${project.id}/members`)}>
                          Membros
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </PageCard>

      {editorState ? (
        <ProjectEditorDialog
          key={editorState.project?.id ?? 'create'}
          mode={editorState.mode}
          project={editorState.project}
          onClose={() => setEditorState(null)}
          onSave={handleSaveProject}
        />
      ) : null}
    </div>
  );
}

function ProjectEditorDialog(props: {
  mode: 'create' | 'edit';
  project?: Project;
  onClose: () => void;
  onSave: (payload: { id?: string; name: string; slug: string; status: ProjectStatus }) => Promise<void>;
}) {
  const [name, setName] = useState(props.project?.name ?? '');
  const [slug, setSlug] = useState(props.project?.slug ?? '');
  const [status, setStatus] = useState<ProjectStatus>(props.project?.status ?? 'active');
  const [slugDirty, setSlugDirty] = useState(Boolean(props.project?.slug));
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!slugDirty) {
      setSlug(slugify(name));
    }
  }, [name, slugDirty]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSaving(true);
    try {
      await props.onSave({
        id: props.project?.id,
        name,
        slug,
        status,
      });
    } finally {
      setSaving(false);
    }
  }

  return (
    <DialogFrame
      title={props.mode === 'create' ? 'Novo projeto' : 'Editar projeto'}
      subtitle="Nome, slug e status operacional."
      onClose={props.onClose}
    >
      <form className="dialog-form" onSubmit={handleSubmit}>
        <label className="field">
          <span>Nome</span>
          <input value={name} onChange={(event) => setName(event.target.value)} required />
        </label>
        <label className="field">
          <span>Slug</span>
          <input
            value={slug}
            onChange={(event) => {
              setSlugDirty(true);
              setSlug(slugify(event.target.value));
            }}
            required
          />
        </label>
        <label className="field">
          <span>Status</span>
          <select value={status} onChange={(event) => setStatus(event.target.value as ProjectStatus)}>
            <option value="active">Ativo</option>
            <option value="archived">Arquivado</option>
          </select>
        </label>
        <div className="dialog-actions">
          <button type="button" className="button ghost" onClick={props.onClose}>
            Cancelar
          </button>
          <button type="submit" className="button primary" disabled={saving}>
            {saving ? 'Salvando...' : props.mode === 'create' ? 'Criar projeto' : 'Salvar alterações'}
          </button>
        </div>
      </form>
    </DialogFrame>
  );
}

function MembersPage() {
  const token = useAccessToken();
  const navigate = useNavigate();
  const { projectId = '' } = useParams();
  const [projects, setProjects] = useState<Project[]>([]);
  const [project, setProject] = useState<Project | null>(null);
  const [members, setMembers] = useState<ProjectMember[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<string | null>(null);
  const [userId, setUserId] = useState('');
  const [role, setRole] = useState<MemberRole>('member');
  const [submitting, setSubmitting] = useState(false);
  const [pendingRemoval, setPendingRemoval] = useState<ProjectMember | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setLoading(true);
      setError(null);

      try {
        const [projectsPayload, projectPayload, membersPayload] = await Promise.all([
          apiRequest<{ data: Project[] }>('/admin/projects', token),
          apiRequest<{ data: Project }>(`/admin/projects/${projectId}`, token),
          apiRequest<{ data: ProjectMember[] }>(`/admin/projects/${projectId}/members`, token),
        ]);

        if (cancelled) return;
        setProjects(projectsPayload.data);
        setProject(projectPayload.data);
        setMembers(membersPayload.data);
      } catch (requestError) {
        if (cancelled) return;
        setError(requestError instanceof Error ? requestError.message : 'Falha ao carregar membros.');
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    void load();

    return () => {
      cancelled = true;
    };
  }, [projectId, token]);

  async function handleAddMember(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSubmitting(true);
    setFeedback(null);
    setError(null);
    try {
      const payload = await apiRequest<{ data: ProjectMember }>(`/admin/projects/${projectId}/members`, token, {
        method: 'POST',
        body: JSON.stringify({ userId, role }),
      });
      setMembers((current) => [...current.filter((member) => member.userId !== payload.data.userId), payload.data]);
      setUserId('');
      setRole('member');
      setFeedback('Membro adicionado com sucesso.');
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Falha ao adicionar membro.');
    } finally {
      setSubmitting(false);
    }
  }

  async function handleRemoveMember() {
    if (!pendingRemoval) return;
    setError(null);
    setFeedback(null);
    try {
      await apiRequest<Record<string, never>>(
        `/admin/projects/${projectId}/members/${pendingRemoval.userId}`,
        token,
        { method: 'DELETE' },
      );
      setMembers((current) => current.filter((member) => member.userId !== pendingRemoval.userId));
      setFeedback('Membro removido com sucesso.');
      setPendingRemoval(null);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Falha ao remover membro.');
    }
  }

  return (
    <div className="page-stack">
      <PageCard
        title="Membros do projeto"
        subtitle="Gestão administrativa direta por `userId`, com confirmação explícita para remoção."
        actions={
          <label className="field compact">
            <span>Projeto</span>
            <select value={projectId} onChange={(event) => navigate(`/projects/${event.target.value}/members`)}>
              {projects.map((item) => (
                <option key={item.id} value={item.id}>
                  {item.name}
                </option>
              ))}
            </select>
          </label>
        }
      >
        {project ? (
          <div className="context-strip">
            <div>
              <strong>{project.name}</strong>
              <span>{project.slug}</span>
            </div>
            <StatusPill status={project.status} />
          </div>
        ) : null}

        <div className="dual-grid">
          <form className="form-card" onSubmit={handleAddMember}>
            <h4>Adicionar membro</h4>
            <label className="field">
              <span>User ID</span>
              <input value={userId} onChange={(event) => setUserId(event.target.value)} placeholder="UUID do usuário" required />
            </label>
            <label className="field">
              <span>Role</span>
              <select value={role} onChange={(event) => setRole(event.target.value as MemberRole)}>
                <option value="member">member</option>
                <option value="owner">owner</option>
              </select>
            </label>
            <button className="button primary" type="submit" disabled={submitting}>
              {submitting ? 'Adicionando...' : 'Adicionar membro'}
            </button>
          </form>

          <div className="form-card neutral">
            <h4>Critério operacional</h4>
            <p>Admins têm visão global. Membership continua controlando o acesso do produto principal por projeto.</p>
            <Link to="/projects" className="text-link">
              Voltar para projetos
            </Link>
          </div>
        </div>

        {feedback ? <InlineFeedback tone="success" message={feedback} /> : null}
        {error ? <InlineFeedback tone="error" message={error} /> : null}

        {loading ? (
          <TableEmpty title="Carregando membros" description="Buscando memberships do projeto selecionado." />
        ) : members.length === 0 ? (
          <TableEmpty title="Sem membros" description="Adicione pelo menos um usuário para habilitar acesso ao projeto." />
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>User ID</th>
                  <th>Role</th>
                  <th>Criado em</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {members.map((member) => (
                  <tr key={`${member.projectId}-${member.userId}`}>
                    <td className="table-primary">{member.userId}</td>
                    <td>
                      <StatusPill status={member.role} />
                    </td>
                    <td>{formatDate(member.createdAt)}</td>
                    <td>
                      <button className="button danger small" onClick={() => setPendingRemoval(member)}>
                        Remover
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </PageCard>

      {pendingRemoval ? (
        <DialogFrame
          title="Remover membro"
          subtitle={`Confirme a remoção de ${pendingRemoval.userId} deste projeto.`}
          onClose={() => setPendingRemoval(null)}
        >
          <div className="dialog-actions">
            <button className="button ghost" onClick={() => setPendingRemoval(null)}>
              Cancelar
            </button>
            <button className="button danger" onClick={handleRemoveMember}>
              Confirmar remoção
            </button>
          </div>
        </DialogFrame>
      ) : null}
    </div>
  );
}

function RecordingsPage() {
  const token = useAccessToken();
  const navigate = useNavigate();
  const { recordingId } = useParams();
  const [searchParams, setSearchParams] = useSearchParams();
  const [recordings, setRecordings] = useState<Recording[]>([]);
  const [selectedRecording, setSelectedRecording] = useState<Recording | null>(null);
  const [loading, setLoading] = useState(true);
  const [detailLoading, setDetailLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [detailError, setDetailError] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<string | null>(null);
  const isWide = useMediaQuery('(min-width: 1180px)');

  const query = searchParams.get('query') ?? '';
  const projectId = searchParams.get('projectId') ?? '';
  const status = searchParams.get('status') ?? '';
  const userId = searchParams.get('userId') ?? '';

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);

    const params = new URLSearchParams();
    if (query) params.set('query', query);
    if (projectId) params.set('projectId', projectId);
    if (status) params.set('status', status);
    if (userId) params.set('userId', userId);

    void apiRequest<{ data: Recording[] }>(`/admin/recordings?${params.toString()}`, token)
      .then((payload) => {
        if (cancelled) return;
        setRecordings(payload.data);
      })
      .catch((requestError: ApiError) => {
        if (cancelled) return;
        setError(requestError.message);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [projectId, query, status, token, userId]);

  useEffect(() => {
    if (!recordingId) {
      setSelectedRecording(null);
      setDetailError(null);
      return;
    }

    let cancelled = false;
    setDetailLoading(true);
    setDetailError(null);

    void apiRequest<{ data: Recording }>(`/admin/recordings/${recordingId}`, token)
      .then((payload) => {
        if (cancelled) return;
        setSelectedRecording(payload.data);
      })
      .catch((requestError: ApiError) => {
        if (cancelled) return;
        setSelectedRecording(null);
        setDetailError(requestError.message);
      })
      .finally(() => {
        if (!cancelled) setDetailLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [recordingId, token]);

  function updateFilters(next: Record<string, string>) {
    const params = new URLSearchParams(searchParams);
    for (const [key, value] of Object.entries(next)) {
      value ? params.set(key, value) : params.delete(key);
    }
    setSearchParams(params, { replace: true });
  }

  async function handleReprocess() {
    if (!selectedRecording) return;
    setFeedback(null);
    try {
      const payload = await apiRequest<{ data: Recording }>(
        `/admin/recordings/${selectedRecording.id}/reprocess`,
        token,
        {
          method: 'POST',
        },
      );
      setSelectedRecording(payload.data);
      setFeedback('Reprocessamento disparado.');
    } catch (requestError) {
      setDetailError(requestError instanceof Error ? requestError.message : 'Falha ao reprocessar gravação.');
    }
  }

  const list = (
    <PageCard title="Gravações" subtitle="Filtros reais, detalhe administrativo e reprocessamento explícito.">
      <div className="filters-grid">
        <label className="field grow">
          <span>Buscar</span>
          <input value={query} onChange={(event) => updateFilters({ query: event.target.value })} placeholder="Título, resumo ou transcript" />
        </label>
        <label className="field">
          <span>Projeto</span>
          <input value={projectId} onChange={(event) => updateFilters({ projectId: event.target.value })} placeholder="projectId" />
        </label>
        <label className="field">
          <span>Status</span>
          <select value={status} onChange={(event) => updateFilters({ status: event.target.value })}>
            <option value="">Todos</option>
            <option value="uploaded">Enviado</option>
            <option value="processing_transcript">Transcrevendo</option>
            <option value="processing_summary">Resumindo</option>
            <option value="indexing">Indexando</option>
            <option value="ready">Pronto</option>
            <option value="failed">Falhou</option>
          </select>
        </label>
        <label className="field">
          <span>Autor</span>
          <input value={userId} onChange={(event) => updateFilters({ userId: event.target.value })} placeholder="createdByUserId" />
        </label>
      </div>

      {error ? <InlineFeedback tone="error" message={error} /> : null}
      {loading ? (
        <TableEmpty title="Carregando gravações" description="Buscando itens operacionais." />
      ) : recordings.length === 0 ? (
        <TableEmpty title="Nenhuma gravação encontrada" description="Ajuste os filtros para refinar a consulta." />
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Título</th>
                <th>Projeto</th>
                <th>Status</th>
                <th>Provider</th>
                <th>Criada em</th>
              </tr>
            </thead>
            <tbody>
              {recordings.map((recording) => (
                <tr
                  key={recording.id}
                  className={recording.id === recordingId ? 'selected-row' : undefined}
                  onClick={() => navigate(`/recordings/${recording.id}?${searchParams.toString()}`)}
                >
                  <td>
                    <div className="table-primary">{recording.title}</div>
                    <div className="table-secondary">{recording.id}</div>
                  </td>
                  <td>{recording.projectId}</td>
                  <td>
                    <StatusPill status={recording.status} />
                  </td>
                  <td>{recording.transcriptionProvider ?? '—'}</td>
                  <td>{formatDate(recording.createdAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </PageCard>
  );

  const detail = recordingId ? (
    <RecordingDetailPane
      loading={detailLoading}
      error={detailError}
      recording={selectedRecording}
      feedback={feedback}
      onClose={() => navigate(`/recordings?${searchParams.toString()}`)}
      onReprocess={handleReprocess}
    />
  ) : null;

  if (!isWide) {
    return (
      <div className="page-stack">
        {detail}
        {list}
      </div>
    );
  }

  return (
    <div className="split-layout">
      <div className="split-main">{list}</div>
      <div className="split-side">
        {detail ?? (
          <PageCard title="Detalhe da gravação" subtitle="Selecione uma linha para inspecionar transcript, resumo e erros.">
            <TableEmpty title="Nenhuma gravação selecionada" description="Abra um item da tabela para trabalhar no detalhe." />
          </PageCard>
        )}
      </div>
    </div>
  );
}

function RecordingDetailPane(props: {
  loading: boolean;
  error: string | null;
  feedback: string | null;
  recording: Recording | null;
  onClose: () => void;
  onReprocess: () => Promise<void>;
}) {
  return (
    <PageCard
      title="Detalhe administrativo"
      subtitle="Metadados operacionais, transcript, summary, highlights, action items e erro final."
      actions={
        <div className="row-actions">
          <button className="button ghost" onClick={props.onClose}>
            Fechar
          </button>
          <button className="button primary" onClick={() => void props.onReprocess()} disabled={!props.recording}>
            Reprocessar
          </button>
        </div>
      }
    >
      {props.feedback ? <InlineFeedback tone="success" message={props.feedback} /> : null}
      {props.error ? <InlineFeedback tone="error" message={props.error} /> : null}
      {props.loading ? (
        <TableEmpty title="Carregando detalhe" description="Buscando grafo completo da gravação." />
      ) : !props.recording ? (
        <TableEmpty title="Gravação indisponível" description="Selecione outra linha para continuar." />
      ) : (
        <div className="detail-stack">
          <div className="detail-metadata">
            <DetailItem label="Recording ID" value={props.recording.id} />
            <DetailItem label="Projeto" value={props.recording.projectId} />
            <DetailItem label="Autor" value={props.recording.createdByUserId} />
            <DetailItem label="Status" value={statusLabel(props.recording.status)} />
            <DetailItem label="Provider" value={props.recording.transcriptionProvider ?? '—'} />
            <DetailItem label="Job ID" value={props.recording.transcriptionJobId ?? '—'} />
            <DetailItem label="Criada em" value={formatDate(props.recording.createdAt)} />
            <DetailItem label="Atualizada em" value={formatDate(props.recording.updatedAt)} />
          </div>

          <section className="detail-block">
            <h4>Resumo executivo</h4>
            <p>{props.recording.summary?.overview ?? 'Sem resumo disponível.'}</p>
            {props.recording.summary?.chapters?.length ? (
              <div className="chapter-grid">
                {props.recording.summary.chapters.map((chapter) => (
                  <article key={chapter.heading} className="chapter-card">
                    <strong>{chapter.heading}</strong>
                    <p>{chapter.body}</p>
                  </article>
                ))}
              </div>
            ) : null}
          </section>

          <section className="detail-block">
            <h4>Highlights</h4>
            {props.recording.noteArtifact?.highlights?.length ? (
              <ul className="detail-list">
                {props.recording.noteArtifact.highlights.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            ) : (
              <span className="table-secondary">Sem highlights estruturados.</span>
            )}
          </section>

          <section className="detail-block">
            <h4>Action items</h4>
            {props.recording.noteArtifact?.actionItems?.length ? (
              <ul className="detail-list">
                {props.recording.noteArtifact.actionItems.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            ) : (
              <span className="table-secondary">Sem action items estruturados.</span>
            )}
          </section>

          <section className="detail-block">
            <h4>Transcript</h4>
            {props.recording.transcriptSegments.length ? (
              <div className="transcript-stack">
                {props.recording.transcriptSegments.map((segment) => (
                  <article key={segment.id} className="transcript-card">
                    <div className="transcript-meta">
                      <strong>{segment.speakerLabel}</strong>
                      <span>{formatTimestamp(segment.startMs)}</span>
                    </div>
                    <p>{segment.text}</p>
                  </article>
                ))}
              </div>
            ) : (
              <span className="table-secondary">Transcript indisponível.</span>
            )}
          </section>

          {props.recording.lastError ? (
            <section className="detail-block error-block">
              <h4>lastError</h4>
              <p>{props.recording.lastError}</p>
            </section>
          ) : null}
        </div>
      )}
    </PageCard>
  );
}

function DetailItem(props: { label: string; value: string }) {
  return (
    <div className="detail-item">
      <span>{props.label}</span>
      <strong>{props.value}</strong>
    </div>
  );
}

function JobsPage() {
  const token = useAccessToken();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const [jobs, setJobs] = useState<JobRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const query = searchParams.get('query') ?? '';
  const projectId = searchParams.get('projectId') ?? '';
  const status = searchParams.get('status') ?? '';

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);

    const params = new URLSearchParams();
    if (query) params.set('query', query);
    if (projectId) params.set('projectId', projectId);
    if (status) params.set('status', status);

    void apiRequest<{ data: JobRow[] }>(`/admin/jobs?${params.toString()}`, token)
      .then((payload) => {
        if (cancelled) return;
        setJobs(payload.data);
      })
      .catch((requestError: ApiError) => {
        if (cancelled) return;
        setError(requestError.message);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [projectId, query, status, token]);

  function updateFilters(next: Record<string, string>) {
    const params = new URLSearchParams(searchParams);
    for (const [key, value] of Object.entries(next)) {
      value ? params.set(key, value) : params.delete(key);
    }
    setSearchParams(params, { replace: true });
  }

  return (
    <div className="page-stack">
      <PageCard title="Jobs operacionais" subtitle="Monitoramento de provider, job id, timestamps e erros.">
        <div className="filters-grid">
          <label className="field grow">
            <span>Buscar</span>
            <input value={query} onChange={(event) => updateFilters({ query: event.target.value })} placeholder="Título ou conteúdo" />
          </label>
          <label className="field">
            <span>Projeto</span>
            <input value={projectId} onChange={(event) => updateFilters({ projectId: event.target.value })} placeholder="projectId" />
          </label>
          <label className="field">
            <span>Status</span>
            <select value={status} onChange={(event) => updateFilters({ status: event.target.value })}>
              <option value="">Todos</option>
              <option value="processing_transcript">Transcrevendo</option>
              <option value="processing_summary">Resumindo</option>
              <option value="indexing">Indexando</option>
              <option value="ready">Pronto</option>
              <option value="failed">Falhou</option>
            </select>
          </label>
        </div>

        {error ? <InlineFeedback tone="error" message={error} /> : null}

        {loading ? (
          <TableEmpty title="Carregando jobs" description="Buscando a fila operacional." />
        ) : jobs.length === 0 ? (
          <TableEmpty title="Nenhum job encontrado" description="Ajuste os filtros para localizar o processamento desejado." />
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Recording</th>
                  <th>Projeto</th>
                  <th>Status</th>
                  <th>Provider</th>
                  <th>Job ID</th>
                  <th>Última atualização</th>
                </tr>
              </thead>
              <tbody>
                {jobs.map((job) => (
                  <tr key={job.recordingId} onClick={() => navigate(`/recordings/${job.recordingId}?${searchParams.toString()}`)}>
                    <td>
                      <div className="table-primary">{job.title}</div>
                      <div className="table-secondary">{job.recordingId}</div>
                    </td>
                    <td>{job.projectId}</td>
                    <td>
                      <StatusPill status={job.status} />
                    </td>
                    <td>{job.transcriptionProvider ?? '—'}</td>
                    <td>{job.transcriptionJobId ?? '—'}</td>
                    <td>{formatDate(job.transcriptionCompletedAt ?? job.transcriptionStartedAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </PageCard>
    </div>
  );
}

function ProvidersPage() {
  const token = useAccessToken();
  const [providers, setProviders] = useState<ProviderData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    void apiRequest<{ data: ProviderData }>('/admin/providers', token)
      .then((payload) => {
        if (cancelled) return;
        setProviders(payload.data);
      })
      .catch((requestError: ApiError) => {
        if (cancelled) return;
        setError(requestError.message);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [token]);

  return (
    <div className="page-stack">
      <PageCard title="Providers e infraestrutura" subtitle="Estado exposto do backend para IA, transcrição e persistência.">
        {error ? <InlineFeedback tone="error" message={error} /> : null}
        {loading ? (
          <TableEmpty title="Carregando providers" description="Buscando configuração exposta do backend." />
        ) : !providers ? (
          <TableEmpty title="Sem dados" description="O backend não retornou configuração de providers." />
        ) : (
          <div className="provider-grid">
            <DetailItem label="AI Provider" value={providers.aiProvider} />
            <DetailItem label="Speech Provider" value={providers.transcriptionProvider} />
            <DetailItem label="Speech Model" value={providers.assemblyAiSpeechModel} />
            <DetailItem label="Persistence" value={providers.supabasePersistenceMode} />
            <DetailItem label="Storage Bucket" value={providers.supabaseStorageBucket} />
          </div>
        )}
      </PageCard>
    </div>
  );
}

function DialogFrame(props: {
  title: string;
  subtitle?: string;
  onClose: () => void;
  children: ReactNode;
}) {
  return (
    <div className="dialog-backdrop" role="presentation" onClick={props.onClose}>
      <div className="dialog-card" role="dialog" aria-modal="true" onClick={(event) => event.stopPropagation()}>
        <div className="section-header">
          <div>
            <h3>{props.title}</h3>
            {props.subtitle ? <p>{props.subtitle}</p> : null}
          </div>
          <button className="button ghost small" onClick={props.onClose}>
            Fechar
          </button>
        </div>
        {props.children}
      </div>
    </div>
  );
}

function useMediaQuery(query: string) {
  const [matches, setMatches] = useState(() => window.matchMedia(query).matches);

  useEffect(() => {
    const media = window.matchMedia(query);
    const listener = (event: MediaQueryListEvent) => setMatches(event.matches);
    media.addEventListener('change', listener);
    setMatches(media.matches);
    return () => media.removeEventListener('change', listener);
  }, [query]);

  return matches;
}
