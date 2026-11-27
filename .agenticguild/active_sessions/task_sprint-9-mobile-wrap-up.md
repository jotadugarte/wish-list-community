# Explore Session — MVP Sprint 9 Mobile Wrap-Up & Native Share-to-App

**Skill:** explore-task  
**Classification:** Feature  
**Repo:** jotadugarte/wish-list-community  
**Base:** `origin/main` @ `7f3dc73` (Merge PR #15 — Sprint 8 Admin/Moderation)  
**Started:** 2026-11-27  
**Status:** DISCOVERY COMPLETE (Phase 2 · Step 2.1) — plan CONFIRMED; handoff to start-task on NEW worker. No product code in this explore.
**Durable explore doc:** `/cursor/stores/bc-32a5179f-cc50-4940-94d7-70abc32641c4/docs/sprint-9-mobile-wrap-up-explore.md`

## Opening triad

### What do we know?
- Sprint 8 Admin/Moderation (web-only) is merged on `main` (`7f3dc73`). Admin stays web-only — not a Sprint 9 Flutter target.
- ROADMAP Pending next item is **MVP Sprint 9 — Mobile Wrap-Up & Native "Share to App" Sheet** covering: Flutter MVP parity (`REQ-MOB-001`), native Share-to-App + smart parse (`REQ-MOB-001/002`, `REQ-ITEM-006`), deep links (`REQ-MOB-001`), client image compression 2MB/1600px/max 3 (`REQ-MOB-001`; Sprint 4 deferred O6A), FCM push + `device_token` unbind on logout (`REQ-NOTIF-001/002`), App Store/Play readiness with in-app account deletion & UGC EULA (`REQ-LIFE-002`, `REQ-AUTH-002`).
- Separate Pending bucket: **Notifications (MVP)** — per-event prefs UI, localized dispatcher completion, and event coverage list.
- Backend already has: `DeviceToken` bound to `api_token`, logout/revocation destroy tokens, `NotificationDispatcher` (in-app + email + **push no-op**), API for notifications + preferences, account soft-delete API, item multipart attach + server-side libvips pipeline, link-preview confirm-before-persist.
- Flutter already has: auth (incl. signup + soft-delete on ProfileSettings), social, wishlists, items (JSON + paste-URL preview; **no gallery multipart / no client compress**), reservations, gifts. `pubspec` has almost no native packages yet (no FCM, share intent, deep links, image_picker).
- Architecture: Flutter is a thin `/api/v1` client; server authority; product parity preference = member features on web + Flutter (Admin web-only already decided).
- Activities / activity deep links are **v1 backlog** — activity link in Sprint 9 deep-link bullet is aspirational vs current MVP domain.
- **O1A LOCKED:** Absorb Notifications (MVP) into Sprint 9 — real FCM, Flutter token register/unbind, prefs + inbox on Flutter and matching Hotwire, complete Pending event list.
- **O2B LOCKED:** True dual-client MVP in S9 — also build Hotwire wishlist/item/reserve/gift parity (Admin remains web-only).
- **O3A LOCKED:** Deep links = friend profile + secret link only; omit activity until v1.
- **O4B LOCKED:** Share-to-App = logged-in parse → Add Item + preview; remember last-used wishlist and skip picker when safe.
- **O5A LOCKED:** Gallery+camera Flutter + Hotwire file picker; both client-compress before upload; server libvips remains mandatory.
- **O6A LOCKED:** Flutter FCM only (ask after login; bind/refresh; unbind logout); Hotwire inbox+email only — no browser Web Push.
- **O7A LOCKED:** Catálogo completo de avisos del roadmap + regalos ya existentes (amistad recibida/aceptada incluida); Ajustes con prender/apagar por tipo.
- **O8A LOCKED (+clarificación):** Listo para tiendas = publicar páginas públicas Hotwire de Términos y Privacidad (`/terms`, `/privacy` o equiv.), enlaces visibles en app+web, borrado de cuenta claro, checklist de submit. Copy legal placeholder OK; owner aprueba texto real después (riesgo/nota).
- **O9B LOCKED:** Host público **provisional/staging** para términos, privacidad y “abrir en la app”; cambiar al dominio de producción **antes** de mandar a las tiendas. Aún no hay dominio de producción.
- **O10B LOCKED:** Cablear envío de avisos del teléfono en código + pruebas; el owner pega las llaves de Google después. Sin llaves: campanita/correo sí; aviso del sistema en teléfono real no.
- **O11A LOCKED:** “Última lista” del Share-to-App se recuerda **solo en ese teléfono** (no en la cuenta / otros aparatos).
- **O12A LOCKED:** La web con sesión usa las **mismas secciones** que el teléfono (Mis listas, compartidas, amigos, reservaciones, avisos, ajustes).
- **O13A LOCKED:** Términos y Privacidad bilingües (es + en) desde el día uno (placeholders OK hasta texto legal real).

### What don't we know?
- Nombre concreto del host staging (configurable — riesgo O9B).
- Texto legal definitivo (placeholder hasta que el owner apruebe — riesgo O8A).
- Llaves Google para avisos del teléfono en dispositivo real (O10B — después).
- Share-to-App packaging: share-extension / intent vs in-app receive-sharing; Amazon/ML parsing rules; guest vs logged-in share flow.
- Deep-link host/association files; which paths ship now vs stub (esp. activity).
- Firebase project / secrets ownership for FCM; APNs setup path.
- Publication checklist: privacy policy URLs, EULA display surface, data-safety forms — what is already true vs docs/store metadata only.

### What do we need to define?
- Launch **`start-task`** (hands-off) on a **new worker** — explore done.
- Domain Model for new mobile-facing entities / VOs (SharePayload, DeepLinkTarget, DeviceRegistration, CompressedImageBlob, etc.).
- Implementation plan (TDD) only after all material O* locked + Final check.

## Classification
**Feature**

## Domain Model

| Entity / VO | Responsibility | Invariants |
| :--- | :--- | :--- |
| **SharePayload** (VO) | Parsed OS share blob → URL + optional title hint | At most one primary `http(s)` URL; empty URL → cannot open Add Item from share |
| **LastWishlistMemory** | Device-local last owned wishlist id for Share-to-App skip-picker | Only valid if wishlist still owned by current user; else clear and show picker (O11A) |
| **DeepLinkTarget** (VO) | Mapped public URL → friend profile \| secret link \| unsupported | Activity paths unsupported in S9 (O3A); invalid → safe error / web fallback |
| **CompressedImageBlob** (VO) | Client image before multipart | ≤3 per item; best-effort ≤2MB and ≤1600 longest side; server libvips still mandatory (O5A) |
| **DeviceRegistration** | Flutter push token bound to API session | Bound to `api_token`; destroyed on logout/revoke (O6A, REQ-NOTIF-002); keys may be absent (O10B) |
| **NotificationEventCatalog** | Prefs + dispatcher event keys | Includes friend received/accepted, reservation S5 set, gift delivered/received/thank-you/voided (O7A) |
| **LegalDocumentPage** | Public Hotwire `/terms`, `/privacy` | Public; bilingual es+en; placeholder copy until owner approves (O8A, O13A) |
| **MemberWebShell** | Hotwire nav sections mirroring phone | Logged-in only; Admin stays separate (O12A, O2B) |

No new core gift/reservation domain entities — reuse existing server models.

## Decision log

### O1 — Notifications (MVP) bucket vs Sprint 9 — **LOCKED A** (owner 2026-11-27)
Absorb Notifications (MVP) into Sprint 9: real FCM send, Flutter register/unbind, prefs + inbox on Flutter and Hotwire, complete Pending event list.

### O2 — Member parity boundary (Hotwire vs Flutter for S9 surfaces) — **LOCKED B** (owner 2026-11-27)
True dual-client MVP in Sprint 9: Hotwire wishlist/item/reserve/gift parity alongside Flutter (Admin remains web-only). Notifications inbox/prefs on both per O1A.

### O3 — Deep-link path set for Sprint 9 — **LOCKED A** (owner 2026-11-27)
Friend profile + secret link Universal/App Links only; omit activity deep links until v1 Activities.

### O4 — Native Share-to-App entry UX — **LOCKED B** (owner 2026-11-27)
Share-to-App: logged-in parse → wishlist picker (skip when last-used wishlist is still a safe owned target) → Add Item with link-preview confirm. Logged-out → login then resume payload. First https URL + leftover text as title hint.

### O5 — Image upload + client compression — **LOCKED A** (owner 2026-11-27)
Gallery + camera on Flutter; file picker on Hotwire; both clients compress toward ≤2MB / ≤1600 before multipart; server libvips WebP/EXIF strip remains mandatory; max 3 images.

### O6 — FCM / push registration UX — **LOCKED A** (owner 2026-11-27)
Flutter FCM only: ask OS permission after login/signup; bind/refresh `fcm_token` on API session; unbind on logout. Hotwire = in-app inbox + email only (no browser Web Push). Prefs Push toggle on web means “signed-in apps.”

### O7 — Notification event catalog for Sprint 9 — **LOCKED A** (owner 2026-11-27)
Catálogo completo del roadmap + claves de regalos ya en código: amistad recibida/aceptada; reservas; regalos (entregado / confirmado / gracias / anulado); Ajustes con toggles por tipo en teléfono y web.

### O8 — Listo para App Store / Play — **LOCKED A** (owner 2026-11-27, con aclaración)
Publicar páginas Hotwire públicas de Términos y Privacidad (`/terms`, `/privacy` o equivalente) + enlaces visibles en app y web + borrado de cuenta claro + checklist de submit a tiendas. Copy legal puede ser placeholder; el owner aprueba el texto real después (quedará como riesgo/nota si no llega a tiempo).

### O9 — Dirección pública del sitio (dominio) — **LOCKED B** (owner 2026-11-27)
Host provisional/staging para URLs públicas (términos, privacidad, abrir en la app). Swap a dominio de producción antes del submit a tiendas. Sin dominio de producción aún; el hostname staging concreto puede quedar en config/checklist si no se nombra ahora.

### O10 — Notificaciones del teléfono (cuenta Google / llaves) — **LOCKED B** (owner 2026-11-27)
Cablear avisos del teléfono en código + pruebas; owner pega llaves Google después. Sin llaves: campanita/correo sí; sistema en dispositivo real no.

### O11 — Dónde se recuerda la última lista al compartir — **LOCKED A** (owner 2026-11-27)
Última lista del Share-to-App solo en ese teléfono (memoria local del aparato).

### O12 — Navegación de la web con sesión — **LOCKED A** (owner 2026-11-27)
Web con sesión: mismas secciones que el teléfono (Mis listas, compartidas, amigos, reservaciones, avisos, ajustes).

### O13 — Idioma de Términos y Privacidad — **LOCKED A** (owner 2026-11-27)
Términos y Privacidad bilingües es+en desde el día uno (placeholders hasta texto legal real).

## Dark corners & pitfalls
- **Alcance enorme (O2B):** reconstruir en web casi toda la app de miembro en el mismo sprint que Share-to-App, enlaces profundos, fotos, avisos y tiendas. Riesgo de plan largo; el plan TDD debe ir por capas (web shell → flujos → móvil nativo → avisos → legales/tiendas), no un solo “big bang”.
- **Actividades / deep link de activity:** ROADMAP lo nombraba; **omitido** (O3A) hasta v1 — no inventar rutas muertas.
- **Admin:** sigue solo web (S8); no portar al teléfono.
- **Host staging sin nombre (O9B):** URLs públicas y “abrir en la app” dependen de un host provisional aún no nombrado — configurable + checklist; **no** mandar a App Store/Play hasta swap a producción.
- **Texto legal placeholder (O8A):** riesgo de rechazo en tienda si se envía revisión con lorem; owner debe aprobar texto real antes del submit.
- **Llaves Google después (O10B):** campanita/correo sí; aviso del sistema en teléfono real no hasta que peguen llaves. CI con dobles.
- **Share-to-App:** solo teléfono; web sigue con pegar enlace. Memoria de última lista solo en ese aparato (O11A) — reinstalar = vuelve a preguntar.
- **Paridad Hotwire vs API:** la web nueva debe hablar con la misma autoridad del servidor (no inventar reglas en el cliente); Secret Link ya existente se integra al shell, no se duplica en lógica rara.
- **Pruebas en la nube:** no hay simulador iOS/Android aquí — Share sheet, Universal/App Links y avisos del sistema = checks manuales del owner + `flutter_test`/RSpec headless.
- **Diseño visual:** preferencia vigente = DesignTokens por defecto hasta HTML de Ñata; no bloquear S9 por diseño final.

### Final check — opens remaining
| Item | Disposition proposed |
| :--- | :--- |
| Hostname staging concreto | **Riesgo / config** (O9B) — no bloquea plan |
| Texto legal definitivo | **Riesgo** (O8A) — placeholder en S9; aprobar antes de submit |
| Llaves Google push | **Diferido a ops** (O10B) — cableado en S9 |
| Actividades / activity links | **Diferido a v1** (O3A) |
| O* product decisions | **Todas locked** O1A–O13A |

**FINAL OK** (owner 2026-11-27) — proposed risk dispositions accepted.




## Lock checklist — **PASS** (2026-11-27)

- [x] Opening triad recorded
- [x] Classification stamped: **Feature**
- [x] Domain Model populated (Feature)
- [x] Final check done + **FINAL OK**
- [x] Dark corners recorded
- [x] Every open question answered, deferred, or implementation risk
- [x] Behaviour matrix: already exists (`docs/core/BEHAVIOUR_MATRIX.md`) — no re-offer
- [x] Implementation plan XML block written (TDD; ends at local green suites; excludes wrapping/release steps)


<implementation_plan>
  <step id="1" status="complete">Write failing RSpec for expanded `NotificationPreference` catalog (O7A): friend.request_received, friend.request_accepted, existing reservation + gift keys (delivered_pending_confirmation, received_confirmed_to_gifter, thank_you, voided_by_owner_delete) appear in defaults/API; channel toggles in_app/email/push. Trace [REQ-NOTIF-001].</step>
  <step id="2" status="complete">Implement catalog + API serialization minimally until step 1 green (no FCM network yet).</step>
  <step id="3" status="complete">Write failing model/service specs: Friendship request! / accept! dispatch NotificationDispatcher for received/accepted to the right user; honor prefs; bilingual titles via I18n. Trace [REQ-NOTIF-001], [REQ-SOC-001].</step>
  <step id="4" status="complete">Implement Friendship notification hooks until step 3 green.</step>
  <step id="5" status="complete">Write failing specs for NotificationDispatcher push path (O1A/O6A/O10B): when push enabled and DeviceTokens exist, enqueue/send via injectable FCM client double; when no tokens/keys, no crash and in-app/email still work; logout still destroys tokens [REQ-NOTIF-002].</step>
  <step id="6" status="complete">Implement real push send wiring behind the double/adapter until step 5 green (no live Google calls in CI).</step>
  <step id="7" status="complete">Write failing request/system specs for public Hotwire `GET /terms` and `GET /privacy` (O8A/O13A): 200 public, es+en content (placeholder OK), linked from signup/profile. Trace [REQ-AUTH-002], [REQ-LIFE-002] publication readiness.</step>
  <step id="8" status="complete">Implement legal pages + visible links (web) until step 7 green.</step>
  <step id="9" status="complete">Write failing system specs for logged-in Hotwire **MemberWebShell** (O12A/O2B): nav sections Mis listas, Compartidas, Amigos, Reservaciones, Avisos, Ajustes; unauthenticated redirected to login.</step>
  <step id="10" status="complete">Implement MemberWebShell layout/nav until step 9 green (empty section shells OK if wired).</step>
  <step id="11" status="complete">Write failing system specs for Hotwire wishlist parity: list/create/edit privacy/secret-link rotate/shares/soft-delete aligned with existing API rules [REQ-WISH-*].</step>
  <step id="12" status="complete">Implement Hotwire wishlist controllers/views until step 11 green (server authority unchanged).</step>
  <step id="13" status="complete">Write failing system specs for Hotwire item CRUD + paste-URL preview confirm + multipart images with client-side compress helper (O5A) respecting ≤3 / ≤2MB / ≤1600; server libvips still runs [REQ-ITEM-002], [REQ-ITEM-006], [REQ-MOB-001].</step>
  <step id="14" status="complete">Implement Hotwire item forms + compress helper until step 13 green.</step>
  <step id="15" status="complete">Write failing system specs for Hotwire reserve / gift / my-reservations / thank-you flows matching existing API behaviour [REQ-RES-*], [REQ-GIFT-*].</step>
  <step id="16" status="complete">Implement Hotwire reservation/gift surfaces until step 15 green.</step>
  <step id="17" status="complete">Write failing system/request specs for Hotwire notification inbox + prefs toggles + profile soft-delete/account links (O1A/O2B/O8A) [REQ-NOTIF-001], [REQ-LIFE-002].</step>
  <step id="18" status="complete">Implement Hotwire inbox/prefs/account deletion UX until step 17 green.</step>
  <step id="19" status="pending">Write failing Flutter tests for SharePayload VO + device-local LastWishlistMemory (O4B/O11A) + ItemForm gallery/camera + client compress + multipart upload (O5A). Trace [REQ-MOB-001], [REQ-MOB-002], [REQ-ITEM-002].</step>
  <step id="20" status="pending">Implement Flutter share parsing, last-wishlist memory, image picker/compress/upload until step 19 green.</step>
  <step id="21" status="pending">Write failing Flutter tests for Share-to-App entry: logged-out → login resume; logged-in → skip picker when memory safe else picker → Add Item with link-preview confirm (O4B). Trace [REQ-MOB-001], [REQ-MOB-002], [REQ-ITEM-006].</step>
  <step id="22" status="pending">Implement Flutter share-intent wiring until step 21 green (platform channels/plugins as needed; headless tests with fakes).</step>
  <step id="23" status="pending">Write failing Flutter tests for DeepLinkTarget: friend profile + `/s/:token` secret link open correct screens; activity/unknown safe failure (O3A) [REQ-MOB-001].</step>
  <step id="24" status="pending">Implement Universal/App Links association config (staging host configurable O9B) + Flutter routing until step 23 green.</step>
  <step id="25" status="pending">Write failing Flutter tests for FCM register-after-login, pass fcm_token on session, clear on logout; graceful when keys missing (O6A/O10B) [REQ-NOTIF-002]. Inbox + prefs screens on Flutter; legal links es+en (O13A).</step>
  <step id="26" status="pending">Implement Flutter notifications client + inbox/prefs + legal links until step 25 green.</step>
  <step id="27" status="pending">Update living docs: API_CONTRACT (any new surfaces), ROADMAP mark Sprint 9 + Notifications absorbed when verified, SYSTEM_ARCHITECTURE mobile/Hotwire surfaces, BEHAVIOUR_MATRIX new BM rows as planned, add short store-submit checklist doc under docs/ (O8A). Staging host + Google keys + legal-text-approval called out as ops risks.</step>
  <step id="28" status="pending">Run full backend RSpec + `flutter analyze` / `flutter test` locally; fix until green. End of start-task implementation scope. (Owner-local manual: Share sheet, deep links on device, real push after keys, store forms.)</step>
</implementation_plan>

## Implementation risks
- O10B: sin llaves Google, no hay prueba real de aviso del sistema en dispositivo; CI cubre cableado con dobles.
- O9B: sin dominio de producción; no mandar a App Store/Play hasta swap de host. Hostname staging concreto TBD/configurable.
- Native Share / Universal Links / FCM require platform project files + store credentials; cloud VM may not fully exercise iOS/Android installers — plan must keep headless `flutter_test` as CI proof and list owner-local manual checks.
- Activity deep links named in ROADMAP while Activities are v1 — O3 must lock omit vs stub vs slip.
- "Full MVP parity" is broad; **O2B** explicitly accepts Hotwire member rebuild in S9 — plan must sequence TDD carefully.

## Notes / scratch
- Owner prefs: one O* card at a time; plain who-sees-what; lettered A/B/C; no product code; handoff to start-task only when owner says so.
- `agent_git`: commit (explore writes session/docs only; no app commits expected).
- `verification`: tdd.

## Handoff — **COMPLETE**
- Plan **CONFIRMED** (owner 2026-11-27 · CONFIRM PLAN).
- Phase 2 validation: Feature + TDD test-first steps; architecture OK; no wrapping/release steps; ends at local RSpec + flutter test.
- Spec locked. Coordinator/owner runs **`start-task`** (hands-off) on a **new worker**.
- **This explore agent does not write product code.**
