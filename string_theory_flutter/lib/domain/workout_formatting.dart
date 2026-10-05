/// Formats a workout duration as e.g. `1h 30m`, `2h` or `45m`.
String formatWorkoutDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '${rest}m';
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest}m';
}

/// Formats a workout start as `Today, 3:05 PM` or `Mar 4, 3:05 PM` in local
/// time. [now] defaults to the current time.
String formatWorkoutStartTime(DateTime dt, {DateTime? now}) {
  final local = dt.toLocal();
  final reference = now ?? DateTime.now();
  final isToday =
      local.year == reference.year &&
      local.month == reference.month &&
      local.day == reference.day;
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  final timeStr = '$hour:$minute $period';

  if (isToday) {
    return 'Today, $timeStr';
  } else {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, $timeStr';
  }
}
