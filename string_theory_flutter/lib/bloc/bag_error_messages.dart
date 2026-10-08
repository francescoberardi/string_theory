import 'package:string_theory_client/string_theory_client.dart';

import '../services/offline_session_queue.dart';

/// A `BagBloc` operation whose failure is surfaced to the user.
enum BagOperation {
  loadBag,
  addRacquet,
  deleteRacquet,
  setPrimaryRacquet,
  seedSampleBag,
  fastForwardRacquetAge,
  logSession,

  /// Persisting a session in the local offline queue.
  saveSessionOffline,
  restringRacquet,
}

const _connectionHint = ' Check your connection and try again.';
const _sessionExpiredMessage =
    'Your session expired. Restart the app to sign in again.';

/// Shown with a sign-in action when a session log hits an expired session.
const logSessionExpiredMessage =
    'Your session expired. Sign in to keep logging sessions.';
const _racquetGoneMessage = 'That racquet is no longer in your bag.';
const _duplicateWorkoutMessage =
    'This workout is already logged on another account.';
const _logRejectedMessage = "Couldn't log this session. Please try again.";
const _saveOfflineFailedMessage =
    "Couldn't save this session. Please try again.";

String _addRejectedMessage(String name) =>
    "Couldn't add \"$name\". Check the racquet details and try again.";

String _unstrungMessage(String name) =>
    '"$name" has no strings mounted. Restring it before logging a session.';

/// Error shown when restringing [racquetName] fails for a reason other than
/// an expired session or a vanished racquet.
String restringFailureMessage(String racquetName) =>
    'Could not restring "$racquetName".$_connectionHint';

/// Plain-words copy for a failed [operation].
///
/// Classifies [error] by status code only, never by its text, so no
/// exception type, status code or server message reaches the user. Errors
/// without a recognised code (network, timeout, 5xx, unknown) get the
/// operation's connection fallback.
///
/// [racquet] is the target racquet as it was before the failure; a
/// log-session 400 on a racquet without an active stringbed means it is
/// unstrung. [racquetName] names a racquet not yet in the bag (add);
/// otherwise the name is taken from [racquet].
String bagErrorMessage(
  BagOperation operation,
  Object error, {
  Racquet? racquet,
  String? racquetName,
}) {
  final statusCode = statusCodeOf(error);
  if (statusCode == 401) {
    return operation == BagOperation.logSession
        ? logSessionExpiredMessage
        : _sessionExpiredMessage;
  }

  final name = racquetName ?? racquet?.name ?? 'this racquet';
  final targetsRacquet = switch (operation) {
    BagOperation.deleteRacquet ||
    BagOperation.setPrimaryRacquet ||
    BagOperation.fastForwardRacquetAge ||
    BagOperation.logSession ||
    BagOperation.restringRacquet => true,
    _ => false,
  };
  if (targetsRacquet && statusCode == 404) return _racquetGoneMessage;

  return switch (operation) {
    BagOperation.loadBag => "Couldn't load your bag.$_connectionHint",
    BagOperation.addRacquet when statusCode == 400 => _addRejectedMessage(
      name,
    ),
    BagOperation.addRacquet => "Couldn't add \"$name\".$_connectionHint",
    BagOperation.deleteRacquet =>
      "Couldn't remove this racquet.$_connectionHint",
    BagOperation.setPrimaryRacquet =>
      "Couldn't set your primary racquet.$_connectionHint",
    BagOperation.seedSampleBag =>
      "Couldn't load the sample bag.$_connectionHint",
    BagOperation.fastForwardRacquetAge =>
      "Couldn't fast-forward this racquet.$_connectionHint",
    BagOperation.logSession => _logSessionMessage(error, statusCode, racquet),
    BagOperation.saveSessionOffline => _saveOfflineFailedMessage,
    BagOperation.restringRacquet => restringFailureMessage(name),
  };
}

String _logSessionMessage(Object error, int? statusCode, Racquet? racquet) {
  if (statusCode == 400 && racquet != null && racquet.activeStringJob == null) {
    return _unstrungMessage(racquet.name);
  }
  if (statusCode == 409) return _duplicateWorkoutMessage;
  if (isPermanentSessionRejection(error)) return _logRejectedMessage;
  return "Couldn't log this session.$_connectionHint";
}
