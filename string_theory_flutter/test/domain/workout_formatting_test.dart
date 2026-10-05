import 'package:flutter_test/flutter_test.dart';
import 'package:string_theory_flutter/domain/workout_formatting.dart';

void main() {
  group('formatWorkoutDuration', () {
    test('formats hours and minutes', () {
      expect(formatWorkoutDuration(90), '1h 30m');
    });

    test('omits minutes on whole hours', () {
      expect(formatWorkoutDuration(120), '2h');
    });

    test('omits hours under one hour', () {
      expect(formatWorkoutDuration(45), '45m');
    });
  });

  group('formatWorkoutStartTime', () {
    final now = DateTime(2026, 10, 5, 18, 0);

    test('prefixes Today for a start on the same local date', () {
      expect(
        formatWorkoutStartTime(DateTime(2026, 10, 5, 15, 5), now: now),
        'Today, 3:05 PM',
      );
    });

    test('uses month and day for another date', () {
      expect(
        formatWorkoutStartTime(DateTime(2026, 3, 4, 15, 5), now: now),
        'Mar 4, 3:05 PM',
      );
    });

    test('renders midnight as 12 AM', () {
      expect(
        formatWorkoutStartTime(DateTime(2026, 10, 5, 0, 7), now: now),
        'Today, 12:07 AM',
      );
    });

    test('renders noon as 12 PM', () {
      expect(
        formatWorkoutStartTime(DateTime(2026, 10, 5, 12, 0), now: now),
        'Today, 12:00 PM',
      );
    });
  });
}
