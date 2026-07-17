# Guía de Modificaciones para el Parche Unificado (0000-unified-fluffybeep.patch)

Esta guía detalla los bloques de código exactos en Dart y los archivos clave de Fluffychat que deben modificarse dentro del archivo `.patch` unificado para habilitar el soporte nativo de Beeper.

## 1. Interceptar Nombres y Avatares de las Salas

Para ocultar al bot de la lista de miembros y forzar que la sala tome el nombre y el avatar exclusivo del contacto real en los "Fake DMs", debes modificar las extensiones o propiedades del modelo `Room`. En Fluffychat, la lógica de presentación de salas suele estar en `lib/utils/room_status_extension.dart` o directamente en las extensiones del paquete Matrix (`matrix_api_lite`/`matrix`).

### Archivo a parchear:
`lib/utils/room_name_extension.dart` (o equivalente donde se resuelva el `displayname` y `avatarUrl` de la sala).

### Bloque de Código (Diff Patch):

```diff
--- a/lib/utils/room_name_extension.dart
+++ b/lib/utils/room_name_extension.dart
@@ -1,5 +1,6 @@
 import 'package:matrix/matrix.dart';
 import 'package:flutter/material.dart';
+import 'package:fluffychat/utils/beeper_bridge_utils.dart'; // [NUEVO]
 
 extension RoomNameExtension on Room {
   String localizedName(BuildContext context) {
+    // [NUEVO] Intercepción de Beeper para Fake DMs
+    if (BeeperBridgeUtils.isFakeDM(this)) {
+      final realContact = BeeperBridgeUtils.getRealContactFromFakeDM(this);
+      if (realContact != null) {
+        return realContact.displayName ?? realContact.id;
+      }
+    }
+    
     // Lógica original de Fluffychat para nombres...
     if (name != null && name!.isNotEmpty) return name!;
     if (isDirectChat) return directChatMember?.displayName ?? 'Empty room';
     return 'Chat';
   }
   
   Uri? get avatarUri {
+    // [NUEVO] Intercepción de Beeper para avatar de Fake DMs
+    if (BeeperBridgeUtils.isFakeDM(this)) {
+      final realContact = BeeperBridgeUtils.getRealContactFromFakeDM(this);
+      if (realContact != null && realContact.avatarUrl != null) {
+        return realContact.avatarUrl;
+      }
+    }
+
     // Lógica original...
     return avatar;
   }
 }
```

## 2. Soporte de Carpetas / Etiquetas de Beeper

Beeper sincroniza las carpetas (etiquetas) mediante eventos globales de `account_data` (`com.beeper.labels`). Debes modificar el controlador principal o el proveedor de la lista de chats para filtrar por estas etiquetas.

### Archivo a parchear:
`lib/controllers/chat_list_controller.dart` (o donde Fluffychat estructure la lista de `Room`).

### Bloque de Código (Diff Patch):

```diff
--- a/lib/controllers/chat_list_controller.dart
+++ b/lib/controllers/chat_list_controller.dart
@@ -45,6 +45,21 @@
   List<Room> get sortedRooms {
     var rooms = client.rooms;
     
+    // [NUEVO] Lógica de filtrado por etiquetas de Beeper
+    // Para leer account_data: client.accountData['com.beeper.labels']
+    final beeperLabelsData = client.accountData['com.beeper.labels'];
+    if (beeperLabelsData != null && currentSelectedLabel != null) {
+      // beeperLabelsData contiene un mapeo de room_id a lista de etiquetas
+      rooms = rooms.where((room) {
+        // Parsear el JSON para ver si currentSelectedLabel está asociado a room.id
+        final labelsForRoom = beeperLabelsData.content[room.id] as List<dynamic>?;
+        if (labelsForRoom != null && labelsForRoom.contains(currentSelectedLabel)) {
+          return true;
+        }
+        return false;
+      }).toList();
+    }
+
     // Lógica original de ordenamiento...
     rooms.sort((a, b) => b.lastEvent?.originServerTs.compareTo(a.lastEvent?.originServerTs ?? 0) ?? 0);
     return rooms;
   }
```

## 3. UI de Bloqueo y Resincronización (Re-Inicialización de Caché)

Inyectar un botón en la pantalla de Ajustes que dispare la limpieza y muestre el `CircularProgressIndicator` en un `Overlay`.

### Archivo a parchear:
`lib/pages/settings/settings_page.dart`

### Bloque de Código (Diff Patch):

```diff
--- a/lib/pages/settings/settings_page.dart
+++ b/lib/pages/settings/settings_page.dart
@@ -5,6 +5,7 @@
 import 'package:fluffychat/config/app_config.dart';
 import 'package:fluffychat/widgets/layouts/max_width_body.dart';
+import 'package:fluffychat/controllers/beeper_reinit_controller.dart'; // [NUEVO]
 
 class SettingsPage extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(title: Text('Settings')),
       body: ListView(
         children: [
           // ... opciones originales ...
           
+          // [NUEVO] Botón de purga Beeper
+          ListTile(
+            leading: const Icon(Icons.sync_problem, color: Colors.orange),
+            title: const Text('Forzar Sincronización (Beeper)'),
+            subtitle: const Text('Reconstruye la base de datos de chats sin cerrar sesión.'),
+            onTap: () async {
+              final client = Matrix.of(context).client;
+              await BeeperReinitController.showReinitOverlay(context, client);
+              ScaffoldMessenger.of(context).showSnackBar(
+                const SnackBar(content: Text('Sincronización completada exitosamente.')),
+              );
+            },
+          ),
+
           ListTile(
             leading: const Icon(Icons.logout, color: Colors.red),
             title: const Text('Logout'),
```
