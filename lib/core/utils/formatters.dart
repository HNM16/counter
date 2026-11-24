import 'package:intl/intl.dart';

abstract final class Formatters {
  static final _grouped = NumberFormat.decimalPattern('en_US');

  /// `12,345`
  static String count(int value) => _grouped.format(value);

  /// `950`, `1.2k`, `12k`, `1.4M`
  static String compact(int value) {
    if (value < 1000) return '$value';
    if (value < 10000) return '${_trim(value / 1000)}k';
    if (value < 1000000) return '${(value / 1000).round()}k';
    return '${_trim(value / 1000000)}M';
  }

  static String _trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  /// Clock style used on the live counter: `4:07` or `1:04:07`.
  static String clock(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
    return '$m:$ss';
  }

  /// Human style used in history and records: `45s`, `12m`, `1h 05m`.
  static String duration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) {
      final s = d.inSeconds.remainder(60);
      return s == 0 || d.inMinutes >= 10 ? '${d.inMinutes}m' : '${d.inMinutes}m ${s}s';
    }
    return '${d.inHours}h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}m';
  }

  static String time(DateTime t) => DateFormat.jm().format(t);

  static String dayMonth(DateTime t) => DateFormat('d MMM').format(t);

  static String longDate(DateTime t) => DateFormat('EEEE, d MMMM').format(t);

  static String fullDate(DateTime t) => DateFormat('d MMMM yyyy').format(t);

  static String weekdayShort(DateTime t) => DateFormat('EEE').format(t);

  static String weekdayNarrow(DateTime t) => DateFormat('EEEEE').format(t);

  static String monthShort(DateTime t) => DateFormat('MMM').format(t);

  static String timeOfDay(int hour, int minute) => DateFormat.jm().format(DateTime(2000, 1, 1, hour, minute));

  /// "Today", "Yesterday", or a date.
  static String relativeDay(DateTime t, DateTime now) {
    final a = DateTime(t.year, t.month, t.day);
    final b = DateTime(now.year, now.month, now.day);
    final diff = b.difference(a).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(t);
    if (t.year == now.year) return DateFormat('EEEE, d MMMM').format(t);
    return DateFormat('d MMMM yyyy').format(t);
  }

  static String plural(int n, String singular, [String? pluralForm]) =>
      n == 1 ? '$n $singular' : '${count(n)} ${pluralForm ?? '${singular}s'}';
}
