import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class BeeperReinitController {
  final Client client;

  BeeperReinitController({required this.client});

  /// Purges local cache (Hive/SQLite tables for messages and avatars)
  /// and resets the sync token, forcing the app to rebuild the state
  /// without logging out the user.
  Future<void> reinitCache(BuildContext context) async {
    try {
      // 1. Stop the current sync process
      client.stopSync();

      // 2. Clear the database cache while keeping keys and session
      // Fluffychat's matrix client allows clearing cache without losing e2ee keys.
      await client.database?.clearCache();

      // 3. Reset the sync token (since token) so that it fetches from scratch
      client.since = '';
      
      // Optionally reset the prev_batch of all rooms
      for (var room in client.rooms) {
        room.clear();
      }

      // 4. Restart sync
      client.startSync();

    } catch (e) {
      debugPrint('Error during Beeper cache reinitialization: $e');
      rethrow;
    }
  }

  /// Displays an overlay to block the UI while reinitializing.
  static Future<void> showReinitOverlay(BuildContext context, Client client) async {
    final overlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          const ModalBarrier(
            color: Colors.black54,
            dismissible: false,
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Re-sincronizando chats (Beeper)...',
                    style: TextStyle(fontSize: 16, decoration: TextDecoration.none),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(overlay);

    try {
      final controller = BeeperReinitController(client: client);
      await controller.reinitCache(context);
    } finally {
      // Remove overlay after sync restarts
      overlay.remove();
    }
  }
}
