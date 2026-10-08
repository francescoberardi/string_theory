import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart'
    show AuthenticationInfoAuthUserId;

import '../generated/protocol.dart';

/// Resolves the authenticated user's tenant ID: their auth user UUID.
///
/// Throws a 401 [BagException] if the session is unauthenticated or its
/// identifier is not a UUID.
UuidValue resolveUserId(Session session) {
  final authInfo = session.authenticated;
  if (authInfo == null) {
    throw BagException(
      message: 'User is not authenticated',
      statusCode: 401,
    );
  }
  try {
    return authInfo.authUserId;
  } on FormatException {
    throw BagException(
      message: 'User identifier is not a valid UUID',
      statusCode: 401,
    );
  }
}
