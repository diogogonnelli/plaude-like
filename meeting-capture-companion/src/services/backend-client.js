export async function listProjects(backendBaseUrl, accessToken) {
  const response = await fetch(`${backendBaseUrl}/projects`, {
    headers: {
      authorization: `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to list projects: ${response.status}`);
  }

  const payload = await response.json();
  return Array.isArray(payload.data) ? payload.data : [];
}
