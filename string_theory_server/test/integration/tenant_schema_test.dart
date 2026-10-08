import 'package:string_theory_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'support/test_tenants.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given the UUID tenant schema (Story 6.3)', (
    sessionBuilder,
    endpoints,
  ) {
    final tenantA = sessionBuilder.copyWith(
      authentication: TestTenants.auth(TestTenants.a),
    );
    final tenantB = sessionBuilder.copyWith(
      authentication: TestTenants.auth(TestTenants.b),
    );

    test(
      '[P0] AC-1 should type userId as uuid on all four tenant tables',
      () async {
        final session = sessionBuilder.build();

        final rows = await session.db.unsafeQuery(
          "SELECT table_name, data_type FROM information_schema.columns "
          "WHERE table_schema = 'public' AND column_name = 'userId' "
          "AND table_name IN "
          "('racquet', 'string_job', 'session_log', 'restring_event');",
        );
        final types = {
          for (final row in rows) row[0] as String: row[1] as String,
        };

        expect(
          types,
          equals({
            'racquet': 'uuid',
            'string_job': 'uuid',
            'session_log': 'uuid',
            'restring_event': 'uuid',
          }),
        );
      },
      skip: tddRedPhaseReason,
    );

    test(
      '[P1] AC-2 should accept the same externalWorkoutId for two tenants',
      () async {
        const sharedWorkoutId = 'hk-shared-workout-6-3';
        final racquetA = await endpoints.bag.createRacquet(
          tenantA,
          racquetName: 'Wilson Blade 98',
        );
        final racquetB = await endpoints.bag.createRacquet(
          tenantB,
          racquetName: 'Babolat Pure Aero',
        );
        await endpoints.session.logSession(
          tenantA,
          sessionLogFor(racquetA.id!, externalWorkoutId: sharedWorkoutId),
        );

        await expectLater(
          endpoints.session.logSession(
            tenantB,
            sessionLogFor(racquetB.id!, externalWorkoutId: sharedWorkoutId),
          ),
          completion(
            isA<SessionLog>().having(
              (log) => log.racquetId,
              'racquetId',
              racquetB.id,
            ),
          ),
        );
      },
      skip: tddRedPhaseReason,
    );
  });
}
