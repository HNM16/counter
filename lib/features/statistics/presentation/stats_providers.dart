import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../tasbih/data/session_repository_provider.dart';
import '../../tasbih/domain/counter_session.dart';
import '../data/sqlite_stats_repository.dart';
import '../domain/stats_models.dart';

final statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => SqliteStatsRepository(ref.watch(appDatabaseProvider)),
);

DateTime _today(Ref ref) => ref.read(clockProvider)().startOfDay;

final statsSummaryProvider = FutureProvider<StatsSummary>((ref) {
  ref.watch(anyRevisionProvider);
  return ref.watch(statsRepositoryProvider).summary();
});

final topDhikrProvider = FutureProvider<List<DhikrUsage>>((ref) {
  ref.watch(anyRevisionProvider);
  return ref.watch(statsRepositoryProvider).topDhikr(limit: 5);
});

final streaksProvider = FutureProvider<Streaks>((ref) async {
  ref.watch(anyRevisionProvider);
  final days = await ref.watch(statsRepositoryProvider).activeDays();
  return Streaks.fromDays(days, _today(ref));
});

/// Today's repetitions per dhikr id.
final todayByDhikrProvider = FutureProvider<Map<String, int>>((ref) {
  ref.watch(anyRevisionProvider);
  return ref.watch(statsRepositoryProvider).countsByDhikrOn(_today(ref));
});

final todayTotalProvider = FutureProvider<int>((ref) async {
  final byDhikr = await ref.watch(todayByDhikrProvider.future);
  return byDhikr.values.fold<int>(0, (a, b) => a + b);
});

/// Bars for the activity chart in the selected period.
final activitySeriesProvider = FutureProvider.family<List<ActivityBucket>, StatsPeriod>((ref, period) async {
  ref.watch(anyRevisionProvider);
  final repo = ref.watch(statsRepositoryProvider);
  final today = _today(ref);
  switch (period) {
    case StatsPeriod.week:
      final from = today.addDays(-6);
      final totals = await repo.dailyTotals(from, today);
      return [
        for (var i = 0; i < 7; i++)
          ActivityBucket(
            start: from.addDays(i),
            count: totals[from.addDays(i)] ?? 0,
            label: Formatters.weekdayShort(from.addDays(i)),
          ),
      ];
    case StatsPeriod.month:
      final from = today.addDays(-29);
      final totals = await repo.dailyTotals(from, today);
      return [
        for (var i = 0; i < 30; i++)
          ActivityBucket(
            start: from.addDays(i),
            count: totals[from.addDays(i)] ?? 0,
            label: '${from.addDays(i).day}',
          ),
      ];
    case StatsPeriod.year:
      final firstMonth = DateTime(today.year, today.month - 11);
      final totals = await repo.dailyTotals(firstMonth, today);
      final buckets = <ActivityBucket>[];
      for (var i = 0; i < 12; i++) {
        final start = DateTime(firstMonth.year, firstMonth.month + i);
        final end = DateTime(start.year, start.month + 1);
        final sum = totals.entries
            .where((e) => !e.key.isBefore(start) && e.key.isBefore(end))
            .fold<int>(0, (a, e) => a + e.value);
        buckets.add(ActivityBucket(start: start, count: sum, label: Formatters.monthShort(start)));
      }
      return buckets;
  }
});

/// Daily totals for the activity heatmap (last 17 full weeks + this week).
final heatmapProvider = FutureProvider<Map<DateTime, int>>((ref) {
  ref.watch(anyRevisionProvider);
  final today = _today(ref);
  final from = today.startOfWeek.addDays(-7 * 17);
  return ref.watch(statsRepositoryProvider).dailyTotals(from, today);
});

/// Paged session history.
class HistoryController extends AsyncNotifier<List<CounterSession>> {
  static const pageSize = 40;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  Future<List<CounterSession>> build() async {
    ref.watch(anyRevisionProvider);
    final items = await ref.watch(sessionRepositoryProvider).history(limit: pageSize);
    _hasMore = items.length == pageSize;
    return items;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !_hasMore || state.isLoading) return;
    final next = await ref.read(sessionRepositoryProvider).history(limit: pageSize, offset: current.length);
    _hasMore = next.length == pageSize;
    if (ref.mounted) state = AsyncData([...current, ...next]);
  }

  Future<void> delete(CounterSession session) async {
    final id = session.id;
    if (id == null || session.isActive) return;
    final current = state.value ?? const [];
    state = AsyncData(current.where((s) => s.id != id).toList());
    await ref.read(sessionRepositoryProvider).delete(id);
    ref.read(structureRevisionProvider.notifier).bump();
  }
}

final historyProvider = AsyncNotifierProvider<HistoryController, List<CounterSession>>(HistoryController.new);

/// The most recently used distinct dhikr ids, newest first.
final recentDhikrIdsProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(anyRevisionProvider);
  final sessions = await ref.watch(sessionRepositoryProvider).history(limit: 60);
  final seen = <String>{};
  return [
    for (final s in sessions)
      if (seen.add(s.dhikrId)) s.dhikrId,
  ].take(6).toList();
});
