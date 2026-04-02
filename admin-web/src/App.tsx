import { useEffect, useMemo, useState } from 'react';

type NavKey = 'dashboard' | 'projects' | 'members' | 'recordings' | 'jobs' | 'providers';

const navItems: Array<{ key: NavKey; label: string }> = [
  { key: 'dashboard', label: 'Dashboard' },
  { key: 'projects', label: 'Projetos' },
  { key: 'members', label: 'Membros' },
  { key: 'recordings', label: 'Gravacoes' },
  { key: 'jobs', label: 'Jobs' },
  { key: 'providers', label: 'Provedores' },
];

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8787';

type DashboardData = {
  totalRecordings: number;
  processing: number;
  failed: number;
  ready: number;
};

type Project = {
  id: string;
  name: string;
  slug: string;
  status: string;
};

type Recording = {
  id: string;
  projectId: string;
  title: string;
  status: string;
  transcriptionProvider?: string | null;
};

type ProviderData = {
  aiProvider: string;
  transcriptionProvider: string;
  assemblyAiSpeechModel: string;
  supabasePersistenceMode: string;
  supabaseStorageBucket: string;
};

export function App() {
  const [active, setActive] = useState<NavKey>('dashboard');
  const [dashboard, setDashboard] = useState<DashboardData | null>(null);
  const [projects, setProjects] = useState<Project[]>([]);
  const [recordings, setRecordings] = useState<Recording[]>([]);
  const [providers, setProviders] = useState<ProviderData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const title = useMemo(() => navItems.find((item) => item.key === active)?.label ?? 'Dashboard', [active]);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setLoading(true);
      setError(null);

      try {
        const [dashboardResponse, projectsResponse, recordingsResponse] = await Promise.all([
          fetch(`${API_BASE_URL}/admin/dashboard`).then((response) => response.json()),
          fetch(`${API_BASE_URL}/admin/projects`).then((response) => response.json()),
          fetch(`${API_BASE_URL}/admin/recordings`).then((response) => response.json()),
        ]);
        const providersResponse = await fetch(`${API_BASE_URL}/admin/providers`).then((response) => response.json());

        if (cancelled) return;
        setDashboard(dashboardResponse.data ?? null);
        setProjects(projectsResponse.data ?? []);
        setRecordings(recordingsResponse.data ?? []);
        setProviders(providersResponse.data ?? null);
      } catch (loadError) {
        if (cancelled) return;
        setError(loadError instanceof Error ? loadError.message : 'Falha ao carregar o admin.');
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    void load();

    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div className="admin-shell">
      <aside className="sidebar">
        <div className="brand">
          <h1>Plaude Admin</h1>
          <p>Operacao, projetos e pipeline</p>
        </div>
        <nav className="nav">
          {navItems.map((item) => (
            <button
              key={item.key}
              className={item.key === active ? 'nav-item active' : 'nav-item'}
              onClick={() => setActive(item.key)}
            >
              {item.label}
            </button>
          ))}
        </nav>
      </aside>

      <main className="content">
        <header className="topbar">
          <div>
            <h2>{title}</h2>
            <p>Backoffice desktop-first para operacao de projetos, membros e gravacoes.</p>
          </div>
          <button className="primary" onClick={() => setActive('projects')}>
            Nova acao
          </button>
        </header>

        <section className="cards">
          <article className="stat-card">
            <span>Total de projetos</span>
            <strong>{projects.length}</strong>
          </article>
          <article className="stat-card">
            <span>Gravacoes em andamento</span>
            <strong>{dashboard?.processing ?? 0}</strong>
          </article>
          <article className="stat-card">
            <span>Jobs ativos</span>
            <strong>{dashboard?.totalRecordings ?? 0}</strong>
          </article>
        </section>

        {loading && <div className="panel">Carregando dados do backoffice...</div>}
        {error && <div className="panel error">{error}</div>}

        <section className="grid single-column">
          {active === 'dashboard' && (
            <DashboardPanels
              projects={projects}
              recordings={recordings}
              onOpenProjects={() => setActive('projects')}
              onOpenRecordings={() => setActive('recordings')}
            />
          )}
          {active === 'projects' && <ProjectsPanel projects={projects} onOpenMembers={() => setActive('members')} />}
          {active === 'members' && <MembersPanel projects={projects} />}
          {active === 'recordings' && <RecordingsPanel recordings={recordings} />}
          {active === 'jobs' && <JobsPanel recordings={recordings} />}
          {active === 'providers' && <ProvidersPanel providers={providers} />}
        </section>
      </main>
    </div>
  );
}

