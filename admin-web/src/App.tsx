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

export function App() {
  const [active, setActive] = useState<NavKey>('dashboard');
  const [dashboard, setDashboard] = useState<DashboardData | null>(null);
  const [projects, setProjects] = useState<Project[]>([]);
  const [recordings, setRecordings] = useState<Recording[]>([]);
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

        if (cancelled) return;
        setDashboard(dashboardResponse.data ?? null);
        setProjects(projectsResponse.data ?? []);
        setRecordings(recordingsResponse.data ?? []);
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
          <button className="primary">Nova acao</button>
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

        <section className="grid">
          <article className="panel">
            <div className="panel-header">
              <h3>Projetos</h3>
              <button>Ver todos</button>
            </div>
            <table>
              <thead>
                <tr>
                  <th>Nome</th>
                  <th>Status</th>
                  <th>Membros</th>
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
              <button>Filtrar</button>
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
        </section>
      </main>
    </div>
  );
}
