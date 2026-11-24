import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/database/app_database.dart';
import 'package:sakina/core/services/haptics_service.dart';
import 'package:sakina/core/services/notification_service.dart';
import 'package:sakina/core/services/sound_service.dart';
import 'package:sakina/features/dhikr/data/dhikr_seed.dart';
import 'package:sakina/features/dhikr/presentation/dhikr_providers.dart';
import 'package:sakina/features/goals/presentation/goal_providers.dart';
import 'package:sakina/features/reminders/domain/reminder.dart';
import 'package:sakina/features/reminders/presentation/reminder_providers.dart';
import 'package:sakina/features/settings/presentation/settings_controller.dart';
import 'package:sakina/features/statistics/presentation/stats_providers.dart';
import 'package:sakina/features/tasbih/data/session_repository_provider.dart';
import 'package:sakina/features/tasbih/presentation/tasbih_controller.dart';

import '../support/harness.dart';

void main() {
  late AppDatabase db;
  late TestClock clock;
  late RecordingHaptics haptics;
  late RecordingSound sound;

  setUp(() async {
    db = await openTestDatabase();
    clock = TestClock(DateTime(2026, 6, 10, 7));
    haptics = RecordingHaptics();
    sound = RecordingSound();
  });
  tearDown(() => db.close());

  Future<ProviderContainer> boot({Map<String, Object> prefs = const {}}) async {
    final c = await createTestContainer(database: db, clock: clock, prefs: prefs, haptics: haptics, sound: sound);
    await c.read(tasbihControllerProvider.future);
    return c;
  }

  TasbihController ctrl(ProviderContainer c) => c.read(tasbihControllerProvider.notifier);
  TasbihState state(ProviderContainer c) => c.read(tasbihControllerProvider).requireValue;

  /// Counts [n] repetitions at a natural cadence.
  Future<void> count(ProviderContainer c, int n) async {
    for (var i = 0; i < n; i++) {
      clock.advance(const Duration(milliseconds: 400));
      expect(ctrl(c).increment(), isTrue);
    }
    await ctrl(c).flush();
  }

  test('starts with the default dhikr and its suggested target', () async {
    final c = await boot();
    final s = state(c).session;
    expect(s.dhikrId, DhikrSeed.defaultId);
    expect(s.target, 33);
    expect(s.totalCount, 0);
    expect(s.id, isNotNull);
  });

  test('the counter survives an application restart', () async {
    final first = await boot();
    await count(first, 40);
    ctrl(first).pause();
    await ctrl(first).flush();
    first.dispose();

    final second = await boot();
    final s = state(second).session;
    expect(s.totalCount, 40);
    expect(s.roundsCompleted, 1);
    expect(s.displayCount, 7);
    expect(s.isPaused, isTrue);
  });

  test('rapid duplicate input is counted once', () async {
    final c = await boot();
    clock.advance(const Duration(seconds: 1));
    expect(ctrl(c).increment(), isTrue);
    expect(ctrl(c).increment(), isFalse, reason: 'same instant');
    clock.advance(const Duration(milliseconds: 30));
    expect(ctrl(c).increment(), isFalse, reason: 'touch bounce');
    expect(state(c).session.totalCount, 1);
    await ctrl(c).flush();
  });

  test('completing a round emits an event and a stronger haptic', () async {
    final c = await boot();
    await count(c, 32);
    expect(state(c).event, isNull);
    await count(c, 1);
    final e = state(c).event!;
    expect(e.kind, TasbihEventKind.roundCompleted);
    expect(e.round, 1);
    expect(haptics.played.last, HapticPattern.round);
    expect(haptics.played.where((p) => p == HapticPattern.bead).length, 32);
  });

  test('reaching a daily goal emits a goal event exactly once', () async {
    final c = await boot();
    await c.read(goalsProvider.notifier).add(target: 10, dhikrId: DhikrSeed.subhanallah);
    await count(c, 9);
    expect(state(c).event, isNull);
    await count(c, 1);
    final e = state(c).event!;
    expect(e.kind, TasbihEventKind.goalReached);
    expect(e.goal!.target, 10);
    expect(haptics.played.last, HapticPattern.goal);
    final serial = e.serial;
    await count(c, 5);
    expect(state(c).event!.serial, serial, reason: 'no repeat celebration past the target');
  });

  test('goal detection includes counts made earlier today', () async {
    final c = await boot();
    await count(c, 6);
    await ctrl(c).finish();
    await c.read(goalsProvider.notifier).add(target: 8);
    await c.read(goalsProvider.future);
    await count(c, 1);
    expect(state(c).event, isNull);
    await count(c, 1);
    expect(state(c).event?.kind, TasbihEventKind.goalReached);
  });

  test('a paused counter resumes on tap instead of counting', () async {
    final c = await boot();
    await count(c, 3);
    ctrl(c).pause();
    clock.advance(const Duration(seconds: 2));
    expect(ctrl(c).increment(), isFalse);
    expect(state(c).session.totalCount, 3);
    expect(state(c).session.isPaused, isFalse);
    clock.advance(const Duration(seconds: 1));
    expect(ctrl(c).increment(), isTrue);
    expect(state(c).session.totalCount, 4);
    await ctrl(c).flush();
  });

  test('undo removes the last count from the session and today', () async {
    final c = await boot();
    await count(c, 5);
    ctrl(c).undo();
    await ctrl(c).flush();
    expect(state(c).session.totalCount, 4);
    expect(await c.read(todayTotalProvider.future), 4);
  });

  test('switching dhikr saves the previous session to history', () async {
    final c = await boot();
    await count(c, 12);
    final other = (await c.read(dhikrRepositoryProvider).byId(DhikrSeed.salawat))!;
    final saved = await ctrl(c).selectDhikr(other);
    expect(saved, isTrue);
    expect(state(c).session.dhikrId, DhikrSeed.salawat);
    expect(state(c).session.totalCount, 0);
    expect(state(c).session.target, 33, reason: 'no suggested count: default round size');

    final history = await c.read(sessionRepositoryProvider).history();
    final finished = history.firstWhere((s) => !s.isActive);
    expect(finished.dhikrId, DhikrSeed.subhanallah);
    expect(finished.totalCount, 12);
  });

  test('switching from an empty session leaves no trace', () async {
    final c = await boot();
    final other = (await c.read(dhikrRepositoryProvider).byId(DhikrSeed.alhamdulillah))!;
    expect(await ctrl(c).selectDhikr(other), isFalse);
    expect(await c.read(sessionRepositoryProvider).history(), isEmpty);
  });

  test('the chosen dhikr is remembered for the next launch', () async {
    final first = await boot();
    final other = (await first.read(dhikrRepositoryProvider).byId(DhikrSeed.astaghfirullah))!;
    await ctrl(first).selectDhikr(other);
    // Simulate the active row being gone (e.g. finished elsewhere).
    await first.read(sessionRepositoryProvider).clearAll();
    final prefs = first.read(settingsProvider);
    first.dispose();

    final second = await boot(prefs: {'settings.lastDhikrId': prefs.lastDhikrId!});
    expect(state(second).session.dhikrId, DhikrSeed.astaghfirullah);
    expect(state(second).session.target, 100);
  });

  test('reset can keep the count in history or discard it entirely', () async {
    final c = await boot();
    await count(c, 7);
    await ctrl(c).reset(keepInHistory: true);
    expect(state(c).session.totalCount, 0);
    expect(await c.read(todayTotalProvider.future), 7);

    await count(c, 5);
    await ctrl(c).reset(keepInHistory: false);
    expect(state(c).session.totalCount, 0);
    c.invalidate(todayTotalProvider);
    expect(await c.read(todayTotalProvider.future), 7, reason: 'discarded counts leave statistics');
  });

  test('finish returns a summary and starts a fresh session', () async {
    final c = await boot();
    await count(c, 34);
    final finished = (await ctrl(c).finish())!;
    expect(finished.totalCount, 34);
    expect(finished.roundsCompleted, 1);
    expect(finished.endedAt, isNotNull);
    expect(state(c).session.totalCount, 0);
    expect(state(c).session.dhikrId, finished.dhikrId);
    expect(await ctrl(c).finish(), isNull, reason: 'nothing to save');
  });

  test('changing the round size keeps the count', () async {
    final c = await boot();
    await count(c, 40);
    ctrl(c).setTarget(100);
    expect(state(c).session.displayCount, 40);
    expect(state(c).session.roundsCompleted, 0);
    await ctrl(c).flush();
  });

  test('haptics and sound follow the settings', () async {
    final c = await boot();
    await c.read(settingsProvider.notifier).update((s) => s.copyWith(hapticsEnabled: false, soundEnabled: true));
    await count(c, 33);
    expect(haptics.played, isEmpty);
    expect(sound.played.where((s) => s == SoundCue.click).length, 32);
    expect(sound.played.last, SoundCue.chime);
  });

  test('clearing history starts over with the same dhikr', () async {
    final c = await boot();
    await count(c, 9);
    await ctrl(c).finish();
    await count(c, 2);
    await ctrl(c).clearAllHistory();
    expect(state(c).session.totalCount, 0);
    expect(await c.read(sessionRepositoryProvider).history(), isEmpty);
  });

  group('reminders', () {
    test('schedules one weekly notification per selected day', () async {
      final notifications = DisabledNotificationService();
      final c = await createTestContainer(database: db, clock: clock, notifications: notifications);
      final result = await c
          .read(remindersProvider.notifier)
          .save(const Reminder(hour: 6, minute: 30, weekdays: {1, 3, 5}, dhikrId: DhikrSeed.salawat));
      expect(result, ReminderSaveResult.scheduled);
      final saved = (await c.read(remindersProvider.future)).single;
      expect(notifications.scheduled.keys.toSet(), {saved.notificationId(1), saved.notificationId(3), saved.notificationId(5)});
      expect(notifications.scheduled.values.first.payload, 'dhikr:${DhikrSeed.salawat}');

      await c.read(remindersProvider.notifier).setEnabled(saved, false);
      expect(notifications.scheduled, isEmpty);
    });

    test('a denied permission saves the reminder as disabled', () async {
      final notifications = DisabledNotificationService(permissionGranted: false);
      final c = await createTestContainer(database: db, clock: clock, notifications: notifications);
      final result = await c
          .read(remindersProvider.notifier)
          .save(const Reminder(hour: 21, minute: 0, weekdays: Reminder.everyDay));
      expect(result, ReminderSaveResult.permissionDenied);
      expect((await c.read(remindersProvider.future)).single.enabled, isFalse);
      expect(notifications.scheduled, isEmpty);
    });

    test('deleting a reminder cancels its notifications', () async {
      final notifications = DisabledNotificationService();
      final c = await createTestContainer(database: db, clock: clock, notifications: notifications);
      await c.read(remindersProvider.notifier).save(const Reminder(hour: 8, minute: 0, weekdays: Reminder.everyDay));
      final saved = (await c.read(remindersProvider.future)).single;
      expect(notifications.scheduled.length, 7);
      await c.read(remindersProvider.notifier).remove(saved);
      expect(notifications.scheduled, isEmpty);
      expect(await c.read(remindersProvider.future), isEmpty);
    });
  });
}
