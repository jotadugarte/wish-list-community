# ADR-0001: Notifications foundation inside Sprint 5

**Status:** Accepted  
**Date:** 2026-11-26

## Context and problem statement

Sprint 5 reservation events (grace started, auto-released, reserved item critically edited or deleted) need user-visible alerts. Device tokens already exist, but there was no in-app store, preference table, or single dispatcher. Leaving notifications orphaned until Sprint 9 would break REQ-RES-003 / REQ-RES-006 product behavior (prior lock D5a).

## Decision drivers

- Reservers must learn about grace, auto-release, and critical item changes in Sprint 5.
- Avoid inventing a second notification path later.
- Push delivery (FCM send) is not required until Sprint 9 / Notifications MVP.

## Considered options

1. **Bundle minimal foundation inside Sprint 5** — `notifications`, `notification_preferences`, single `NotificationDispatcher` (in-app + email enqueue; push no-op).
2. **Separate notifications chore PR before Sprint 5** — cleaner PR boundary; delays reservations.
3. **AuditEvent only in Sprint 5** — lowest code; violates user-facing REQ-RES-003/006 and D5a.

## Decision outcome

**Chosen option:** Option 1 (O1A / O8A)

Preferences default all-on; missing preference row means defaults-on. Only Sprint 5 reservation events are wired now. Push preference is stored; send is intentionally a no-op until Sprint 9.

### Positive consequences

- REQ-RES-003 / REQ-RES-006 and D5a satisfied with Sprint 5.
- One dispatcher entrypoint for later notification epics.

### Negative consequences

- Larger Sprint 5 PR surface.
- Temporary gap: no live FCM delivery despite a push toggle.

## More information

Session locks L-O1A, L-O8A, L-D5a. Spec §4.5 / §4.7. Draft PR #12.
