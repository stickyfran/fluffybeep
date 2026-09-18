# Roadmap: Integración PIM (CardDAV, CalDAV y Asistente Integral)

Este documento registra la estrategia y arquitectura para evolucionar Fluffybeep desde un cliente de mensajería unificada hacia un PIM (Personal Information Manager) completo y autónomo.

---

## 1. Arquitectura de Servidor (OCI ARM64)

* **Servidor PIM Recomendado:** **Radicale** (Python 3).
  * Consumo: ~25 MB RAM.
  * Protocolos: CardDAV (RFC 6352 - Contactos vCard 4.0) y CalDAV (RFC 4791 - Calendario iCal .ics).
  * Exposición: Vía Caddy bajo `https://francomusco.duckdns.org/radicale/` con SSL automático y autenticación básica.

---

## 2. Los 3 Pilares de Integración

### A. Libreta de Contactos (CardDAV <-> Fluffybeep / WhatsApp / Instagram)
* **Auto-Creación de Contactos:** Cuando entra un chat nuevo de WhatsApp o Instagram, el daemon del servidor extrae nombre, teléfono/handle y avatar, creando o actualizando la vCard 4.0 en Radicale.
* **Modelo Enriquecido:** Mapeo de `contact_profile.dart` (cumpleaños, profesión, notas) directamente a campos estándar de vCard (`BDAY`, `TITLE`, `NOTE`, `X-INSTAGRAM`).
* **Sincronización Móvil:** Vía **DAVx5** en Android, integrando los contactos directamente en la agenda nativa del teléfono para que `beeper_phone_contacts.dart` los consuma a velocidad de memoria local.

### B. Calendario y Citas Inteligentes (CalDAV <-> Chat AI)
* **Detección de Compromisos en Conversaciones:** El asistente de IA analiza mensajes entrantes buscando intenciones de agenda ("nos vemos el jueves a las 18hs").
* **Sugerencia de Eventos:** El daemon genera el borrador del evento `.ics` en CalDAV y en el timeline de Fluffybeep se renderiza una tarjeta interactiva para aceptar o descartar la reunión.
* **Recordatorios y Cumpleaños:** Los cumpleaños extraídos de los perfiles se sincronizan en el calendario de CalDAV con alertas automáticas.

### C. Almacenamiento y Notas (WebDAV)
* Sincronización de notas rápidas del contacto y respaldos de configuración.

---

## 3. Fases de Ejecución

1. **Fase 1 (Infraestructura PIM):**
   * Añadir servicio Radicale a `docker-compose.yml` en el servidor OCI.
   * Rutas en Caddyfile para `/radicale/*` y well-known (`/.well-known/caldav`, `/.well-known/carddav`).
   * Validación con DAVx5 en Android.
2. **Fase 2 (Auto-Enlace Server-Side):**
   * Daemon Python sincronizando JIDs y salas con vCards de Radicale.
3. **Fase 3 (Smart Scheduling IA):**
   * Extracción de eventos y creación de objetos iCalendar.
4. **Fase 4 (UI en Fluffybeep):**
   * Pestaña/Drawer de Contactos y Calendario unificados dentro de la aplicación.
