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

export async function listRecordings(backendBaseUrl, accessToken) {
  const response = await fetch(`${backendBaseUrl}/recordings?_ts=${Date.now()}`, {
    headers: {
      authorization: `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to list recordings: ${response.status}`);
  }

  const payload = await response.json();
  return Array.isArray(payload.data) ? payload.data : [];
}

export async function getRecording(backendBaseUrl, accessToken, recordingId) {
  const response = await fetch(`${backendBaseUrl}/recordings/${recordingId}?_ts=${Date.now()}`, {
    headers: {
      authorization: `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to get recording: ${response.status}`);
  }

  const payload = await response.json();
  return payload.data ?? null;
}

export async function exportRecordingMarkdown(backendBaseUrl, accessToken, recordingId) {
  const response = await fetch(`${backendBaseUrl}/recordings/${recordingId}/export`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${accessToken}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({ format: 'md' }),
  });

  if (!response.ok) {
    throw new Error(`Failed to export recording: ${response.status}`);
  }

  const payload = await response.json();
  return payload.data ?? null;
}

export async function updateRecording(backendBaseUrl, accessToken, recordingId, input) {
  const response = await fetch(`${backendBaseUrl}/recordings/${recordingId}`, {
    method: 'PATCH',
    headers: {
      authorization: `Bearer ${accessToken}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify(input),
  });

  if (!response.ok) {
    throw new Error(`Failed to update recording: ${response.status}`);
  }

  const payload = await response.json();
  return payload.data ?? null;
}
