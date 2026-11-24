import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../dhikr/presentation/dhikr_providers.dart';
import '../../../goals/domain/goal.dart';
import '../../../goals/presentation/goal_providers.dart';

/// Today's progress for each daily goal.
class GoalsOverview extends ConsumerWidget {
  const GoalsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final progress = ref.watch(goalProgressProvider);

    return progress.when(
      loading: () => const SizedBox(height: 60),
      error: (e, _) => Padding(padding: Space.pagePadding, child: Text('Could not load goals: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: Space.pagePadding,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Set a gentle daily target, such as 100 repetitions, and watch it fill up through the day.',
                    style: text.bodyMedium,
                  ),
                ),
                const SizedBox(width: Space.md),
                OutlinedButton(onPressed: () => context.push(Routes.goals), child: const Text('Add goal')),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (final p in items) GoalProgressRow(progress: p),
          ],
        );
      },
    );
  }
}

class GoalProgressRow extends ConsumerWidget {
  const GoalProgressRow({super.key, required this.progress, this.onTap, this.trailing});

  final GoalProgress progress;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final goal = progress.goal;
    final dhikr = goal.dhikrId == null ? null : ref.watch(dhikrByIdProvider(goal.dhikrId!));
    final title = goal.isOverall ? 'All dhikr' : (dhikr?.transliteration ?? 'Dhikr');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: 10),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
              child: Icon(
                progress.isComplete ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                key: ValueKey(progress.isComplete),
                color: progress.isComplete ? c.accent : c.hairline,
                size: 22,
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: text.titleSmall)),
                      Text(
                        '${Formatters.count(progress.current)} / ${Formatters.count(goal.target)}',
                        style: text.bodySmall!.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: progress.fraction),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 5,
                        color: progress.isComplete ? c.gold : c.accent,
                        backgroundColor: c.surfaceMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: Space.xs), trailing!],
          ],
        ),
      ),
    );
  }
}
