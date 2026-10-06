import 'package:serverpod_test/serverpod_test_public_exports.dart'
    as serverpod_test;
import 'package:string_theory_server/src/generated/protocol.dart';
import 'package:string_theory_server/src/util/tenant_resolver.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given resolveUserId on a Session', (sessionBuilder, _) {
    test(
      'should throw a 401 BagException when the session is unauthenticated',
      () {
        final session = sessionBuilder
            .copyWith(
              authentication:
                  serverpod_test.AuthenticationOverride.unauthenticated(),
            )
            .build();

        expect(
          () => resolveUserId(session),
          throwsA(
            isA<BagException>().having((e) => e.statusCode, 'statusCode', 401),
          ),
        );
      },
    );

    test(
      'should resolve the authenticated UUID identifier to its golden value',
      () {
        const uuid = '550e8400-e29b-41d4-a716-446655440000';
        final session = sessionBuilder
            .copyWith(
              authentication:
                  serverpod_test.AuthenticationOverride.authenticationInfo(
                    uuid,
                    {},
                  ),
            )
            .build();

        expect(resolveUserId(session), 5851104350888952746);
      },
    );
  });
}
