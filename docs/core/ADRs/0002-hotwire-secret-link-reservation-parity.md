# ADR-0002: Hotwire Secret Link reservation parity

**Status:** Accepted  
**Date:** 2026-11-26

## Context and problem statement

Prior lock D6a says the primary client is `/api/v1` + Flutter, with web only where SPEC requires. Secret Links already have a Hotwire surface (`/s/:share_token`). Sprint 5 must decide whether logged-in sharees can reserve only via Flutter/API, or also on the existing web link page.

## Decision drivers

- Guests already land on Hotwire for OG/invitation; forcing a mobile-only reserve path breaks that journey.
- SPEC requires logged-in users with Secret Link access to view and reserve (`REQ-WISH-002`).
- Keep D6a intact for other features while acknowledging Secret Link as an obligatory web reservation surface for this sprint.

## Considered options

1. **API + Flutter only** — web remains invitation/read-only for items; reserve only on mobile.
2. **Hotwire parity (O4B)** — logged-in sharees get the same reserve/extend/cancel actions as Flutter on `/s/:share_token`.
3. **Redirect Secret Link users into a separate SPA** — rejected by architecture (Hotwire-only web).

## Decision outcome

**Chosen option:** Option 2 (O4B)

Logged-in sharees on `/s/:share_token` can reserve, extend, and cancel (and see viewer-relative availability). Guests remain invitation/view plus login/`return_to` before reserving. Owners browsing their own link must not see reservation spoilers.

### Positive consequences

- One coherent Secret Link journey from invitation → login → reserve.
- Narrows D6a only for this obligatory web surface.

### Negative consequences

- Extra Hotwire controller/view coverage alongside API/Flutter.
- Must keep web and API behavior in lockstep for reservation actions.

## More information

Session lock L-O4B. Spec §4.5. `SecretLinkReservationsController`. Draft PR #12.
