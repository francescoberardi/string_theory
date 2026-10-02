import 'package:string_theory_server/server.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given AnonymousIdp endpoint',
    (sessionBuilder, endpoints) {
      setUpAll(() {
        final session = sessionBuilder.build();
        initializeAuthServices(session.serverpod);
      });

      test(
        'when calling `login` then returns valid AuthSuccess session',
        () async {
          final authSuccess = await endpoints.anonymousIdp.login(
            sessionBuilder,
          );

          expect(authSuccess.authUserId, isNotNull);
          expect(authSuccess.token, isNotEmpty);
        },
      );

      test(
        'when calling `login` multiple times then creates distinct anonymous user identities',
        () async {
          final first = await endpoints.anonymousIdp.login(sessionBuilder);
          final second = await endpoints.anonymousIdp.login(sessionBuilder);

          expect(first.authUserId, isNotNull);
          expect(second.authUserId, isNotNull);
          expect(first.authUserId, isNot(equals(second.authUserId)));
          expect(first.token, isNot(equals(second.token)));
        },
      );
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}
