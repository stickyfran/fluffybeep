import 'package:matrix/matrix.dart';

class BeeperBridgeUtils {
  /// Regular expression to detect Beeper bridge bots.
  /// Matches pattern like: @whatsappbot:beeper.local
  static final RegExp beeperBotRegex = RegExp(r'^@.*bot.*:beeper\..*$');

  /// Checks if a given matrix user ID belongs to a Beeper bridge bot.
  static bool isBeeperBot(String userId) {
    return beeperBotRegex.hasMatch(userId);
  }

  /// Determines if a room is a "Fake DM" created by Beeper.
  /// A Fake DM is defined as a room with exactly 3 members:
  /// 1. The local user (You)
  /// 2. The real contact
  /// 3. The Beeper bridge bot
  static bool isFakeDM(Room room) {
    final members = room.getParticipants();
    
    // A Fake DM must have exactly 3 participants (including the local user)
    if (members.length != 3) {
      return false;
    }

    bool hasLocalUser = false;
    bool hasBot = false;
    bool hasRealContact = false;

    final clientUserId = room.client.userID;

    for (var member in members) {
      if (member.id == clientUserId) {
        hasLocalUser = true;
      } else if (isBeeperBot(member.id)) {
        hasBot = true;
      } else {
        hasRealContact = true;
      }
    }

    return hasLocalUser && hasBot && hasRealContact;
  }

  /// Extracts the real contact from a Fake DM room.
  /// Returns null if it's not a Fake DM or if the contact cannot be found.
  static User? getRealContactFromFakeDM(Room room) {
    if (!isFakeDM(room)) return null;

    final members = room.getParticipants();
    final clientUserId = room.client.userID;

    for (var member in members) {
      if (member.id != clientUserId && !isBeeperBot(member.id)) {
        return member;
      }
    }
    
    return null;
  }
}
