import 'package:flutter/foundation.dart';

import '../../../core/utils/date_utils.dart';

@immutable
class DhikrUsage {
  const DhikrUsage({
    required this.dhikrId,
    required this.label,
    required this.arabic,
    required this.count,
    required this.sessions,
  });

  final String dhikrId;
  final String label;
  final String arabic;
  final int count;
  final int sessions;
}

@immutable
class DayRecord {
  const DayRecord(this.day, this.count);

  final DateTime day;
  final int count;
}

@immutable
class StatsSummary {
  const StatsSummary({
    required this.totalCount,
    required this.completedSessions,
    required this.totalRounds,
    required this.totalActive,
    required this.bestDay,
    required this.longestSessionCount,
    required this.longestSessionDuration,
    required this.activeDays,
  });

  static const empty = StatsSummary(
    totalCount: 0,
    completedSessions: 0,
    totalRounds: 0,
    totalActive: Duration.zero,
    bestDay: null,
    longestSessionCount: 0,
    longestSessionDuration: Duration.zero,
    activeDays: 0,
  );

  final int totalCount;
  final int completedSessions;
  final int totalRounds;
  final Duration totalActive;
  final DayRecord? bestDay;
  final int longestSessionCount;
  final Duration longestSessionDuration;
  final int activeDays;
}

@immutable
class Streaks {
  const Streaks({required this.current, required this.longest});

  final int current;
  final int longest;

  /// Computes streaks of consecutive active days.
  ///
  /// The current streak is still alive if the last active day is today or
  /// yesterday (the user has the rest of today to continue it).
  factory Streaks.fromDays(Iterable<DateTime> activeDays, DateTime today) {
    final days = {for (final d in activeDays) d.startOfDay}.toList()..sort();
    if (days.isEmpty) return const Streaks(current: 0, longest: 0);

    var longest = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i - 1].addDays(1) == days[i]) {
        run++;
      } else {
        run = 1;
      }
      if (run > longest) longest = run;
    }

    final t = today.startOfDay;
    final last = days.last;
    var current = 0;
    if (last == t || last == t.addDays(-1)) {
      current = 1;
      for (var i = days.length - 1; i > 0; i--) {
        if (days[i - 1].addDays(1) == days[i]) {
          current++;
        } else {
          break;
        }
      }
    }
    return Streaks(current: current, longest: longest);
  }
}

enum StatsPeriod {
  week('Week'),
  month('Month'),
  year('Year');

  const StatsPeriod(this.label);
  final String label;
}

/// One bar in an activity chart.
@immutable
class ActivityBucket {
  const ActivityBucket({required this.start, required this.count, required this.label});

  final DateTime start;
  final int count;
  final String label;
}

abstract interface class StatsRepository {
  /// Repetitions per local day in `[from, to]` (inclusive). Missing days are
  /// omitted.
  Future<Map<DateTime, int>> dailyTotals(DateTime from, DateTime to);

  Future<StatsSummary> summary();

  Future<List<DhikrUsage>> topDhikr({int limit = 5});

  /// Every day with at least one repetition.
  Future<List<DateTime>> activeDays();

  /// Repetitions per dhikr id on [day].
  Future<Map<String, int>> countsByDhikrOn(DateTime day);
}
