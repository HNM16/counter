import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/geometric_pattern.dart';
import '../../statistics/domain/stats_models.dart';
import '../../statistics/presentation/stats_providers.dart';
import '../../statistics/presentation/widgets/activity_chart.dart';
import 'widgets/daily_hero.dart';
import 'widgets/goals_overview.dart';
import 'widgets/recent_dhikr_strip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    final sections = <Widget>[
      _Header(now: now),
      const DailyHero(),
      const SectionHeader('Continue with', padding: EdgeInsets.fromLTRB(Space.gutter, Space.xxl, Space.xs, Space.sm)),
      const RecentDhikrStrip(),
      SectionHeader('Daily goals', action: 'Manage', onAction: () => context.push(Routes.goals)),
      const GoalsOverview(),
      SectionHeader('This week', action: 'Statistics', onAction: () => context.go(Routes.stats)),
      const _WeekGlance(),
      const SizedBox(height: Space.lg),
      const Hairline(),
      ListTile(
        leading: Icon(Icons.menu_book_outlined, color: c.accent),
        title: const Text('Dhikr library'),
        subtitle: const Text('Browse, favourite and create your own'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(Routes.library),
      ),
      const Hairline(),
      ListTile(
        leading: Icon(Icons.notifications_none_rounded, color: c.accent),
        title: const Text('Reminders'),
        subtitle: const Text('Gentle, optional nudges'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(Routes.reminders),
      ),
      const SizedBox(height: Space.xxl),
      Center(
        child: Text(
          '"So remember Me; I will remember you."  Quran 2:152',
          style: text.bodySmall!.copyWith(color: c.textTertiary, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: Space.xxl),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            for (var i = 0; i < sections.length; i++)
              sections[i]
                  .animate()
                  .fadeIn(duration: 380.ms, delay: (40 * i.clamp(0, 8)).ms)
                  .slideY(begin: 0.04, end: 0, duration: 380.ms, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.now});

  final DateTime now;

  String get _partOfDay {
    final h = now.hour;
    if (h < 5) return 'A peaceful night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'A peaceful night';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, Space.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppEmblem(size: 34, color: c.accent, accent: c.gold),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sakina', style: text.headlineMedium!.copyWith(height: 1.0)),
                const SizedBox(height: 4),
                Text('$_partOfDay  ·  ${Formatters.longDate(now)}', style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekGlance extends ConsumerWidget {
  const _WeekGlance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final series = ref.watch(activitySeriesProvider(StatsPeriod.week));
    return Padding(
      padding: Space.pagePadding,
      child: series.when(
        loading: () => const SizedBox(height: 150),
        error: (e, _) => Text('Could not load activity: $e'),
        data: (buckets) {
          final total = buckets.fold<int>(0, (a, b) => a + b.count);
          final active = buckets.where((b) => b.count > 0).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Formatters.count(total), style: text.headlineMedium),
                  const SizedBox(width: Space.xs),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('in the last 7 days · $active active', style: text.bodySmall),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              ActivityBarChart(
                buckets: buckets,
                height: 96,
                selectable: true,
                describe: (b) => '${Formatters.relativeDay(b.start, DateTime.now())}: ${Formatters.count(b.count)}',
              ),
            ],
          );
        },
      ),
    );
  }
}
