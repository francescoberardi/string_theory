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
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}
