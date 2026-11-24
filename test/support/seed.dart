import 'dart:math' as math;

import 'package:sakina/core/database/app_database.dart';
import 'package:sakina/features/dhikr/data/dhikr_seed.dart';
import 'package:sakina/features/goals/data/sqlite_goal_repository.dart';
import 'package:sakina/features/goals/domain/goal.dart';
import 'package:sakina/features/tasbih/data/sqlite_session_repository.dart';
import 'package:sakina/features/tasbih/domain/counter_session.dart';

/// Fills the database with a few weeks of plausible activity.
Future<void> seedSampleHistory(AppDatabase db, DateTime now, {int days = 40}) async {
  final repo = SqliteSessionRepository(db);
  final rnd = math.Random(3);
  final dhikr = DhikrSeed.entries;
  for (var d = days; d >= 1; d--) {
    if (rnd.nextDouble() < 0.2) continue;
    final day = DateTime(now.year, now.month, now.day - d, 6 + rnd.nextInt(14), rnd.nextInt(60));
    final sessions = 1 + rnd.nextInt(3);
    for (var s = 0; s < sessions; s++) {
      final x = dhikr[rnd.nextInt(5)];
      final target = x.suggestedCount ?? 33;
      final count = target * (1 + rnd.nextInt(3)) + rnd.nextInt(10);
      final start = day.add(Duration(minutes: s * 40));
      final created = await repo.insert(
        CounterSession.start(
          dhikrId: x.id,
          dhikrLabel: x.transliteration,
          dhikrArabic: x.arabic,
          target: target,
          now: start,
        ),
      );
      final ended = created
          .copyWith(
            totalCount: count,
            activeDuration: Duration(seconds: (count * 1.4).round()),
            lastActivityAt: start.add(Duration(seconds: (count * 1.4).round())),
          )
          .finish(start.add(Duration(seconds: (count * 1.4).round())));
      await repo.save(ended, dayDelta: count, at: start);
    }
  }
  final goals = SqliteGoalRepository(db);
  await goals.insert(Goal(target: 300, createdAt: now));
  await goals.insert(Goal(target: 100, dhikrId: DhikrSeed.subhanallahWaBihamdihi, createdAt: now));
  await goals.insert(Goal(target: 33, dhikrId: DhikrSeed.subhanallah, createdAt: now));
}
