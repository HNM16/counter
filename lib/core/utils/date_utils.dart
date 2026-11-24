/// Calendar helpers. All day keys use the device's local time zone so that
/// "today" matches what the user sees on their clock.
abstract final class DayKey {
  /// Formats [date] as `YYYY-MM-DD` (local date).
  static String of(DateTime date) {
    final d = date.toLocal();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Parses a `YYYY-MM-DD` key back to a local midnight [DateTime].
  static DateTime parse(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}

extension DateTimeDays on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  /// Calendar-safe day arithmetic (immune to DST shifts).
  DateTime addDays(int days) => DateTime(year, month, day + days);

  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;

  /// Monday-based start of the week containing this date.
  DateTime get startOfWeek => startOfDay.addDays(-(weekday - DateTime.monday));

  DateTime get startOfMonth => DateTime(year, month);
}
