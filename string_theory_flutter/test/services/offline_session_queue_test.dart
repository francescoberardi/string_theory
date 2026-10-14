import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/services/offline_session_queue.dart';

SessionLog _log({
  int racquetId = 1,
  int durationMinutes = 60,
  String? externalWorkoutId,
  String source = 'manual',
}) {
  return SessionLog(
    userId: Namespace.nil.uuidValue,
    racquetId: racquetId,
    startTime: DateTime.utc(2026, 10, 4, 17, 0),
    durationMinutes: durationMinutes,
    courtSurface: 'Clay',
    notes: 'Offline match',
    source: source,
    externalWorkoutId: externalWorkoutId,
    createdAt: DateTime.utc(2026, 10, 4, 18, 0),
  );
}

void main() {
  final fixedNow = DateTime.utc(2026, 10, 4, 18, 30);

  group('OfflineSessionQueue enqueue', () {
    test('starts empty and reports pending count after enqueue', () async {
      final queue = OfflineSessionQueue(
        storage: InMemorySessionQueueStorage(),
        now: () => fixedNow,
      );
      await queue.load();
      expect(queue.pendingCount, 0);

      await queue.enqueue(_log(externalWorkoutId: 'hk-1'));

      expect(queue.pendingCount, 1);
      expect(queue.pending.single.externalWorkoutId, 'hk-1');
    });

    test('preserves an existing externalWorkoutId', () async {
      final queue = OfflineSessionQueue(storage: InMemorySessionQueueStorage());

      final queued = await queue.enqueue(_log(externalWorkoutId: 'hk-42'));

      expect(queued.externalWorkoutId, 'hk-42');
    });

    test('generates a client idempotency key when none is provided', () async {
      final queue = OfflineSessionQueue(
        storage: InMemorySessionQueueStorage(),
        now: () => fixedNow,
      );

      final queued = await queue.enqueue(_log(racquetId: 7));

      expect(
        queued.externalWorkoutId,
        'client_offline_${fixedNow.microsecondsSinceEpoch}_7',
      );
    });

    test('treats a blank externalWorkoutId as missing', () async {
      final queue = OfflineSessionQueue(
        storage: InMemorySessionQueueStorage(),
        now: () => fixedNow,
      );

      final queued = await queue.enqueue(_log(externalWorkoutId: '  '));

      expect(queued.externalWorkoutId, startsWith('client_offline_'));
    });

    test(
      'generates unique keys for sessions enqueued at the same instant',
      () async {
        final queue = OfflineSessionQueue(
          storage: InMemorySessionQueueStorage(),
          now: () => fixedNow,
        );

        final first = await queue.enqueue(_log());
        final second = await queue.enqueue(_log());

        expect(first.externalWorkoutId, isNot(second.externalWorkoutId));
        expect(queue.pendingCount, 2);
      },
    );

    test('deduplicates sessions with the same externalWorkoutId', () async {
      final queue = OfflineSessionQueue(storage: InMemorySessionQueueStorage());

      await queue.enqueue(_log(externalWorkoutId: 'hk-1'));
      await queue.enqueue(_log(externalWorkoutId: 'hk-1'));

      expect(queue.pendingCount, 1);
    });
  });

  group('OfflineSessionQueue persistence', () {
    test('round-trips queued sessions through storage', () async {
      final storage = InMemorySessionQueueStorage();
      final writer = OfflineSessionQueue(storage: storage);
      await writer.enqueue(_log(externalWorkoutId: 'hk-1'));
      await writer.enqueue(_log(racquetId: 2, externalWorkoutId: 'hk-2'));

      final reader = OfflineSessionQueue(storage: storage);
      await reader.load();

      expect(reader.pendingCount, 2);
      final restored = reader.pending.first;
      expect(restored.racquetId, 1);
      expect(restored.durationMinutes, 60);
      expect(restored.courtSurface, 'Clay');
      expect(restored.notes, 'Offline match');
      expect(restored.source, 'manual');
      expect(restored.externalWorkoutId, 'hk-1');
      expect(restored.startTime, DateTime.utc(2026, 10, 4, 17, 0));
      expect(reader.pending.last.externalWorkoutId, 'hk-2');
    });

    test('skips corrupt stored entries instead of failing the load', () async {
      final storage = InMemorySessionQueueStorage([
        'not json',
        jsonEncode(_log(externalWorkoutId: 'hk-ok').toJson()),
        jsonEncode({'unexpected': true}),
      ]);
      final queue = OfflineSessionQueue(storage: storage);

      await queue.load();

      expect(queue.pendingCount, 1);
      expect(queue.pending.single.externalWorkoutId, 'hk-ok');
    });

    test('SharedPreferences storage persists across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final writer = OfflineSessionQueue(
        storage: SharedPreferencesSessionQueueStorage(),
      );
      await writer.enqueue(_log(externalWorkoutId: 'hk-persist'));

      final reader = OfflineSessionQueue(
        storage: SharedPreferencesSessionQueueStorage(),
      );
      await reader.load();

      expect(reader.pending.single.externalWorkoutId, 'hk-persist');
    });
  });

  group('OfflineSessionQueue sync', () {
    test('posts queued sessions in order and drains the queue', () async {
      final storage = InMemorySessionQueueStorage();
      final queue = OfflineSessionQueue(storage: storage);
      await queue.enqueue(_log(externalWorkoutId: 'hk-1'));
      await queue.enqueue(_log(externalWorkoutId: 'hk-2'));
      final sent = <String?>[];

      final result = await queue.sync((log) async {
        sent.add(log.externalWorkoutId);
        return log;
      });

      expect(sent, ['hk-1', 'hk-2']);
      expect(result.synced, 2);
      expect(result.discarded, 0);
      expect(result.remaining, 0);
      expect(queue.pendingCount, 0);
      expect(await storage.read(), isEmpty);
    });

    test('keeps unsent sessions when connectivity drops mid-sync', () async {
      final storage = InMemorySessionQueueStorage();
      final queue = OfflineSessionQueue(storage: storage);
      await queue.enqueue(_log(externalWorkoutId: 'hk-1'));
      await queue.enqueue(_log(externalWorkoutId: 'hk-2'));
      await queue.enqueue(_log(externalWorkoutId: 'hk-3'));
      var calls = 0;

      final result = await queue.sync((log) async {
        calls++;
        if (calls == 2) {
          throw const ServerpodClientNetworkException('connection lost');
        }
        return log;
      });

      expect(calls, 2);
      expect(result.synced, 1);
      expect(result.remaining, 2);
      expect(result.interrupted, isTrue);
      expect(queue.pending.map((l) => l.externalWorkoutId), ['hk-2', 'hk-3']);

      final reloaded = OfflineSessionQueue(storage: storage);
      await reloaded.load();
      expect(reloaded.pendingCount, 2);
    });

    test(
      're-sending an already-accepted session removes it (idempotent)',
      () async {
        final queue = OfflineSessionQueue(
          storage: InMemorySessionQueueStorage(),
        );
        await queue.enqueue(_log(externalWorkoutId: 'hk-dup'));
        final serverRows = <String>{};

        // First pulse: server accepts, but the response never arrives.
        await queue.sync((log) async {
          serverRows.add(log.externalWorkoutId!);
          throw const ServerpodClientNetworkException('response lost');
        });
        expect(queue.pendingCount, 1);

        // Next pulse: server returns the existing row for the same key.
        final result = await queue.sync((log) async {
          serverRows.add(log.externalWorkoutId!);
          return log.copyWith(id: 99);
        });

        expect(result.synced, 1);
        expect(queue.pendingCount, 0);
        expect(serverRows, {'hk-dup'});
      },
    );

    test(
      'discards sessions the server rejects to avoid poisoning the queue',
      () async {
        final queue = OfflineSessionQueue(
          storage: InMemorySessionQueueStorage(),
        );
        await queue.enqueue(_log(externalWorkoutId: 'hk-bad'));
        await queue.enqueue(_log(externalWorkoutId: 'hk-good'));
        final sent = <String?>[];

        final result = await queue.sync((log) async {
          sent.add(log.externalWorkoutId);
          if (log.externalWorkoutId == 'hk-bad') {
            throw BagException(
              message: 'Duration must be greater than zero',
              statusCode: 400,
            );
          }
          return log;
        });

        expect(sent, ['hk-bad', 'hk-good']);
        expect(result.synced, 1);
        expect(result.discarded, 1);
        expect(queue.pendingCount, 0);
      },
    );

    test('discards sessions rejected with a client HTTP error', () async {
      final queue = OfflineSessionQueue(storage: InMemorySessionQueueStorage());
      await queue.enqueue(_log(externalWorkoutId: 'hk-bad'));

      final result = await queue.sync(
        (log) async => throw ServerpodClientBadRequest('invalid'),
      );

      expect(result.discarded, 1);
      expect(queue.pendingCount, 0);
    });

    test(
      'keeps sessions when the server reports a transient failure',
      () async {
        final queue = OfflineSessionQueue(
          storage: InMemorySessionQueueStorage(),
        );
        await queue.enqueue(_log(externalWorkoutId: 'hk-1'));

        final result = await queue.sync(
          (log) async => throw ServerpodClientUnauthorized(),
        );

        expect(result.synced, 0);
        expect(result.interrupted, isTrue);
        expect(queue.pendingCount, 1);
      },
    );

    test('concurrent sync calls share a single drain', () async {
      final queue = OfflineSessionQueue(storage: InMemorySessionQueueStorage());
      await queue.enqueue(_log(externalWorkoutId: 'hk-1'));
      final gate = Completer<void>();
      var calls = 0;

      Future<SessionLog> send(SessionLog log) async {
        calls++;
        await gate.future;
        return log;
      }

      final first = queue.sync(send);
      final second = queue.sync(send);
      gate.complete();

      expect((await first).synced, 1);
      expect((await second).synced, 1);
      expect(calls, 1);
    });
  });

  group('OfflineSessionQueue clear', () {
    test('drops every queued session from memory and storage', () async {
      final storage = InMemorySessionQueueStorage();
      final queue = OfflineSessionQueue(storage: storage);
      await queue.enqueue(_log(externalWorkoutId: 'hk-1'));
      await queue.enqueue(_log(externalWorkoutId: 'hk-2'));

      await queue.clear();

      expect(queue.pendingCount, 0);
      expect(await storage.read(), isEmpty);
    });

    test('clears stored sessions that were never loaded', () async {
      final storage = InMemorySessionQueueStorage([
        jsonEncode(_log(externalWorkoutId: 'hk-1').toJson()),
      ]);
      final queue = OfflineSessionQueue(storage: storage);

      await queue.clear();
      await queue.load();

      expect(queue.pendingCount, 0);
      expect(await storage.read(), isEmpty);
    });

    test('accepts new sessions after a clear', () async {
      final queue = OfflineSessionQueue(storage: InMemorySessionQueueStorage());
      await queue.enqueue(_log(externalWorkoutId: 'hk-1'));

      await queue.clear();
      await queue.enqueue(_log(externalWorkoutId: 'hk-2'));

      expect(queue.pending.single.externalWorkoutId, 'hk-2');
    });

    test(
      'stops a drain in flight: no queued session is sent after a clear',
      () async {
        final storage = InMemorySessionQueueStorage();
        final queue = OfflineSessionQueue(storage: storage);
        await queue.enqueue(_log(externalWorkoutId: 'hk-1'));
        await queue.enqueue(_log(externalWorkoutId: 'hk-2'));
        final firstSend = Completer<void>();
        final sent = <String?>[];

        final sync = queue.sync((log) async {
          sent.add(log.externalWorkoutId);
          if (sent.length == 1) await firstSend.future;
          return log;
        });
        await pumpEventQueue();
        await queue.clear();
        firstSend.complete();
        await sync;

        expect(sent, ['hk-1']);
        expect(queue.pendingCount, 0);
        expect(await storage.read(), isEmpty);
      },
    );
  });

  group('isPermanentSessionRejection', () {
    test('classifies server rejections and transient failures', () {
      expect(
        isPermanentSessionRejection(
          BagException(message: 'not found', statusCode: 404),
        ),
        isTrue,
      );
      expect(
        isPermanentSessionRejection(
          BagException(message: 'conflict', statusCode: 409),
        ),
        isTrue,
      );
      expect(isPermanentSessionRejection(ServerpodClientNotFound()), isTrue);
      expect(
        isPermanentSessionRejection(
          const ServerpodClientNetworkException('offline'),
        ),
        isFalse,
      );
      expect(
        isPermanentSessionRejection(ServerpodClientUnauthorized()),
        isFalse,
      );
      expect(isPermanentSessionRejection(TimeoutException('slow')), isFalse);
      expect(isPermanentSessionRejection(Exception('RPC timeout')), isFalse);
    });
  });
}
