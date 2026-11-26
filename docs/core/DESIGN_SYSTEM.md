# Shared Design System (`DESIGN_SYSTEM.md`)

> **Purpose:** Single source of truth for visual design tokens (color palette, typography, icon style, navigation layout, spacing, and elevation) shared across the Rails 8 Hotwire/Tailwind CSS web client (`backend/`) and the Flutter iOS/Android mobile client (`mobile/`). Maintained automatically by `sync-docs`.

## 1. Interactive Co-Founder Design Studio
- **Live Exploration Artifact:** [`docs/estudio_diseno_visual_ceci_nata.html`](../estudio_diseno_visual_ceci_nata.html)
- **Status:** Awaiting final visual selection file (`diseno_visual_nata_completado.html`) from co-founder **Ceci Pinilla ("Ñata")**.
- **Interim policy (D2b, 2026-11-26):** Ship and iterate with current `DesignTokens` / theme defaults until Ñata’s final HTML lands; retokenize afterward. Do not block sprints on design lock.

## 2. Token Architecture (Parameterized for Web & Flutter)
Both clients consume the following semantic design tokens so the entire visual identity updates from a single definition:

| Token Category | Semantic Keys | Web Target (`Tailwind CSS`) | Mobile Target (`Flutter ThemeData`) |
| :--- | :--- | :--- | :--- |
| **Color Palette (Light & Dark)** | `bg`, `surface`, `text`, `muted`, `primary`, `primaryFg`, `accent`, `accentBg`, `border`, `specBg` | CSS Custom Properties (`--c-bg`, `--c-primary`, etc.) | `ColorScheme` + custom `AppColors` `ThemeExtension` |
| **Typography** | `headingFont`, `bodyFont`, `headingWeight` | Google Fonts + `font-display` / `font-sans` | `google_fonts` package (`TextTheme`) |
| **Iconography** | `iconStyle` (`minimal`, `solid-pill`, `pastel-circle`, `brutalist-sticker`, `gradient-badge`, `filled-bold`, `dashed-tag`, `duotone-ring`) | SVG stroke/container utility classes | Custom `AppIconBadge` widget |
| **Navigation Layout** | `navStructure` (`4-tabs`, `5-tabs-fab`, `floating-pill`, `3-tabs-top-bar`) | Responsive bottom/side navigation partial | `AppScaffold` navigation bar adapter |

## 3. Core Component Invariants (`[REQ-ITEM-001]`, `[REQ-ITEM-004]`, `[REQ-RES-002]`)
1. **Prominent Item Specifications Box (`[REQ-ITEM-001]`):** Every wishlist item card renders the owner's `specifications` note (color, size, variant clarification) directly below the item title/image using `specBg` and `accent` left border so friends never miss exact gift instructions.
2. **Zero Spoilers for Owner (`[REQ-RES-002]`):** When viewing one's own wishlist, item cards never display reservation badges, timestamps, or purchase states.
3. **Separated Received Gifts Section (`[REQ-ITEM-004]`):** Items confirmed as `received_confirmed` move to a dedicated *"Regalos Recibidos" / "Received Gifts"* section at the bottom of the wishlist.
