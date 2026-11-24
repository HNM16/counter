import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/utils/date_utils.dart';
import 'package:sakina/core/utils/formatters.dart';
import 'package:sakina/features/goals/domain/goal.dart';
import 'package:sakina/features/reminders/domain/reminder.dart';
import 'package:sakina/features/statistics/domain/stats_models.dart';

void main() {
  final today = DateTime(2026, 5, 20);

  group('streaks', () {
    test('no activity means no streak', () {
      final s = Streaks.fromDays(const [], today);
      expect((s.current, s.longest), (0, 0));
    });

    test('counts consecutive days ending today', () {
      final s = Streaks.fromDays([for (var i = 0; i < 5; i++) today.addDays(-i)], today);
      expect((s.current, s.longest), (5, 5));
    });

    test('a streak ending yesterday is still alive', () {
      final s = Streaks.fromDays([today.addDays(-1), today.addDays(-2)], today);
      expect(s.current, 2);
    });

    test('a gap of a full day breaks the current streak but keeps the record', () {
      final days = [
        for (var i = 10; i < 17; i++) today.addDays(-i), // 7-day run
        today.addDays(-3),
        today.addDays(-2),
      ];
      final s = Streaks.fromDays(days, today);
      expect(s.current, 0);
      expect(s.longest, 7);
    });

    test('duplicate and unsorted days are handled', () {
      final s = Streaks.fromDays([today, today.addDays(-1), today, today.addDays(-2)], today);
      expect((s.current, s.longest), (3, 3));
    });

    test('streaks are calendar based across DST changes', () {
      // Spans the European spring DST change.
      final base = DateTime(2026, 3, 31);
      final s = Streaks.fromDays([for (var i = 0; i < 6; i++) base.addDays(-i)], base);
      expect(s.longest, 6);
    });
  });

  group('goal progress', () {
    final goals = [
      Goal(id: 1, target: 100, createdAt: today),
      Goal(id: 2, target: 33, dhikrId: 'a', createdAt: today),
    ];

    test('overall goals count every dhikr; specific goals only their own', () {
      final p = GoalProgress.compute(goals, {'a': 40, 'b': 30});
      expect(p[0].current, 70);
      expect(p[1].current, 40);
      expect(p[1].isComplete, isTrue);
      expect(p[1].fraction, 1.0);
      expect(p[0].remaining, 30);
    });

    test('overall completion caps each goal at its own target', () {
      final p = GoalProgress.compute(goals, {'a': 500});
      // 100/100 and 33/33 -> complete; extra counts are not double-counted.
      expect(GoalProgress.overall(p), 1.0);
      final partial = GoalProgress.compute(goals, {'b': 50});
      expect(GoalProgress.overall(partial), closeTo(50 / 133, 1e-9));
    });

    test('detects exactly the count that crosses a target', () {
      expect(GoalProgress.crossedBy(goals, dhikrId: 'a', before: 32, totalBefore: 50).map((g) => g.id), [2]);
      expect(GoalProgress.crossedBy(goals, dhikrId: 'a', before: 33, totalBefore: 51), isEmpty);
      expect(GoalProgress.crossedBy(goals, dhikrId: 'b', before: 10, totalBefore: 99).map((g) => g.id), [1]);
      expect(GoalProgress.crossedBy(goals, dhikrId: 'b', before: 32, totalBefore: 10), isEmpty);
    });
  });

  group('reminders', () {
    test('weekdays survive the bitmask round trip', () {
      const r = Reminder(hour: 6, minute: 30, weekdays: {1, 3, 5, 7});
      expect(Reminder.weekdaysFromMask(r.weekdayMask), {1, 3, 5, 7});
      expect(Reminder.weekdaysFromMask(Reminder(hour: 0, minute: 0, weekdays: Reminder.everyDay).weekdayMask),
          Reminder.everyDay);
    });

    test('notification ids are unique per reminder and weekday', () {
      const a = Reminder(id: 1, hour: 0, minute: 0, weekdays: {});
      const b = Reminder(id: 2, hour: 0, minute: 0, weekdays: {});
      final ids = {...a.allNotificationIds, ...b.allNotificationIds};
      expect(ids.length, 14);
    });
  });

  group('formatting and dates', () {
    test('day keys round trip', () {
      final d = DateTime(2026, 1, 9, 23, 59);
      expect(DayKey.of(d), '2026-01-09');
      expect(DayKey.parse('2026-01-09'), DateTime(2026, 1, 9));
    });

    test('week starts on Monday', () {
      expect(DateTime(2026, 5, 20).startOfWeek, DateTime(2026, 5, 18));
      expect(DateTime(2026, 5, 18).startOfWeek, DateTime(2026, 5, 18));
    });

    test('numbers and durations read naturally', () {
      expect(Formatters.count(12345), '12,345');
      expect(Formatters.compact(950), '950');
      expect(Formatters.compact(1250), '1.3k');
      expect(Formatters.compact(15000), '15k');
      expect(Formatters.clock(const Duration(minutes: 4, seconds: 7)), '4:07');
      expect(Formatters.clock(const Duration(hours: 1, minutes: 4, seconds: 7)), '1:04:07');
      expect(Formatters.duration(const Duration(seconds: 45)), '45s');
      expect(Formatters.duration(const Duration(hours: 1, minutes: 5)), '1h 05m');
      expect(Formatters.plural(1, 'round'), '1 round');
      expect(Formatters.plural(3, 'round'), '3 rounds');
    });
  });
}
