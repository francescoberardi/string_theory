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
  return resolveUserIdFromIdentifier(authInfo.userIdentifier);
}

/// Maps an auth `userIdentifier` string to the integer tenant `userId`.
///
/// Every tenant-scoped row is keyed by this value, so the mapping must stay
/// stable, quirks included:
/// - Anything [int.tryParse] accepts passes through, including negative
///   values, surrounding whitespace, a `+` sign and `0x` hex.
/// - Otherwise, after stripping every `-`, any case-insensitive hex string
///   (UUIDs, but also `cafe` or decimal digits past int64) is reduced modulo
///   int64 max.
/// - Anything else is hashed over its UTF-16 code units.
///
/// The numeric and hex ranges overlap (`'3'` and the all-`f` UUID both map
/// to 3). Serverpod auth issues UUIDs, so numeric identifiers only occur in
/// tests.
int resolveUserIdFromIdentifier(String userIdentifier) {
  final parsed = int.tryParse(userIdentifier);
  if (parsed != null) {
    return parsed;
  }

  // Hex strings, including UUIDs
  final cleanHex = userIdentifier.replaceAll('-', '');
  final bigIntVal = BigInt.tryParse(cleanHex, radix: 16);
  if (bigIntVal != null) {
    return (bigIntVal.remainder(BigInt.from(0x7FFFFFFFFFFFFFFF))).toInt();
  }

  // Deterministic FNV-1a-style hash fallback for non-UUID strings. The BigInt
  // product is never masked to 64 bits, so this is not standard FNV-1a-64;
  // keep it as is, since changing it would re-key existing tenants.
  var hash = BigInt.parse('0xcbf29ce484222325');
  final prime = BigInt.parse('0x100000001b3');
  for (final codeUnit in userIdentifier.codeUnits) {
    hash = (hash ^ BigInt.from(codeUnit)) * prime;
  }
  return (hash.remainder(BigInt.from(0x7FFFFFFFFFFFFFFF))).abs().toInt();
}
