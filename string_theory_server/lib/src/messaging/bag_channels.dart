import 'package:serverpod/serverpod.dart';

/// Channel naming and event types for real-time bag updates.
abstract final class BagChannels {
  /// Event published after a new session is logged.
  static const String sessionLogged = 'sessionLogged';

  /// Event published after a racquet is restrung (see `BagEndpoint.restringRacquet`).
  static const String restrung = 'restrung';

  /// Event published when the daily decay run changes a racquet's health score.
  static const String decayed = 'decayed';

  /// Returns the per-user bag channel name.
  static String forUser(UuidValue userId) => 'user_${userId.uuid}_bag';
}
