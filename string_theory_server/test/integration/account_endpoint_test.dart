import 'package:serverpod_auth_idp_server/core.dart' show AuthUser;
import 'package:serverpod_auth_idp_server/providers/email.dart'
    show EmailAccount;
import 'package:serverpod_test/serverpod_test_public_exports.dart'
    as serverpod_test;
import 'package:test/test.dart';

import 'support/test_tenants.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given AccountEndpoint.getAccountEmail', (
    sessionBuilder,
    endpoints,
  ) {
    const email = 'judge@example.com';

    setUp(() async {
      final session = sessionBuilder.build();
      // Tenant f has an email account; tenant g is an anonymous guest.
      await AuthUser.db.insert(session, [
        AuthUser(id: TestTenants.fUserId, scopeNames: {}),
        AuthUser(id: TestTenants.gUserId, scopeNames: {}),
      ]);
      await EmailAccount.db.insertRow(
        session,
        EmailAccount(
          authUserId: TestTenants.fUserId,
          email: email,
          passwordHash: 'not-a-real-hash',
        ),
      );
    });

    test('returns the email of an email-account user', () async {
      final result = await endpoints.account.getAccountEmail(
        sessionBuilder.copyWith(
          authentication: TestTenants.auth(TestTenants.f),
        ),
      );

      expect(result, email);
    });

    test('returns null for a guest without an email account', () async {
      final result = await endpoints.account.getAccountEmail(
        sessionBuilder.copyWith(
          authentication: TestTenants.auth(TestTenants.g),
        ),
      );

      expect(result, isNull);
    });

    test('rejects an unauthenticated caller', () async {
      await expectLater(
        endpoints.account.getAccountEmail(
          sessionBuilder.copyWith(
            authentication:
                serverpod_test.AuthenticationOverride.unauthenticated(),
          ),
        ),
        throwsA(isA<serverpod_test.ServerpodUnauthenticatedException>()),
      );
    });
  });
}