function DashboardPanels(props: {
  projects: Project[];
  recordings: Recording[];
  onOpenProjects: () => void;
  onOpenRecordings: () => void;
}) {
  const { projects, recordings, onOpenProjects, onOpenRecordings } = props;

  return (
    <>
      <article className="panel">
        <div className="panel-header">
          <h3>Projetos</h3>
          <button onClick={onOpenProjects}>Ver todos</button>
        </div>
        <table>
          <thead>
            <tr>
              <th>Nome</th>
              <th>Status</th>
              <th>Slug</th>
            </tr>
          </thead>
          <tbody>
            {projects.map((project) => (
              <tr key={project.id}>
                <td>{project.name}</td>
                <td>{project.status}</td>
                <td>{project.slug}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </article>

      <article className="panel">
        <div className="panel-header">
          <h3>Gravacoes recentes</h3>
          <button onClick={onOpenRecordings}>Filtrar</button>
        </div>
        <table>
          <thead>
            <tr>
              <th>Titulo</th>
              <th>Projeto</th>
              <th>Status</th>
              <th>Provider</th>
            </tr>
          </thead>
          <tbody>
            {recordings.map((recording) => (
              <tr key={recording.id}>
                <td>{recording.title}</td>
                <td>{recording.projectId}</td>
                <td>{recording.status}</td>
                <td>{recording.transcriptionProvider ?? '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </article>
    </>
  );
}

function ProjectsPanel(props: { projects: Project[]; onOpenMembers: () => void }) {
  return (
    <article className="panel">
      <div className="panel-header">
        <h3>Gestao de projetos</h3>
        <button onClick={props.onOpenMembers}>Ver membros</button>
      </div>
      <table>
        <thead>
          <tr>
            <th>Nome</th>
            <th>Slug</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {props.projects.map((project) => (
            <tr key={project.id}>
              <td>{project.name}</td>
              <td>{project.slug}</td>
              <td>{project.status}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </article>
  );
}

function MembersPanel(props: { projects: Project[] }) {
  return (
    <article className="panel">
      <div className="panel-header">
        <h3>Membros por projeto</h3>
      </div>
      <div className="stack">
        {props.projects.map((project) => (
          <div key={project.id} className="chip-row">
            <strong>{project.name}</strong>
            <span>Use /admin/projects/{project.id}/members para listar e gerenciar membros.</span>
          </div>
        ))}
      </div>
    </article>
  );
}

function RecordingsPanel(props: { recordings: Recording[] }) {
  return (
    <article className="panel">
      <div className="panel-header">
        <h3>Gravacoes</h3>
      </div>
      <table>
        <thead>
          <tr>
            <th>Titulo</th>
            <th>Projeto</th>
            <th>Status</th>
            <th>Provider</th>
          </tr>
        </thead>
        <tbody>
          {props.recordings.map((recording) => (
            <tr key={recording.id}>
              <td>{recording.title}</td>
              <td>{recording.projectId}</td>
              <td>{recording.status}</td>
              <td>{recording.transcriptionProvider ?? '-'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </article>
  );
}

function JobsPanel(props: { recordings: Recording[] }) {
  return (
    <article className="panel">
      <div className="panel-header">
        <h3>Jobs de transcricao</h3>
      </div>
      <table>
        <thead>
          <tr>
            <th>Recording</th>
            <th>Status</th>
            <th>Provider</th>
          </tr>
        </thead>
        <tbody>
          {props.recordings.map((recording) => (
            <tr key={recording.id}>
              <td>{recording.id}</td>
              <td>{recording.status}</td>
              <td>{recording.transcriptionProvider ?? '-'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </article>
  );
}

function ProvidersPanel(props: { providers: ProviderData | null }) {
  return (
    <article className="panel">
      <div className="panel-header">
        <h3>Provedores</h3>
      </div>
      {!props.providers ? (
        <p>Sem dados de provider disponiveis.</p>
      ) : (
        <div className="stack">
          <div className="chip-row"><strong>AI:</strong> <span>{props.providers.aiProvider}</span></div>
          <div className="chip-row"><strong>Transcricao:</strong> <span>{props.providers.transcriptionProvider}</span></div>
          <div className="chip-row"><strong>Speech model:</strong> <span>{props.providers.assemblyAiSpeechModel}</span></div>
          <div className="chip-row"><strong>Persistencia:</strong> <span>{props.providers.supabasePersistenceMode}</span></div>
          <div className="chip-row"><strong>Bucket:</strong> <span>{props.providers.supabaseStorageBucket}</span></div>
        </div>
      )}
    </article>
  );
}
