import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:string_theory_client/string_theory_client.dart';

/// Persists the raw, JSON-encoded entries of the [OfflineSessionQueue].
///
/// Each entry is stored separately so one corrupt record never prevents the
/// rest of the queue from loading.
abstract class SessionQueueStorage {
  /// Returns the stored entries in queue order (empty if none).
  Future<List<String>> read();

  /// Replaces the stored entries with [entries].
  Future<void> write(List<String> entries);
}

/// Volatile [SessionQueueStorage] for tests and as a safe default.
class InMemorySessionQueueStorage implements SessionQueueStorage {
  List<String> _entries;

  InMemorySessionQueueStorage([List<String>? entries])
    : _entries = List.of(entries ?? const <String>[]);

  @override
  Future<List<String>> read() async => List.of(_entries);

  @override
  Future<void> write(List<String> entries) async {
    _entries = List.of(entries);
  }
}

/// [SessionQueueStorage] backed by [SharedPreferences], so queued sessions
/// survive app restarts and kills.
class SharedPreferencesSessionQueueStorage implements SessionQueueStorage {
  static const defaultKey = 'offline_session_queue_v1';

  final String key;

  SharedPreferencesSessionQueueStorage({this.key = defaultKey});

  @override
  Future<List<String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? const <String>[];
  }

  @override
  Future<void> write(List<String> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, entries);
  }
}

/// Outcome of one [OfflineSessionQueue.sync] drain.
@immutable
class SessionSyncResult {
  /// Sessions the server accepted (including idempotent duplicates).
  final int synced;

  /// Sessions the server permanently rejected and that were dropped.
  final int discarded;

  /// Sessions still queued after the drain.
  final int remaining;

  /// Whether the drain stopped early on a transient (network) failure.
  final bool interrupted;

  const SessionSyncResult({
    required this.synced,
    required this.discarded,
    required this.remaining,
    required this.interrupted,
  });

  @override
  String toString() =>
      'SessionSyncResult(synced: $synced, discarded: $discarded, '
      'remaining: $remaining, interrupted: $interrupted)';
}

/// The HTTP status code carried by [error], or null when it has none (network
/// failures, timeouts and anything unknown).
int? statusCodeOf(Object error) => switch (error) {
  BagException(:final statusCode) => statusCode,
  ServerpodClientHttpException(:final statusCode) => statusCode,
  _ => null,
};

/// Whether [error] means the server rejected a session for good, so retrying
/// the same payload can never succeed.
///
/// Client errors (4xx) are permanent, except 401 (the guest session may be
/// re-provisioned), 408 and 429. Network failures, timeouts, server errors
/// and anything unknown are treated as transient.
bool isPermanentSessionRejection(Object error) {
  final statusCode = statusCodeOf(error);
  if (statusCode == null) return false;
  if (statusCode < 400 || statusCode >= 500) return false;
  return statusCode != 401 && statusCode != 408 && statusCode != 429;
}

/// Local, persistent queue of [SessionLog]s logged while offline.
///
/// Every queued session carries a unique `externalWorkoutId` so the server's
/// `session_log_external_id_idx` makes re-sending it idempotent.
class OfflineSessionQueue {
  final SessionQueueStorage storage;
  final DateTime Function() _now;

  List<SessionLog>? _items;
  Future<void>? _loading;
  Future<SessionSyncResult>? _syncInFlight;

  OfflineSessionQueue({required this.storage, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Queued sessions in send order. Empty until [load] completes.
  List<SessionLog> get pending => List.unmodifiable(_items ?? const []);

  /// Number of queued sessions. Zero until [load] completes.
  int get pendingCount => _items?.length ?? 0;

  /// Loads the queue from [storage]; later calls are no-ops.
  Future<void> load() {
    if (_items != null) return Future.value();
    return _loading ??= _readFromStorage().whenComplete(() => _loading = null);
  }

  Future<void> _readFromStorage() async {
    final entries = await storage.read();
    final items = <SessionLog>[];
    for (final entry in entries) {
      try {
        final decoded = jsonDecode(entry);
        items.add(SessionLog.fromJson(decoded as Map<String, dynamic>));
      } catch (e) {
        debugPrint('OfflineSessionQueue: skipping corrupt entry: $e');
      }
    }
    _items ??= items;
  }

  /// Adds [log] to the queue and persists it.
  ///
  /// Keeps a non-blank `externalWorkoutId`, otherwise assigns
  /// `client_offline_<microseconds>_<racquetId>`. A session whose key is
  /// already queued is not added twice. Returns the queued session.
  Future<SessionLog> enqueue(SessionLog log) async {
    await load();
    final items = _items!;

    final existingId = log.externalWorkoutId?.trim();
    if (existingId != null && existingId.isNotEmpty) {
      final duplicate = items
          .where((l) => l.externalWorkoutId == existingId)
          .firstOrNull;
      if (duplicate != null) return duplicate;
    }

    final queued = log.copyWith(
      externalWorkoutId: (existingId != null && existingId.isNotEmpty)
          ? existingId
          : _generateKey(log.racquetId, items),
    );
    items.add(queued);
    try {
      await _persist();
    } catch (_) {
      items.remove(queued);
      rethrow;
    }
    return queued;
  }

  String _generateKey(int racquetId, List<SessionLog> items) {
    final base = 'client_offline_${_now().microsecondsSinceEpoch}_$racquetId';
    final taken = items.map((l) => l.externalWorkoutId).toSet();
    var key = base;
    var suffix = 2;
    while (taken.contains(key)) {
      key = '${base}_${suffix++}';
    }
    return key;
  }

  /// Sends queued sessions one by one, in order, through [send].
  ///
  /// Accepted sessions (including idempotent duplicates) are removed; sessions
  /// the server permanently rejects are discarded; the first transient failure
  /// stops the drain and keeps the rest queued for the next attempt.
  /// Concurrent calls share the drain already in flight.
  Future<SessionSyncResult> sync(
    Future<SessionLog> Function(SessionLog log) send,
  ) {
    return _syncInFlight ??= _drain(
      send,
    ).whenComplete(() => _syncInFlight = null);
  }

  Future<SessionSyncResult> _drain(
    Future<SessionLog> Function(SessionLog log) send,
  ) async {
    await load();
    final items = _items!;
    var synced = 0;
    var discarded = 0;
    var interrupted = false;

    while (items.isNotEmpty) {
      final next = items.first;
      try {
        await send(next);
        synced++;
      } catch (e) {
        if (!isPermanentSessionRejection(e)) {
          debugPrint('OfflineSessionQueue: sync paused: $e');
          interrupted = true;
          break;
        }
        debugPrint(
          'OfflineSessionQueue: discarding rejected session '
          '${next.externalWorkoutId}: $e',
        );
        discarded++;
      }
      items.removeAt(0);
      try {
        await _persist();
      } catch (_) {
        items.insert(0, next);
        rethrow;
      }
    }

    return SessionSyncResult(
      synced: synced,
      discarded: discarded,
      remaining: items.length,
      interrupted: interrupted,
    );
  }

  Future<void> _persist() {
    final entries = _items!.map((l) => jsonEncode(l.toJson())).toList();
    return storage.write(entries);
  }
}
