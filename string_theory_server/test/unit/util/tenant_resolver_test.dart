import 'package:string_theory_server/src/util/tenant_resolver.dart';
import 'package:test/test.dart';

// Characterization tests: every tenant-scoped row is keyed by these outputs,
// so a changed value here means existing users lose access to their data.
// Golden values were captured from the mapping as of commit
// fdf1401 (before it was extracted from resolveUserId).
void main() {
  const int64Max = 0x7FFFFFFFFFFFFFFF;

  group('resolveUserIdFromIdentifier', () {
    group('numeric identifiers', () {
      test('should pass a plain integer identifier through unchanged', () {
        expect(resolveUserIdFromIdentifier('1'), 1);
        expect(resolveUserIdFromIdentifier('42'), 42);
      });

      test('should resolve zero to zero', () {
        expect(resolveUserIdFromIdentifier('0'), 0);
      });

      test('should pass a negative integer identifier through as negative', () {
        expect(resolveUserIdFromIdentifier('-5'), -5);
      });

      test('should pass the int64 minimum through unchanged', () {
        expect(
          resolveUserIdFromIdentifier('-9223372036854775808'),
          -9223372036854775808,
        );
      });

      test(
        'should map a negative digit string beyond int64 through the hex path',
        () {
          // The minus sign is stripped like a hyphen.
          expect(
            resolveUserIdFromIdentifier('-9223372036854775809'),
            3707029189907933773,
          );
        },
      );

      test('should pass the int64 maximum through unchanged', () {
        expect(resolveUserIdFromIdentifier('$int64Max'), int64Max);
      });

      test('should accept the forms int.tryParse accepts', () {
        expect(resolveUserIdFromIdentifier(' 5'), 5);
        expect(resolveUserIdFromIdentifier('+5'), 5);
        expect(resolveUserIdFromIdentifier('0x10'), 16);
      });

      test(
        'should map a digit string beyond int64 through the hex path',
        () {
          // int.tryParse overflows to null, and the digits are valid hex.
          final userId = resolveUserIdFromIdentifier('9223372036854775808');
          expect(userId, 3707029189907933772);
          expect(userId, inInclusiveRange(0, int64Max));
        },
      );
    });

    group('UUID identifiers', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';

      test('should map a UUID to its golden value', () {
        expect(resolveUserIdFromIdentifier(uuid), 5851104350888952746);
      });

      test('should ignore hyphens', () {
        expect(
          resolveUserIdFromIdentifier('550e8400e29b41d4a716446655440000'),
          resolveUserIdFromIdentifier(uuid),
        );
      });

      test('should map the all-zero UUID to zero', () {
        expect(
          resolveUserIdFromIdentifier('00000000-0000-0000-0000-000000000000'),
          0,
        );
      });

      test('should map the all-ones UUID to a non-negative value', () {
        final userId = resolveUserIdFromIdentifier(
          'ffffffff-ffff-ffff-ffff-ffffffffffff',
        );
        expect(userId, 3);
        expect(userId, inInclusiveRange(0, int64Max));
      });

      test('should treat any short hex-looking string as hex, not hash it', () {
        expect(resolveUserIdFromIdentifier('cafe'), 0xcafe);
      });

      test('should ignore hex case', () {
        expect(resolveUserIdFromIdentifier('CAFE'), 0xcafe);
        expect(
          resolveUserIdFromIdentifier('550E8400-E29B-41D4-A716-446655440000'),
          resolveUserIdFromIdentifier(uuid),
        );
      });

      test('should collide with the numeric path for small values', () {
        // Known overlap, harmless while auth identifiers are always UUIDs.
        expect(
          resolveUserIdFromIdentifier('ffffffff-ffff-ffff-ffff-ffffffffffff'),
          resolveUserIdFromIdentifier('3'),
        );
      });

      test('should map distinct UUIDs to distinct values', () {
        expect(
          resolveUserIdFromIdentifier('550e8400-e29b-41d4-a716-446655440001'),
          isNot(resolveUserIdFromIdentifier(uuid)),
        );
      });
    });

    group('non-hex identifiers (FNV-1a fallback)', () {
      test('should map identifiers to their golden values', () {
        expect(
          resolveUserIdFromIdentifier('alice@example.com'),
          8174540226388122313,
        );
        expect(
          resolveUserIdFromIdentifier('bob@example.com'),
          2248774747829726110,
        );
        expect(resolveUserIdFromIdentifier('guest'), 8112957777949343058);
      });

      test('should hash the empty identifier', () {
        expect(resolveUserIdFromIdentifier(''), 5472609002491880230);
      });

      test('should hash UTF-16 code units, not UTF-8 bytes', () {
        expect(resolveUserIdFromIdentifier('josé'), 5343732455055097843);
        // A surrogate pair.
        expect(resolveUserIdFromIdentifier('🎾'), 2283743397207434851);
      });

      test('should hash a hyphen-only identifier instead of throwing', () {
        expect(resolveUserIdFromIdentifier('---'), 1244373046031139481);
      });

      test('should always return a non-negative value', () {
        for (final identifier in [
          'alice@example.com',
          'bob@example.com',
          'guest',
          'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz',
        ]) {
          expect(
            resolveUserIdFromIdentifier(identifier),
            inInclusiveRange(0, int64Max),
            reason: identifier,
          );
        }
      });
    });
  });
}
