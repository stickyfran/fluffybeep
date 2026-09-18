# Implementación Completa — Features de FluffyBeep

Catálogo de todas las personalizaciones construidas sobre FluffyChat v2.9.4 (124 commits).
Referencia para portar a Element X u otros clientes Matrix.

**Fork Element X**: [stickyfran/fluffybeep-x](https://github.com/stickyfran/fluffybeep-x) — Branch: `fluffybeep`
**CI**: `build-fluffybeep.yml` activo — genera APK debug FDroid optimizado solo para `arm64-v8a` (reduce tamaño de artefactos de ~300MB a ~40-60MB) en cada push a `fluffybeep`

---

## 📋 Log de Investigación (2026-09-18)

### Hallazgos de Element X vs FluffyBeep

| Feature | Element X ya lo tiene? | Acción |
|---------|----------------------|--------|
| Audio OGG Opus | ✅ Sí — `OggOpusEncoder` nativo, `.ogg`, `audio/ogg` | No portar (excepto extras: earpiece, continuous play) |
| Background Sync | ⚠️ Push-only (FCM/UnifiedPush), sin foreground service | Evaluar según notificaciones actuales |
| Bridge Detection | ❌ No — trata todo como rooms vanilla Matrix | Evaluar si se necesita |
| Read Receipts | ⚠️ Básico — tiene `markAsRead` pero no smart features | Portar mejoras |
| Spaces | ✅ Sí — `SpaceFiltersState` con bottom sheet y filtrado | Personalizar (iconos permanentes) |

### Datos del Servidor (Live)

**Server**: `francomusco.duckdns.org` | **User**: `@franco:francomusco.duckdns.org`

#### Estructura de Espacios:
- **WhatsApp Space** (`!AMtfDMCaFAigCvnvlM`): 7 salas (Papa, Bruno, Ramiro, Esquirla, Pintura papitas, MESHEE y SIMON, Status Broadcast)
- **Instagram Space** (`!xzUfEAVKGzuGqhzAzs`): 16 salas (Thiago, Agus, Irma, Vichosky, E.Ch., Cielo, Franco Pérez, Acttflaco, Papá, Joaquín, Gustii, Ramiro Caraballo, Matti, Turbo Amadeo, Hora de Momingos, Jeremías)

#### Candidatos a Merge detectados (nombre coincide):
| WhatsApp | Instagram | Match |
|----------|-----------|-------|
| Papa (WA) `!qRoC...` | 𝑷𝒂𝒑𝒂 `!RlRI...` | ✅ Unicode-normalized "papa" == "papa" |
| Ramiro (WA) `!jZqK...` | Ramiro Caraballo `!VRKs...` | ✅ Token "ramiro" match |
| Hora de Momingos `!CXnk...` | Hora de Momingos `!CXnk...` | ⚠️ Mismo room en ambos spaces |
| Esquirla `!ghBZ...` | — | ❌ Solo en WA |

---

## Feature 1: 🔀 Unified Contact Merge (Beeper-style)

**Prioridad**: 🔴 Crítica | **Complejidad**: 🔴 Alta | **Estado**: 🚧 En Progreso (Fix de Navegación, Indicadores de Red en Avatares y Agrupación en Chat List)

Fusionar contactos de múltiples bridges (WhatsApp, Instagram, Signal, etc.) en una sola entrada del chat list con switcher entre redes.

**Implementación en Element X (`fluffybeep-x`)**:
- **Servicio y Dominio**: `ContactMergeService`, `MergedContact`, `MergedRoomSummary`, `detectNetwork` en `libraries/matrix/api` y `libraries/matrix/impl`.
- **Persistencia en la Nube & Compatibilidad FluffyBeep**:
  - Soporte directo para `com.beeper.merged_contacts` (formato original de FluffyBeep) y `m.fluffybeep.merges`.
  - Carga automática de los contactos fusionados existentes en la cuenta sin necesidad de re-fusionar.
  - Almacenamiento y sincronización de borradores (`merged_draft_<id>`) al swapear entre redes.
- **Gestión en Detalles del Chat (`RoomDetailsView`)**:
  - Sección dedicada de fusión de contactos.
  - Lista de salas hermanas vinculadas con indicador de sala activa y botón de desvinculación individual o total.
  - Diálogo de búsqueda y selección de chats unidos para vincular con un tap, con avatares y detección de red (WhatsApp, Instagram, Telegram, Signal, Matrix).
- **Corrección de Navegación / Swapping (Fix del Crash)**:
  - Causa del crash: `attachRoom` en `LoggedInFlowNode.kt` realizaba `waitForNavTargetAttached { it is NavTarget.Home }`, bloqueándose indefinidamente cuando la sala ya estaba abierta (`NavTarget.Room`).
  - Solución: Swapping de salas hermanas usa `backstack.replace(NavTarget.Room(...))` en `LoggedInFlowNode` sin apilar en el historial, y `attachRoom` acepta `NavTarget.Home || NavTarget.Room`.
- **Indicadores de Red (Puntitos de Color en Avatares)**:
  - WhatsApp: Verde `#25D366`
  - Instagram: Rosa `#E1306C`
  - Telegram: Azul `#2AABEE`
  - Signal: Azul `#3A76F0`
  - En la lista de chats (`RoomSummaryRow`), cada avatar muestra su puntito de red en la esquina inferior derecha.
  - En contactos fusionados, el avatar muestra una fila compuesta de puntitos (ej. verde + rosa) representando todas sus redes activas.
- **Agrupación en Lista de Chats (`RoomListPresenter`)**:
  - Las salas hermanas pertenecientes a un mismo `MergedContact` se colapsan en una sola fila en la lista de chats, mostrando la suma de no leídos y el último evento/timestamp.
- **Switcher de Red en Timeline/Composer (`MessagesView`)**:
  - Mini-avatares con indicador de red y nombre de plataforma.
  - Badge de no leídos en redes inactivas.
  - Cambio inmediato de red y preservación del texto que se esté escribiendo.
- **Tests Unitarios**: Suites de `:libraries:matrix:impl`, `:features:roomdetails:impl`, `:features:messages:impl` y `:features:home:impl`.

**Sub-features futuras / En el tintero**:
- **Resolución de Nombres vía Contactos Locales (`ContactsContract` / `READ_CONTACTS`)**:
  - Extraer número de teléfono/JID desde el Matrix ID del bridge (`@whatsapp_54911xxxx:server` -> `+54 9 11 xxxx`).
  - Consultar la libreta de direcciones del teléfono Android para resolver y sobreescribir el display name con el nombre guardado en la agenda local (ej. *"Papá"* en lugar del nombre de perfil de WhatsApp/Matrix).
  - Cache en memoria y actualización reactiva al cambiar contactos.
- Algoritmo de token similarity ranking para auto-merge
- Strip network prefix en previews de chat list (quitar "(WA)", "(IG)" superfluos)
- Integración bidireccional con CardDAV / Radicale (server-side vCards)

---

## Feature 2: 🎙️ Audio/Voice Notes Pipeline (WhatsApp OGG Opus)

**Prioridad**: 🔴 Crítica | **Complejidad**: 🔴 Alta | **Estado**: 🔍 Verificar en Element X

Recording → OGG Opus nativo (RFC 7845) → stream copy remuxing → waveform scrubber con haptics → speaker/earpiece toggle → continuous playback → pre-caching.

**Commits**: `43ebc9f`, `a8c8629`, `5fbbebd`, `a8381a6`, `fc466fc`, `a54762a`, `b4becec`, `779ef8b`, `fb430e3`, `73d6c60`

**Sub-features**:
- Grabación directa en OGG Opus (NO AAC/m4a)
- FFmpeg stream copy remuxing (`-c:a copy`) en contenedor OGG limpio
- Waveform scrubber sincronizado con Canvas custom y haptics
- Toggle speaker/earpiece con proximity sensor y persistencia
- Reproducción continua de audios en una sala (auto-advance)
- Pre-cache de voice notes visibles en viewport
- Velocidad persistente (1x, 1.5x, 2x)
- Instant play-pause con UI state priorizado
- Loading indicator y manejo de cache mismatch
- Metadata PTT correcta para bridge mautrix-whatsapp

**Invariante crítico**: WhatsApp bridges requieren estrictamente `audio/ogg` Opus con extensión `.ogg`.

---

## Feature 3: 🌐 Bridge Network Detection & Launchers

**Prioridad**: 🟡 Alta | **Complejidad**: 🟡 Media | **Estado**: 🔍 Verificar en Element X

Detectar bridge type de cada room, mostrar indicadores visuales, lanzar app nativa para llamadas/acciones.

**Commits**: `9aaa0b8`, `b03f058`, `8fd0d34`, `3d51979`, `7f81d0c`, `81ff0c7`, `6aeb65b`

**Sub-features**:
- Parseo de room state events para identificar bridge type
- Iconos/dots de red en chat list y header
- Intent launcher para abrir WhatsApp/Instagram/Signal con deep links
- Redirección de llamadas entrantes vía bridge a app nativa
- Auto-launch de WhatsApp en incoming call push
- Network indicator dots (half-size)
- Configuración de paquetes de apps personalizados

---

## Feature 4: 🔄 Background Sync & Foreground Service

**Prioridad**: 🟡 Alta | **Complejidad**: 🟡 Media | **Estado**: 🔍 Verificar en Element X

Sincronización completa en background con foreground service, checkpoints, y banner de progreso.

**Commits**: `9954fc0`, `ac5dc5d`, `52cad0d`

**Sub-features**:
- Foreground service con notificación persistente
- Full resync de rooms, avatares y contactos
- Floating banner de progreso
- Checkpoints para Beeper sync
- Android 14 shortService watchdog
- Throttling inteligente según nivel de batería

---

## Feature 5: 📬 Smart Read Receipts & Unread Management

**Prioridad**: 🟡 Alta | **Complejidad**: 🟢 Baja | **Estado**: ⏳ Planificada para Element X

Mark-as-read inteligente, floating manual read button, suppress badge, retry robusto.

**Commits**: `0901a3d`, `bed9391`, `eded096`, `84c6d0a`, `2d8723f`, `8681463`, `1533f5b`, `64afec8`

**Sub-features**:
- Detectar reply propio (app o PC) y marcar sala como leída
- Floating manual read button con animación
- Suppress unread badge cuando último evento es mío
- Reintentos robustos para setReadMarker con backoff exponencial
- Optimistic unread state
- Hide floating button cuando no hay unreads

---

## Feature 6: 🗣️ Whisper On-Device Transcription

**Prioridad**: 🔴 Crítica | **Complejidad**: 🔴 Alta | **Estado**: 🔜 Posterior

Transcripción local de voice notes usando whisper.cpp sin enviar audio a servidores.

**Commits**: `1b11317`, `d8b5a73`

**Sub-features**:
- Integración whisper.cpp vía JNI / whisper_ggml
- Background transcription service
- Botón de transcribir bajo cada audio
- Texto inline bajo el audio con progreso
- Gestión de modelos por idioma
- Cuantización INT8, GPU delegate

---

## Feature 7: 🤖 AI Contact Profile & Ask AI

**Prioridad**: 🟡 Alta | **Complejidad**: 🟡 Media | **Estado**: ⏳ Planificada para Element X

Perfil de contacto enriquecido con AI on-device + consulta AI sobre historial de chat.

**Commits**: `2497c36`, `4b6aa22`, `7eb0dd9`, `cb13efb`, `0b3ea12`

**Sub-features**:
- Notas privadas de contacto en Matrix `account_data`
- Perfil estructurado (hobbies, fechas importantes, relación)
- Auto-detección de nombre y datos del historial
- Contextualización de eventos con fechas/horas
- Ask AI: consulta contextualizada sobre historial de chat
- Limpieza de memoria para consultas grandes
- AI checkpoints en detalles de contacto

---

## Feature 8: 📅 Scheduled Messages

**Prioridad**: 🟢 Medio | **Complejidad**: 🟡 Media | **Estado**: 🔜 Posterior

Programar mensajes para envío futuro.

**Commits**: `84d17d6`, `8bee495`, `2c954b1`

**Sub-features**:
- Persistencia local de mensajes programados
- AlarmManager/WorkManager para envío puntual
- Picker de fecha/hora
- Indicador en timeline
- Gestión de mensajes programados (editar/cancelar)
- Collapsable navigation rail en mobile

---

## Feature 9: 🎨 Instagram Sticker Conversion

**Prioridad**: 🟢 Medio | **Complejidad**: 🟢 Baja | **Estado**: 🔜 Posterior

Soporte de stickers animados de Instagram bridge.

**Commits**: `855f57f`, `bec7e67`, `040253d`, `22f9db6`

**Sub-features**:
- Detección de stickers en rooms de Instagram bridge
- Conversión GIF animado → PNG/WebP
- Envío como `m.image` para compatibilidad con bridge
- Offload de conversión a isolate/background thread
- Manejo seguro de sticker body nullable

---

## Feature 10: 📊 Crash/Freeze Logger con Breadcrumbs

**Prioridad**: 🟡 Alta | **Complejidad**: 🟢 Baja | **Estado**: 🔜 Posterior

Logger dedicado de crashes y freezes con breadcrumbs de navegación.

**Commits**: `8739b9f`, `0fb5358`, `acbdb29`, `486749f`

**Sub-features**:
- Interceptor de crashes con stack traces
- Breadcrumbs de navegación en tiempo real
- Filtro de lifecycle en background (evitar false positives)
- Watchdog thread para detectar ANR/freeze
- Export de logs con botón de compartir
- Breadcrumb de chat context con MatrixLocals

---

## Feature 11: 🎨 UI Polish

**Prioridad**: 🟢 Medio | **Complejidad**: 🟢 Baja | **Estado**: 🔜 Posterior

Mejoras visuales y opciones de personalización.

**Commits**: `17ff946`, `2b726c1`, `8d738bc`, `fe125f2`

**Sub-features**:
- Avatares squircle opcionales
- Bubble gradient toggleable
- Dark neutral bubble option
- Translucent floating bars con blur
- Collapsable navigation rail en mobile
- Filter y reorder animations
- Stickers button movido al menú add con setting

---

## Feature 12: 📥 Full History Downloader

**Prioridad**: 🟢 Medio | **Complejidad**: 🟡 Media | **Estado**: ⏳ Planificada para Element X

Descarga completa del historial de una sala.

**Commits**: `f5590bf`, `261cb3f`, `2cd79d0`

**Sub-features**:
- Descarga paginada de todo el historial
- Indicador de progreso con porcentaje
- Cancelación en cualquier momento
- Auto-fetch initial history en chats vacíos
- Spinner en lugar de botón redundante de "load more"
- Acceso desde popup menu del chat y detalles del contacto

---

## Feature 13: 📝 Input Draft Sharing entre Merged Chats

**Prioridad**: 🟢 Medio | **Complejidad**: 🟢 Baja | **Estado**: ⏳ Planificada para Element X

Preservar y compartir borrador de input al cambiar entre chats fusionados del mismo contacto.

**Commits**: `d26a5620`

**Sub-features**:
- Persistencia de draft por room
- Compartición automática entre siblings de un merge
- Restauración del draft al volver a un chat

---

## Feature 14: 🚀 Custom Spaces / Persistent Space Icons (Telegram-style Bottom Nav)

**Prioridad**: 🔴 Crítica | **Complejidad**: 🟡 Media | **Estado**: ✅ Implementada y Verificada

Desplegar los espacios (WhatsApp, Instagram, etc.) como iconos permanentes en la barra de navegación principal tipo Telegram en lugar de requerir abrir el modal de Spaces.

**Implementación en Element X (`fluffybeep-x`)**:
- **Navegación Inferior Flotante**: Se expandió `HomeView` y `HorizontalFloatingToolbar` para integrar los accesos directos a Espacios con scroll horizontal.
- **Acceso Directo de 1 Tap**:
  - Pestaña "Todos los chats" fija al inicio.
  - Pestañas para cada Espacio unido con avatar circular y nombre.
  - Indicador de selección activa con resaltado y pills estilizados según tokens Compound (`ElementTheme.colors`).
  - Botón selector/expansor de espacios al final para gestionar o ver la lista completa.
- **Presenter y Estado**:
  - `SpaceFiltersState`: expone `allSpaces: ImmutableList<SpaceSummary>` directamente a la barra de navegación.
  - `SpaceFiltersEvent.SelectSpaceDirectly(spaceId: RoomId?)`: filtra la lista de chats de inmediato sin abrir el bottom sheet.
- **Tests Unitarios**: 13 tests pasando en `:features:home:impl:testDebugUnitTest` (`SpaceFiltersPresenterTest`).

---



Estas ~40+ personalizaciones de FluffyBeep **no necesitan portarse** porque Element X (nativo + Rust) las resuelve por diseño:

### Performance (~30 commits)
- RepaintBoundary para chat list, waveform, rail items → Compose tiene recomposición granular
- MxcImage retry cap, lifecycle bypass → Coil/Glide en Android nativo
- Presence LRU, dispose value notifiers → Kotlin coroutines + StateFlow
- Debounce search/space search → Flow.debounce()
- Battery optimizations (WidgetsBindingObserver, vsync) → Lifecycle-aware components
- MouseRegion avoidance on mobile → No aplica en Compose
- Skeleton alpha optimization → Compose modifier.alpha()
- Binary search insertion para chat list → DiffUtil en LazyColumn

### Database & Build (~10 commits)
- SQLCipher key handling, WAL mode → matrix-rust-sdk usa su propio store
- Gradle build fixes, compileSdk overrides → Específicos de FluffyChat
- Flutter plugin conflicts → No aplica

### Flutter-specific (~5 commits)
- dart:async imports → No aplica
- Flutter widget lifecycle management → Compose lifecycle
- AnimatedSwitcher syntax fixes → No aplica
