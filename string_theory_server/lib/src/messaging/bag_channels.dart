/// Channel naming and event types for real-time bag updates.
abstract final class BagChannels {
  /// Event published after a new session is logged.
  static const String sessionLogged = 'sessionLogged';

  /// Event published after a racquet is restrung (reserved for Story 4.1).
  static const String restrung = 'restrung';

  /// Returns the per-user bag channel name.
  static String forUser(int userId) => 'user_${userId}_bag';
}
