<task_session>
  <metadata>
    <task_name>Roadmap pre-Sprint 3 review — locked decisions D1a–D7a</task_name>
    <type>Chore</type>
    <req_id>N/A (docs / process)</req_id>
    <roadmap_item>Pre-Sprint 3 hygiene + sequencing (signup P0, Wishlists Sprint 3)</roadmap_item>
  </metadata>

  <implementation_plan>
    <step id="1" status="complete">Explore ROADMAP vs repo; surface over-claims (signup Done, LIFE-001 cascade, notifications orphan)</step>
    <step id="2" status="complete">Lock owner decisions D1a–D7a (2026-11-26)</step>
    <step id="3" status="complete">PR-A: session + ROADMAP wording hygiene (this chore branch)</step>
    <step id="4" status="pending">PR-B: Signup P0 (API + Flutter + docs) before Sprint 3 explore/start</step>
    <step id="5" status="pending">explore-task MVP Sprint 3 Wishlists (Hotwire mínimo Secret Link) — only after PR-A + PR-B; no start-task until owner says</step>
  </implementation_plan>

  <working_notes>
## Base
- Repo: jotadugarte/wish-list-community
- origin/main @ 59fee19 (agentic:guild 1.1.0)
- Project store report: docs/roadmap-pre-sprint3-review.md (coordinator store)

## Veredicto
Cerrar chores P0 (signup + wording LIFE-001/signup + higiene de sesiones), luego explore-task Sprint 3 Wishlists con Hotwire mínimo para Secret Link. No start-task de producto Sprint 3 hasta que el owner lo diga.

## Decisiones Locked (owner) — 2026-11-26

| ID | Decisión | Status |
| :--- | :--- | :--- |
| **D1a** | Signup chore **P0 antes de Sprint 3** | Locked |
| **D2b** | Seguir con **DesignTokens defaults**; retokenizar cuando llegue HTML de Ñata (no bloquea) | Locked |
| **D3a** | Mantener split: Wishlists = Sprint 3, Items = Sprint 4 | Locked |
| **D4a** | **Hotwire mínimo** Secret Link en Sprint 3 (**obligatorio**) | Locked |
| **D5a** | Fundación de **notifications antes/con Sprint 5** | Locked |
| **D6a** | API+Flutter primario; web solo si SPEC lo exige (Secret Link) | Locked |
| **D7a** | Chore de **higiene de sesiones** | Locked |

Ñata HTML aún no listo — no bloquea (D2b).

## Orden MVP (locked)
3 Wishlists (+ Hotwire Secret Link) → 4 Items → **notif foundation (D5a)** → 5 Reservations → 6 Gifts → 7 Anti-spam → 8 Admin → 9 Mobile wrap-up.

## Secuencia de chore PRs
- **PR-A** (this branch): archive stale sessions; persist this session; ROADMAP signup/LIFE-001 wording; optional DESIGN_SYSTEM D2b note.
- **PR-B**: Signup P0 — must merge before explore/start Sprint 3.

## Preferencias de proceso (owner)
TDD hands-off al implementar · pause accept en code-review y sync-docs · QA al cerrar · español con owner vía coordinador.
  </working_notes>
</task_session>
