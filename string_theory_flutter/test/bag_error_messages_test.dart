import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_error_messages.dart';

void main() {
  final strung = Racquet(
    id: 1,
    userId: Namespace.nil.uuidValue,
    name: 'Wilson Blade 98',
    isPrimary: true,
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: DateTime.utc(2026, 10, 1),
    activeStringJob: StringJob(
      userId: Namespace.nil.uuidValue,
      racquetId: 1,
      brand: 'Luxilon',
      model: 'ALU Power',
      materialCategory: StringMaterialCategory.coPoly,
      installedTension: 52.0,
      maxRatedHours: 20.0,
      stringingDate: DateTime.utc(2026, 10, 1),
      totalCourtHours: 0.0,
      currentHealthScore: 100,
      isActive: true,
    ),
  );
  final unstrung = Racquet(
    id: 2,
    userId: Namespace.nil.uuidValue,
    name: 'Head Radical MP',
    isPrimary: false,
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: DateTime.utc(2026, 10, 1),
  );

  BagException bag(int statusCode) => BagException(
    message: 'server says something internal',
    statusCode: statusCode,
  );

  /// Errors carrying no recognised status code: each must get the
  /// operation's connection fallback.
  final networkErrors = <String, Object>{
    'plain Exception': Exception('socket closed'),
    'network exception': const ServerpodClientNetworkException('offline'),
    'timeout': TimeoutException('no response'),
    'BagException 500': bag(500),
    'HTTP 500': ServerpodClientInternalServerError(),
    'HTTP 503': ServerpodClientUnknownHttpException('down', 503),
  };

  const connection = ' Check your connection and try again.';
  const goneMessage = 'That racquet is no longer in your bag.';
  const expiredMessage =
      'Your session expired. Restart the app to sign in again.';

  /// Asserts [message] leaks none of the raw error details.
  void expectClean(String message) {
    for (final leak in [
      'Exception',
      'statusCode',
      'server says',
      'socket closed',
      'offline',
      'no response',
      'Unknown error',
    ]) {
      expect(message, isNot(contains(leak)));
    }
  }

  group('bagErrorMessage', () {
    group('connection fallbacks', () {
      final fallbacks = <BagOperation, (Racquet?, String?, String)>{
        BagOperation.loadBag: (
          null,
          null,
          "Couldn't load your bag.$connection",
        ),
        BagOperation.addRacquet: (
          null,
          'Yonex Ezone',
          "Couldn't add \"Yonex Ezone\".$connection",
        ),
        BagOperation.deleteRacquet: (
          strung,
          null,
          "Couldn't remove this racquet.$connection",
        ),
        BagOperation.setPrimaryRacquet: (
          strung,
          null,
          "Couldn't set your primary racquet.$connection",
        ),
        BagOperation.fastForwardRacquetAge: (
          strung,
          null,
          "Couldn't fast-forward this racquet.$connection",
        ),
        BagOperation.seedSampleBag: (
          null,
          null,
          "Couldn't load the sample bag.$connection",
        ),
        BagOperation.restringRacquet: (
          strung,
          null,
          restringFailureMessage('Wilson Blade 98'),
        ),
      };

      for (final MapEntry(key: op, value: (racquet, name, expected))
          in fallbacks.entries) {
        for (final MapEntry(key: label, value: error)
            in networkErrors.entries) {
          test('$op with $label', () {
            final message = bagErrorMessage(
              op,
              error,
              racquet: racquet,
              racquetName: name,
            );
            expect(message, expected);
            expectClean(message);
          });
        }
      }
    });

    test('restring fallback keeps the existing copy', () {
      expect(
        restringFailureMessage('Wilson Blade 98'),
        'Could not restring "Wilson Blade 98". '
        'Check your connection and try again.',
      );
    });

    test('load bag maps any non-401 error to its fallback', () {
      for (final error in [bag(400), bag(404), ServerpodClientNotFound()]) {
        expect(
          bagErrorMessage(BagOperation.loadBag, error),
          "Couldn't load your bag.$connection",
        );
      }
    });

    test('seed sample bag maps any non-401 error to its fallback', () {
      for (final error in [bag(400), bag(404), ServerpodClientBadRequest()]) {
        expect(
          bagErrorMessage(BagOperation.seedSampleBag, error),
          "Couldn't load the sample bag.$connection",
        );
      }
    });

    group('add racquet rejected (400)', () {
      for (final error in [bag(400), ServerpodClientBadRequest('bad')]) {
        test('${error.runtimeType}', () {
          final message = bagErrorMessage(
            BagOperation.addRacquet,
            error,
            racquetName: 'Yonex Ezone',
          );
          expect(
            message,
            "Couldn't add \"Yonex Ezone\". "
            'Check the racquet details and try again.',
          );
          expectClean(message);
        });
      }
    });

    group('racquet-targeted 404', () {
      for (final op in [
        BagOperation.deleteRacquet,
        BagOperation.setPrimaryRacquet,
        BagOperation.fastForwardRacquetAge,
        BagOperation.logSession,
        BagOperation.restringRacquet,
      ]) {
        for (final error in [bag(404), ServerpodClientNotFound()]) {
          test('$op with ${error.runtimeType}', () {
            expect(
              bagErrorMessage(op, error, racquet: strung),
              goneMessage,
            );
          });
        }
      }
    });

    group('log session', () {
      test('400 on an unstrung racquet', () {
        for (final error in [bag(400), ServerpodClientBadRequest('x')]) {
          final message = bagErrorMessage(
            BagOperation.logSession,
            error,
            racquet: unstrung,
          );
          expect(
            message,
            '"Head Radical MP" has no strings mounted. '
            'Restring it before logging a session.',
          );
          expectClean(message);
        }
      });

      test('400 on a strung racquet is another permanent rejection', () {
        expect(
          bagErrorMessage(BagOperation.logSession, bag(400), racquet: strung),
          "Couldn't log this session. Please try again.",
        );
      });

      test('400 with an unknown racquet is another permanent rejection', () {
        expect(
          bagErrorMessage(BagOperation.logSession, bag(400)),
          "Couldn't log this session. Please try again.",
        );
      });

      test('409 duplicate workout', () {
        for (final error in [
          bag(409),
          ServerpodClientUnknownHttpException('dup', 409),
        ]) {
          expect(
            bagErrorMessage(BagOperation.logSession, error, racquet: strung),
            'This workout is already logged on another account.',
          );
        }
      });

      test('other permanent 4xx rejections', () {
        for (final error in [
          bag(403),
          ServerpodClientForbidden(),
          bag(422),
        ]) {
          expect(
            bagErrorMessage(BagOperation.logSession, error, racquet: strung),
            "Couldn't log this session. Please try again.",
          );
        }
      });

      test('non-HTTP errors get the connection fallback', () {
        for (final error in networkErrors.values) {
          expect(
            bagErrorMessage(BagOperation.logSession, error, racquet: strung),
            "Couldn't log this session.$connection",
          );
        }
      });
    });

    test('offline enqueue failure', () {
      for (final error in [
        Exception('disk full'),
        StateError('prefs unavailable'),
      ]) {
        final message = bagErrorMessage(
          BagOperation.saveSessionOffline,
          error,
          racquet: strung,
        );
        expect(message, "Couldn't save this session. Please try again.");
        expect(message, isNot(contains('disk full')));
      }
    });

    group('401 on any operation', () {
      for (final op in BagOperation.values) {
        for (final error in [bag(401), ServerpodClientUnauthorized()]) {
          test('$op with ${error.runtimeType}', () {
            expect(
              bagErrorMessage(
                op,
                error,
                racquet: strung,
                racquetName: 'Yonex Ezone',
              ),
              expiredMessage,
            );
          });
        }
      }
    });
  });
}
