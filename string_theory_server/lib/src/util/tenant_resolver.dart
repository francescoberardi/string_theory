import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Resolves the authenticated user's ID as an integer.
/// Throws [BagException] with status 401 if unauthenticated.
int resolveUserId(Session session) {
  final authInfo = session.authenticated;
  if (authInfo == null) {
    throw BagException(
      message: 'User is not authenticated',
      statusCode: 401,
    );
  }
  final parsed = int.tryParse(authInfo.userIdentifier);
  if (parsed != null) {
    return parsed;
  }

  // Deterministic resolution for UUID userIdentifier strings across server restarts
  final cleanHex = authInfo.userIdentifier.replaceAll('-', '');
  final bigIntVal = BigInt.tryParse(cleanHex, radix: 16);
  if (bigIntVal != null) {
    return (bigIntVal.remainder(BigInt.from(0x7FFFFFFFFFFFFFFF))).toInt();
  }

  // Deterministic 64-bit FNV-1a hash fallback for non-UUID strings
  var hash = BigInt.parse('0xcbf29ce484222325');
  final prime = BigInt.parse('0x100000001b3');
  for (final byte in authInfo.userIdentifier.codeUnits) {
    hash = (hash ^ BigInt.from(byte)) * prime;
  }
  return (hash.remainder(BigInt.from(0x7FFFFFFFFFFFFFFF))).abs().toInt();
}
