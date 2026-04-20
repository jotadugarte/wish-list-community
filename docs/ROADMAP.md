# Project Roadmap

Things done and things left to do. Update this when finishing branches; use `roadmap-manage` to add, prioritize, or catalog items.

**Format:** Use `[x]` for done, `[ ]` for pending. Add `(REQ-ID)` to link to SPEC. Add `— YYYY-MM-DD` for done date. Add `— Branch: name` for in-progress. Add `— Depends on: Item` for dependencies.

---

## Done
*(No completed items yet)*

## In Progress
*(No items currently in progress)*

## Pending (by priority)
- [ ] **MVP Sprint 1 — Base + Auth nativa Rails 8**
  - [ ] Authentication (sign up, login, logout, sessions), gem "authentication-zero"
  - [ ] Reset password (MVP; confirmación de email queda para v1)
  - [ ] Perfil público: `username` único (email privado), cambio con cooldown
  - [ ] Bloquear usuarios (bloqueo gana: corta acceso inmediato incluso si había amistad/share/link)
  - [ ] Soft-delete + restaurar (wishlist restaura items; al restaurar no hay “reservas fantasma”)
- [ ] **MVP Sprint 2 — Social**
  - [ ] Buscar usuarios por `username`
  - [ ] Solicitudes de amistad + aceptar/declinar + lista de amigos (solo amigos en MVP)
  - [ ] Reportar usuario (MVP: solo reportes; moderación completa en Sprint 8)
- [ ] **MVP Sprint 3 — Wishlists (privacidad + compartir)**
  - [ ] CRUD wishlist
  - [ ] Privacidad por wishlist:
    - [ ] Pública: visible en Discover y por link
    - [ ] Privada: visible solo para amigos
    - [ ] Compartida: solo amigos específicos + link secreto
  - [ ] Link secreto (no caduca); al pasar a “privada” se invalida automáticamente
  - [ ] Invitado puede ver wishlists públicas (Discover y por link); no puede reservar/regalar
- [ ] **MVP Sprint 4 — Items + media**
  - [ ] CRUD items con notas (talla/color) y múltiples links por item
  - [ ] Hasta 3 imágenes por item:
    - [ ] Máx 2MB c/u, máx 1600px lado mayor
    - [ ] Compresión en cliente opcional (UX)
    - [ ] Servidor obligatorio: resize + re-encode (WebP cuando sea posible; PNG permitido y convertir a WebP cuando aplique)
- [ ] **MVP Sprint 5 — Reservas (privadas)**
  - [ ] Reservar item (solo usuarios logueados con acceso) con concurrencia “primer reservado gana”
  - [ ] Una reserva activa por item
  - [ ] Nota privada del reservador (nadie más la ve)
  - [ ] Fecha estimada privada del reservador (receptor nunca ve reservas)
  - [ ] Si fecha expira: notificar reservador “Fecha expiró”; reservador decide extender fecha o quitar reserva (no auto-liberar)
- [ ] **MVP Sprint 6 — Regalado + anonimato + resolución de conflicto**
  - [ ] Marcar item como “regalado” (dueño o regalador), incluso si nadie reservó
  - [ ] Anónimo para usuarios; admin puede auditar
  - [ ] Al marcar “regalado”:
    - [ ] Cancelar reserva activa/expirada si existe
    - [ ] Notificar al reservador “Ya fue entregado; reserva removida”
  - [ ] Guardar referencia del link usado en regalo “online” (solo visible para admin)
- [ ] **MVP Sprint 7 — Discover + anti-spam + reportes**
  - [ ] Discover (usuarios públicos + wishlists públicas), sin follow/like
  - [ ] Rate limits (anti-spam) + reportar wishlist
  - [ ] Contenido sensible: manejo solo por reportes (sin revisión automática en MVP)
- [ ] **MVP Sprint 8 — Admin/Moderación**
  - [ ] Panel admin: cola de reportes + acciones (bloquear)
  - [ ] Admin puede ver historial interno (reservas/regalos/cambios) y revertir por error/abuso
  - [ ] Admin ve identidad de regaladores (para auditoría) y link usado en online-gift
- [ ] **MVP Sprint 9 — iOS + Android (Turbo Native)**
  - [ ] Apps Turbo Native con paridad MVP web
  - [ ] Deep links: perfil público, wishlist pública, link secreto
  - [ ] Upload de imágenes desde móvil respetando límites
  - [ ] Push notifications: opcional (email + in-app son requeridos)
- [ ] **Notificaciones (MVP) — in-app + email (configurable por usuario)**
  - [ ] Preferencias por evento (in-app/email toggles)
  - [ ] Dispatcher único para crear in-app + encolar email
  - [ ] Eventos mínimos:
    - [ ] Solicitud de amistad recibida
    - [ ] Amistad aceptada
    - [ ] Fecha de reserva expirada (solo reservador)
    - [ ] Reserva cancelada por regalo entregado (solo reservador)

## Backlog
- [ ] **v1 Sprint A — Actividades (sistema configurable)**
  - [ ] Crear actividad grupal (owner, nombre, fechas, moneda única, budget por regalo individual)
  - [ ] Configuración al crear actividad:
    - [ ] `assignment_mode`: `secret_santa` (1→1) / `open_gifting` (todos a todos)
    - [ ] `visibility_mode`: `recipient_only` / `all_participants`
    - [ ] `reservation_visibility`: `hidden_from_recipient` / `visible_to_recipient`
  - [ ] Invitar amigos / aceptar participantes (bloqueos impiden participación)
  - [ ] Sorteo para `secret_santa`
- [ ] **v1 Sprint B — Actividades (listas + reservas + budget)**
  - [ ] Cada usuario agrega sus items de actividad (precio manual + moneda)
  - [ ] Reservas dentro de actividad (open_gifting permite reservar para múltiples personas)
  - [ ] Validación budget: no permitir reservar item con precio > budget (por regalo individual)
- [ ] **v1 — Confirmación de email**
- [ ] **v1 — Compartir con no-amigos**
  - [ ] Compartir con cualquier usuario (no-amigo) + hardening anti-abuso
- [ ] **Backlog v1 — Actividades: “no repetir del año pasado” (opcional)**
- [ ] **Backlog — Validar precio contra link (best-effort)**

<!-- 
Example formats:
- [x] Auth & sessions (REQ-AUTH-001) — 2026-02-15
- [ ] User dashboard (REQ-DASH-001) — Branch: feature/dashboard
1. [ ] Export to CSV (REQ-EXPORT-001)
-->
