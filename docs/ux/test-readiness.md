# UX Test Readiness

## What To Verify

- The first load shows a clear library state and a visible primary action.
- Empty states explain the next step.
- Processing states are legible and not hidden behind spinners only.
- Upload, record, detail, chat, and export actions remain distinguishable.
- Mobile and web layouts retain hierarchy at narrow widths.

## Failure States

- Backend unavailable falls back to demo content.
- Recording permission denied surfaces a clear message.
- Processing errors keep the note accessible for retry.
- Chat should never look empty without context about the note.

## Visual Acceptance

- No default purple SaaS look.
- No generic card-grid homepage.
- No ambiguous primary action.
- No text-on-pattern contrast failures.

