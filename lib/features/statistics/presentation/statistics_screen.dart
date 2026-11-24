import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/arabic_text.dart';
import '../../../shared/widgets/common.dart';
import '../../tasbih/domain/counter_session.dart';
import '../domain/stats_models.dart';
import 'stats_providers.dart';
import 'widgets/activity_chart.dart';
import 'widgets/session_tile.dart';

final _periodProvider = NotifierProvider<_PeriodNotifier, StatsPeriod>(_PeriodNotifier.new);

class _PeriodNotifier extends Notifier<StatsPeriod> {
  @override
  StatsPeriod build() => StatsPeriod.week;

  void set(StatsPeriod p) => state = p;
}

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final summary = ref.watch(statsSummaryProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: summary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load statistics.\n$e', textAlign: TextAlign.center)),
          data: (s) => ListView(
            padding: const EdgeInsets.only(bottom: Space.xxl),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, 0),
                child: Text('Statistics', style: text.headlineLarge),
              ),
              if (s.totalCount == 0)
                const EmptyState(
                  icon: Icons.insights_outlined,
                  title: 'Your journey starts with one bead',
                  message: 'Count your first dhikr and your activity, records and history will appear here.',
                )
              else ...[
                _Overview(summary: s),
                const _ActivitySection(),
                const SectionHeader('Last 18 weeks'),
                const _HeatmapSection(),
                const SectionHeader('Most remembered'),
                const _TopDhikr(),
                const SectionHeader('Personal records'),
                _Records(summary: s),
                SectionHeader('Recent sessions', action: 'All history', onAction: () => context.push(Routes.history)),
                const _RecentSessions(),
              ],
            ].animate(interval: 40.ms).fadeIn(duration: 320.ms),
          ),
        ),
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview({required this.summary});

  final StatsSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayTotalProvider).value ?? 0;
    final streak = ref.watch(streaksProvider).value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, 0),
      child: Row(
        children: [
          Expanded(child: StatPair(value: Formatters.compact(summary.totalCount), label: 'All time')),
          Expanded(child: StatPair(value: Formatters.compact(today), label: 'Today')),
          Expanded(
            child: StatPair(
              value: '${streak?.current ?? 0}',
              label: 'Day streak',
              valueColor: context.colors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitySection extends ConsumerWidget {
  const _ActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_periodProvider);
    final series = ref.watch(activitySeriesProvider(period));
    final text = Theme.of(context).textTheme;
    final now = ref.watch(clockProvider)();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader('Activity'),
        Padding(
          padding: Space.pagePadding,
          child: SegmentedButton<StatsPeriod>(
            showSelectedIcon: false,
            segments: [for (final p in StatsPeriod.values) ButtonSegment(value: p, label: Text(p.label))],
            selected: {period},
            onSelectionChanged: (s) => ref.read(_periodProvider.notifier).set(s.first),
          ),
        ),
        const SizedBox(height: Space.md),
        Padding(
          padding: Space.pagePadding,
          child: series.when(
            loading: () => const SizedBox(height: 230),
            error: (e, _) => Text('$e'),
            data: (buckets) {
              final total = buckets.fold<int>(0, (a, b) => a + b.count);
              final days = period == StatsPeriod.year ? 365 : buckets.length;
              final avg = days == 0 ? 0 : (total / days).round();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Formatters.count(total)} repetitions  ·  ${Formatters.count(avg)} per day on average',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: Space.xs),
                  ActivityBarChart(
                    key: ValueKey(period),
                    buckets: buckets,
                    height: 170,
                    describe: (b) => period == StatsPeriod.year
                        ? '${Formatters.monthShort(b.start)} ${b.start.year}: ${Formatters.count(b.count)}'
                        : '${Formatters.relativeDay(b.start, now)}: ${Formatters.count(b.count)}',
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeatmapSection extends ConsumerWidget {
  const _HeatmapSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(heatmapProvider);
    final now = ref.watch(clockProvider)();
    return Padding(
      padding: Space.pagePadding,
      child: data.when(
        loading: () => const SizedBox(height: 120),
        error: (e, _) => Text('$e'),
        data: (totals) => ActivityHeatmap(totals: totals, today: DateTime(now.year, now.month, now.day)),
      ),
    );
  }
}

class _TopDhikr extends ConsumerWidget {
  const _TopDhikr();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final top = ref.watch(topDhikrProvider).value ?? const <DhikrUsage>[];
    if (top.isEmpty) return const SizedBox.shrink();
    final max = top.first.count;
    return Column(
      children: [
        for (final (i, u) in top.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text('${i + 1}', style: text.labelMedium!.copyWith(color: c.textTertiary)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(u.label, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Text(Formatters.count(u.count), style: text.labelLarge),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: max == 0 ? 0 : u.count / max,
                          minHeight: 4,
                          color: i == 0 ? c.gold : c.accent,
                          backgroundColor: c.surfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.md),
                SizedBox(width: 92, child: ArabicText(u.arabic, size: 17, maxLines: 1, textAlign: TextAlign.right)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Records extends ConsumerWidget {
  const _Records({required this.summary});

  final StatsSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streaksProvider).value;
    final best = summary.bestDay;
    final items = <(IconData, String, String)>[
      (
        Icons.wb_sunny_outlined,
        'Best day',
        best == null ? '-' : '${Formatters.count(best.count)}  ·  ${Formatters.fullDate(best.day)}',
      ),
      (Icons.local_fire_department_outlined, 'Longest streak', Formatters.plural(streak?.longest ?? 0, 'day')),
      (Icons.bolt_outlined, 'Longest session', Formatters.plural(summary.longestSessionCount, 'repetition')),
      (Icons.timer_outlined, 'Longest focus', Formatters.duration(summary.longestSessionDuration)),
      (Icons.task_alt, 'Completed sessions', Formatters.count(summary.completedSessions)),
      (Icons.autorenew, 'Rounds completed', Formatters.count(summary.totalRounds)),
      (Icons.hourglass_bottom_rounded, 'Total focused time', Formatters.duration(summary.totalActive)),
      (Icons.calendar_month_outlined, 'Active days', Formatters.count(summary.activeDays)),
    ];
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final (icon, label, value) in items)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: 9),
            child: Row(
              children: [
                Icon(icon, size: 20, color: c.accent),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(label, style: text.bodyMedium!.copyWith(color: c.textPrimary))),
                Text(value, style: text.labelLarge),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentSessions extends ConsumerWidget {
  const _RecentSessions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(historyProvider).value ?? const <CounterSession>[];
    return Column(
      children: [for (final s in sessions.take(4)) SessionTile(session: s)],
    );
  }
}
