import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart'
    show EmailAccount;

import '../util/tenant_resolver.dart';

/// Account details for the signed-in user.
class AccountEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// The email address of the signed-in user's email account, or null when
  /// the user has none (an anonymous guest).
  Future<String?> getAccountEmail(Session session) async {
    final authUserId = resolveUserId(session);
    final account = await EmailAccount.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId),
    );
    return account?.email;
  }
}
