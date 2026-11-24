import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/common.dart';
import '../../../../shared/widgets/geometric_pattern.dart';
import '../../../../shared/widgets/progress_ring.dart';
import '../../../dhikr/presentation/dhikr_providers.dart';
import '../../../goals/domain/goal.dart';
import '../../../goals/presentation/goal_providers.dart';
import '../../../statistics/presentation/stats_providers.dart';
import '../../../tasbih/presentation/tasbih_controller.dart';

/// The single hero block of the home screen: today's progress and the
/// primary "Start Tasbih" action.
class DailyHero extends ConsumerWidget {
  const DailyHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayTotalProvider).value ?? 0;
    final streak = ref.watch(streaksProvider).value?.current ?? 0;
    final progress = ref.watch(goalProgressProvider).value ?? const <GoalProgress>[];
    final overall = GoalProgress.overall(progress);
    final completed = progress.where((p) => p.isComplete).length;
    final session = ref.watch(tasbihControllerProvider).value?.session;
    final dhikr = session == null ? null : ref.watch(dhikrByIdProvider(session.dhikrId));

    final heroBg = c.isDark ? c.surfaceMuted : AppPalette.forest;
    const onHero = Color(0xFFF4EFE4);
    const onHeroSoft = Color(0xFFA9C2B7);

    String goalLine;
    if (progress.isEmpty) {
      goalLine = 'No daily goal set';
    } else if (completed == progress.length) {
      goalLine = progress.length == 1 ? 'Daily goal complete' : 'All ${progress.length} goals complete';
    } else {
      goalLine = '$completed of ${progress.length} goals complete';
    }

    final hasSession = session != null && session.totalCount > 0;
    final buttonLabel = hasSession ? 'Continue Tasbih' : 'Start Tasbih';
    final buttonDetail = session == null
        ? null
        : hasSession
        ? '${dhikr?.transliteration ?? session.dhikrLabel}  ·  ${session.displayCount}/${session.target}'
        : dhikr?.transliteration ?? session.dhikrLabel;

    return Padding(
      padding: Space.pagePadding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Container(
          color: heroBg,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: GeometricPatternPainter(color: AppPalette.gold.withValues(alpha: 0.07))),
              ),
              Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProgressRing(
                          progress: progress.isEmpty ? 0 : overall,
                          color: AppPalette.gold,
                          trackColor: Colors.white.withValues(alpha: 0.12),
                          size: 104,
                          strokeWidth: 5,
                          child: Text(
                            progress.isEmpty ? '-' : '${(overall * 100).round()}%',
                            style: const TextStyle(
                              fontFamily: AppFonts.serif,
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                              color: onHero,
                            ),
                          ),
                        ),
                        const SizedBox(width: Space.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TODAY', style: text.labelSmall!.copyWith(color: onHeroSoft)),
                              const SizedBox(height: 2),
                              Text(
                                Formatters.count(today),
                                style: text.displaySmall!.copyWith(color: onHero, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                today == 1 ? 'repetition' : 'repetitions',
                                style: text.bodySmall!.copyWith(color: onHeroSoft),
                              ),
                              const SizedBox(height: Space.xs),
                              Text(goalLine, style: text.bodySmall!.copyWith(color: onHero)),
                              if (streak > 0)
                                Text(
                                  '$streak-day streak',
                                  style: text.bodySmall!.copyWith(color: AppPalette.gold, fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.lg),
                    Pressable(
                      onTap: () => context.go(Routes.tasbih),
                      semanticLabel: buttonLabel,
                      child: Container(
                        height: 58,
                        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                        decoration: BoxDecoration(
                          color: AppPalette.ivory,
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(buttonLabel, style: text.labelLarge!.copyWith(color: AppPalette.forest)),
                                  if (buttonDetail != null)
                                    Text(
                                      buttonDetail,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.bodySmall!.copyWith(color: AppPalette.inkSoft, height: 1.3),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded, color: AppPalette.forest),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
