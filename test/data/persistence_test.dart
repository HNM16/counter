import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/database/app_database.dart';
import 'package:sakina/features/dhikr/data/dhikr_seed.dart';
import 'package:sakina/features/dhikr/data/sqlite_dhikr_repository.dart';
import 'package:sakina/features/goals/data/sqlite_goal_repository.dart';
import 'package:sakina/features/goals/domain/goal.dart';
import 'package:sakina/features/reminders/data/sqlite_reminder_repository.dart';
import 'package:sakina/features/reminders/domain/reminder.dart';
import 'package:sakina/features/settings/data/settings_repository.dart';
import 'package:sakina/features/settings/domain/app_settings.dart';
import 'package:sakina/features/statistics/data/sqlite_stats_repository.dart';
import 'package:sakina/features/tasbih/data/sqlite_session_repository.dart';
import 'package:sakina/features/tasbih/domain/counter_session.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/harness.dart';

void main() {
  late AppDatabase db;
  setUp(() async => db = await openTestDatabase());
  tearDown(() => db.close());

  CounterSession draft(String id, DateTime at, {int target = 33}) =>
      CounterSession.start(dhikrId: id, dhikrLabel: id.toUpperCase(), dhikrArabic: 'ع', target: target, now: at);

  group('dhikr library', () {
    test('seeds every built-in dhikr with Arabic, transliteration and translation', () async {
      final all = await SqliteDhikrRepository(db).all();
      expect(all.length, DhikrSeed.entries.length);
      for (final d in all) {
        expect(d.arabic, isNotEmpty);
        expect(d.transliteration, isNotEmpty);
        expect(d.translation, isNotEmpty);
        expect(d.isCustom, isFalse);
      }
      expect(all.map((d) => d.arabic), contains('سُبْحَانَ اللَّهِ'));
    });

    test('suggested counts always come with a source', () async {
      for (final d in await SqliteDhikrRepository(db).all()) {
        if (d.suggestedCount != null) expect(d.reference, isNotNull, reason: d.id);
      }
    });

    test('re-seeding is idempotent and keeps favourites', () async {
      final repo = SqliteDhikrRepository(db);
      final first = (await repo.byId(DhikrSeed.alhamdulillah))!;
      await repo.update(first.copyWith(isFavorite: true));
      await repo.ensureSeeded();
      expect((await repo.all()).length, DhikrSeed.entries.length);
      expect((await repo.byId(DhikrSeed.alhamdulillah))!.isFavorite, isTrue);
    });

    test('creates, edits and deletes custom dhikr', () async {
      final repo = SqliteDhikrRepository(db, clock: () => DateTime(2026, 2, 2));
      final created = await repo.create(
        arabic: ' حَسْبُنَا اللَّهُ ',
        transliteration: 'Hasbuna Allah',
        translation: 'Allah is sufficient for us.',
        suggestedCount: 7,
      );
      expect(created.isCustom, isTrue);
      expect(created.arabic, 'حَسْبُنَا اللَّهُ', reason: 'input is trimmed');

      await repo.update(created.copyWith(transliteration: 'Hasbunallah', clearSuggestedCount: true));
      final edited = (await repo.byId(created.id))!;
      expect(edited.transliteration, 'Hasbunallah');
      expect(edited.suggestedCount, isNull);

      await repo.delete(created.id);
      expect(await repo.byId(created.id), isNull);
    });

    test('deleting a custom dhikr removes its goals and detaches reminders', () async {
      final repo = SqliteDhikrRepository(db);
      final d = await repo.create(arabic: '', transliteration: 'Mine', translation: '');
      await SqliteGoalRepository(db).insert(Goal(target: 10, dhikrId: d.id, createdAt: DateTime(2026)));
      final r = await SqliteReminderRepository(db).insert(
        Reminder(hour: 5, minute: 0, weekdays: Reminder.everyDay, dhikrId: d.id),
      );
      await repo.delete(d.id);
      expect(await SqliteGoalRepository(db).all(), isEmpty);
      final reminder = (await SqliteReminderRepository(db).all()).single;
      expect(reminder.id, r.id);
      expect(reminder.dhikrId, isNull);
    });

    test('built-in dhikr cannot be deleted', () async {
      final repo = SqliteDhikrRepository(db);
      await repo.delete(DhikrSeed.subhanallah);
      expect(await repo.byId(DhikrSeed.subhanallah), isNotNull);
    });
  });

  group('sessions', () {
    test('the active session round-trips exactly', () async {
      final repo = SqliteSessionRepository(db);
      final t = DateTime(2026, 4, 4, 9, 30);
      var s = await repo.insert(draft('a', t, target: 99));
      s = s.copyWith(totalCount: 120, activeDuration: const Duration(seconds: 95), isPaused: true, lastActivityAt: t);
      await repo.save(s, dayDelta: 120, at: t);

      final loaded = (await repo.loadActive())!;
      expect(loaded, s);
      expect(loaded.roundsCompleted, 1);
      expect(loaded.isPaused, isTrue);
    });

    test('a finished session is no longer active', () async {
      final repo = SqliteSessionRepository(db);
      final t = DateTime(2026, 4, 4, 9);
      final s = await repo.insert(draft('a', t));
      await repo.save(s.copyWith(totalCount: 3).finish(t.add(const Duration(minutes: 1))));
      expect(await repo.loadActive(), isNull);
      expect((await repo.history()).single.endedAt, isNotNull);
    });

    test('counts are attributed to the day they happened, even across midnight', () async {
      final repo = SqliteSessionRepository(db);
      final stats = SqliteStatsRepository(db);
      final late = DateTime(2026, 4, 4, 23, 59);
      final early = DateTime(2026, 4, 5, 0, 1);
      var s = await repo.insert(draft('a', late));
      s = s.copyWith(totalCount: 10);
      await repo.save(s, dayDelta: 10, at: late);
      s = s.copyWith(totalCount: 15);
      await repo.save(s, dayDelta: 5, at: early);

      final totals = await stats.dailyTotals(DateTime(2026, 4, 1), DateTime(2026, 4, 30));
      expect(totals, {DateTime(2026, 4, 4): 10, DateTime(2026, 4, 5): 5});
    });

    test('undo removes counts from the given day first, then the latest day', () async {
      final repo = SqliteSessionRepository(db);
      final stats = SqliteStatsRepository(db);
      final d1 = DateTime(2026, 4, 4, 22);
      final d2 = DateTime(2026, 4, 5, 8);
      var s = await repo.insert(draft('a', d1));
      await repo.save(s = s.copyWith(totalCount: 4), dayDelta: 4, at: d1);
      await repo.save(s = s.copyWith(totalCount: 6), dayDelta: 2, at: d2);
      // Undo three on day 2: two come from day 2, one from day 1.
      await repo.save(s = s.copyWith(totalCount: 3), dayDelta: -3, at: d2);

      final totals = await stats.dailyTotals(DateTime(2026, 4, 1), DateTime(2026, 4, 30));
      expect(totals, {DateTime(2026, 4, 4): 3});
      expect(totals.values.fold<int>(0, (a, b) => a + b), s.totalCount);
    });

    test('history is newest first and hides empty sessions', () async {
      final repo = SqliteSessionRepository(db);
      for (var i = 0; i < 3; i++) {
        final t = DateTime(2026, 4, 1 + i, 10);
        final s = await repo.insert(draft('d$i', t));
        await repo.save(s.copyWith(totalCount: i == 1 ? 0 : 5, lastActivityAt: t).finish(t), dayDelta: 5, at: t);
      }
      final history = await repo.history();
      expect(history.map((s) => s.dhikrId), ['d2', 'd0']);
    });

    test('history pages with limit and offset', () async {
      final repo = SqliteSessionRepository(db);
      for (var i = 0; i < 5; i++) {
        final t = DateTime(2026, 4, 1, 8 + i);
        final s = await repo.insert(draft('d$i', t));
        await repo.save(s.copyWith(totalCount: 1, lastActivityAt: t).finish(t));
      }
      final page1 = await repo.history(limit: 2);
      final page2 = await repo.history(limit: 2, offset: 2);
      expect(page1.map((s) => s.dhikrId), ['d4', 'd3']);
      expect(page2.map((s) => s.dhikrId), ['d2', 'd1']);
    });

    test('deleting a session removes it from statistics', () async {
      final repo = SqliteSessionRepository(db);
      final stats = SqliteStatsRepository(db);
      final t = DateTime(2026, 4, 4, 10);
      final s = await repo.insert(draft('a', t));
      await repo.save(s.copyWith(totalCount: 33), dayDelta: 33, at: t);
      await repo.delete(s.id!);
      expect(await stats.dailyTotals(DateTime(2026), DateTime(2027)), isEmpty);
      expect((await stats.summary()).totalCount, 0);
    });

    test('clearAll wipes sessions and per-day counts', () async {
      final repo = SqliteSessionRepository(db);
      final t = DateTime(2026, 4, 4, 10);
      final s = await repo.insert(draft('a', t));
      await repo.save(s.copyWith(totalCount: 3), dayDelta: 3, at: t);
      await repo.clearAll();
      expect(await repo.history(), isEmpty);
      expect(await SqliteStatsRepository(db).activeDays(), isEmpty);
    });
  });

  group('statistics', () {
    Future<void> session(String id, DateTime at, int count, {int target = 33, bool finish = true}) async {
      final repo = SqliteSessionRepository(db);
      var s = await repo.insert(draft(id, at, target: target));
      s = s.copyWith(totalCount: count, activeDuration: Duration(seconds: count), lastActivityAt: at);
      if (finish) s = s.finish(at);
      await repo.save(s, dayDelta: count, at: at);
    }

    test('summarises totals, rounds, sessions and records', () async {
      await session('a', DateTime(2026, 4, 1, 9), 66);
      await session('b', DateTime(2026, 4, 1, 10), 100, target: 100);
      await session('a', DateTime(2026, 4, 3, 9), 10, finish: false);

      final s = await SqliteStatsRepository(db).summary();
      expect(s.totalCount, 176);
      expect(s.completedSessions, 2);
      expect(s.totalRounds, 3);
      expect(s.longestSessionCount, 100);
      expect(s.longestSessionDuration, const Duration(seconds: 100));
      expect(s.bestDay!.day, DateTime(2026, 4, 1));
      expect(s.bestDay!.count, 166);
      expect(s.activeDays, 2);
    });

    test('ranks the most used dhikr', () async {
      await session('a', DateTime(2026, 4, 1, 9), 10);
      await session('b', DateTime(2026, 4, 1, 10), 50);
      await session('a', DateTime(2026, 4, 2, 9), 30);
      final top = await SqliteStatsRepository(db).topDhikr();
      expect(top.map((u) => (u.dhikrId, u.count, u.sessions)), [('b', 50, 1), ('a', 40, 2)]);
    });

    test('reports per-dhikr counts for a given day', () async {
      await session('a', DateTime(2026, 4, 1, 9), 10);
      await session('b', DateTime(2026, 4, 1, 10), 5);
      await session('a', DateTime(2026, 4, 2, 9), 7);
      expect(await SqliteStatsRepository(db).countsByDhikrOn(DateTime(2026, 4, 1, 18)), {'a': 10, 'b': 5});
    });

    test('lists active days in order', () async {
      await session('a', DateTime(2026, 4, 3, 9), 1);
      await session('a', DateTime(2026, 4, 1, 9), 1);
      expect(await SqliteStatsRepository(db).activeDays(), [DateTime(2026, 4, 1), DateTime(2026, 4, 3)]);
    });
  });

  group('goals and reminders', () {
    test('goals support create, update and delete', () async {
      final repo = SqliteGoalRepository(db);
      final g = await repo.insert(Goal(target: 100, createdAt: DateTime(2026)));
      await repo.update(g.copyWith(target: 1000, dhikrId: DhikrSeed.salawat));
      expect((await repo.all()).single.target, 1000);
      expect((await repo.all()).single.dhikrId, DhikrSeed.salawat);
      await repo.delete(g.id!);
      expect(await repo.all(), isEmpty);
    });

    test('reminders keep their weekdays and are ordered by time', () async {
      final repo = SqliteReminderRepository(db);
      await repo.insert(const Reminder(hour: 21, minute: 0, weekdays: {5}));
      final morning = await repo.insert(const Reminder(hour: 6, minute: 15, weekdays: {1, 2, 3}, enabled: false));
      final all = await repo.all();
      expect(all.first.id, morning.id);
      expect(all.first.weekdays, {1, 2, 3});
      expect(all.first.enabled, isFalse);
    });
  });

  group('settings', () {
    test('every preference survives a save and reload', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = SettingsRepository(await SharedPreferences.getInstance());
      const custom = AppSettings(
        themeMode: AppThemeMode.dark,
        accent: Color(0xFF1F6F78),
        counterMode: CounterMode.digital,
        tasbihStyle: TasbihStyle.strand,
        beadMaterial: BeadMaterial.jade,
        beadTint: Color(0xFF123456),
        beadSize: BeadSize.large,
        beadCount: 99,
        tasbihBackground: TasbihBackground.night,
        digitalDesign: DigitalDesign.custom,
        digitalLayout: DigitalLayout.device,
        customDigitalBackground: Color(0xFF222222),
        customDigitalAccent: Color(0xFFEEDDCC),
        defaultTarget: 100,
        hapticsEnabled: false,
        soundEnabled: true,
        arabicScale: 1.3,
        textScale: 1.1,
        showTransliteration: false,
        showTranslation: false,
        lastDhikrId: 'salawat',
      );
      await repo.save(custom);
      expect(repo.load(), custom);
    });

    test('clearing the tint and corrupt values fall back safely', () async {
      SharedPreferences.setMockInitialValues({
        'settings.beadCount': 50,
        'settings.tasbihStyle': 'unknown',
        'settings.arabicScale': 9.0,
      });
      final repo = SettingsRepository(await SharedPreferences.getInstance());
      final s = repo.load();
      expect(s.beadCount, 33);
      expect(s.tasbihStyle, TasbihStyle.ring);
      expect(s.arabicScale, AppSettings.maxArabicScale);

      await repo.save(s.copyWith(beadTint: const Color(0xFF000000)));
      await repo.save(repo.load().copyWith(clearBeadTint: true));
      expect(repo.load().beadTint, isNull);
    });
  });
}
