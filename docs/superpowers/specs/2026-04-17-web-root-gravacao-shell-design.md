# Web Root GravAção Shell Design

## Goal

Rebuild the Laravel web frontend at `GET /` so it mirrors the Flutter app's layout, buttons, and main workflows while remaining compatible with the current hosting constraint: all web interaction must keep working from the root path.

## Constraints

- Keep the frontend on Laravel/PHP. Do not revert to Flutter for the web experience.
- Preserve the current deployed language and tone of the web app while adopting the Flutter information architecture and controls.
- Avoid dependence on extra public web routes such as `/library`, `/settings`, `/recordings/...`, or `/api/...`.
- Support admin-only navigation and content in the same shell.

## Recommended Architecture

Use a single root shell with one controller pair:

- `GET /` renders the entire authenticated experience, switching panels by query string such as `/?tab=home`, `/?tab=library`, `/?tab=system`, and `/?tab=admin`.
- `POST /` handles all authenticated actions through `intent`, including login/logout, active project selection, audio upload, microphone upload, project creation, recording reassignment, reprocess, and chat send.

This keeps the deployment safe for the current Nginx/host behavior while still reproducing the Flutter experience.

## UI Structure

### Guest

- Keep root login on `/`.
- Upgrade the visual shell so the guest view feels consistent with the authenticated app branding.

### Authenticated Shell

- Desktop sidebar with brand block, active project card, navigation items, and bottom endorsement.
- Top header with wordmark, active project selector, refresh action, and context-sensitive actions.
- Main content area switches by `tab` query parameter.

### Tabs

- `home`: hero deck, active project context, microphone capture button, upload button, summary metrics.
- `library`: search, project/status filters, grouped recordings, detail panel, chat form, transcript/summary rendering.
- `system`: session/environment summary, project creation and management actions, logout.
- `admin`: admin overview cards and recent users/profiles, visible only for admins.

## Functional Scope

### Recording Actions

- Upload audio from file.
- Record audio from browser microphone with `MediaRecorder` and submit it as a normal multipart form to `POST /`.
- Store uploaded audio on the existing `recordings` disk.
- Create the recording via `RecordingService` and start processing when a file exists.
- Allow reprocess and project reassignment from the library/detail surface.

### Library and Detail

- Filter by project, status, and search term from query parameters.
- Show grouped views equivalent to Flutter: processing, ready, failed.
- Show detail content inline in the root shell, selected by query parameter.
- Support chat messages on a selected recording using `ChatService`.

### Project Actions

- Persist the “project for new recordings” selection in session.
- Allow project creation from the system tab.

### Admin

- Reuse existing admin overview data and render it in the same visual language as the Flutter shell.

## Data Flow

- `DashboardController@index` prepares all view state for the current tab and optional selected recording.
- `DashboardController@submit` dispatches by `intent`.
- Auth intents continue to use the existing authentication logic.
- Authenticated intents operate only on the current user's accessible records.

## Error Handling

- Validation errors return to `/` with the current tab/query state preserved.
- Flash notices communicate upload, processing, chat, and project outcomes.
- Unauthorized admin access falls back to the default home tab.

## Testing Strategy

- Feature tests cover guest root, authenticated shell, admin navigation, active project selection, and root upload flow.
- Existing web access tests are updated to assert the Flutter-like shell instead of the old simple dashboard.

