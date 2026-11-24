import 'dart:math' as math;

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/geometric_pattern.dart';
import '../../dhikr/presentation/dhikr_providers.dart';
import 'tasbih_controller.dart';

/// Listens for round and goal events and plays a short, non-blocking
/// celebration on top of the counter.
class CelebrationOverlay extends ConsumerStatefulWidget {
  const CelebrationOverlay({super.key, required this.foreground, required this.accent});

  final Color foreground;
  final Color accent;

  @override
  ConsumerState<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends ConsumerState<CelebrationOverlay> {
  TasbihEvent? _event;
  int _lastSerial = 0;

  @override
  void initState() {
    super.initState();
    _lastSerial = ref.read(tasbihControllerProvider).value?.event?.serial ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tasbihControllerProvider.select((s) => s.value?.event), (_, next) {
      if (next == null || next.serial <= _lastSerial) return;
      _lastSerial = next.serial;
      setState(() => _event = next);
    });

    final e = _event;
    if (e == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: switch (e.kind) {
        TasbihEventKind.roundCompleted => _RoundBurst(
          key: ValueKey(e.serial),
          round: e.round,
          color: widget.accent,
          foreground: widget.foreground,
        ),
        TasbihEventKind.goalReached => _GoalCard(key: ValueKey(e.serial), event: e, accent: widget.accent),
      },
    );
  }
}

class _RoundBurst extends StatelessWidget {
  const _RoundBurst({super.key, required this.round, required this.color, required this.foreground});

  final int round;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Stack(
      children: [
        Center(
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          )
              .animate()
              .scale(begin: const Offset(0.6, 0.6), end: const Offset(1.6, 1.6), duration: 900.ms, curve: Curves.easeOut)
              .fadeOut(duration: 900.ms, curve: Curves.easeIn),
        ),
        Align(
          alignment: const Alignment(0, -0.92),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Round $round complete',
              style: text.labelLarge!.copyWith(color: foreground),
            ),
          )
              .animate()
              .fadeIn(duration: 220.ms)
              .slideY(begin: -0.4, end: 0, duration: 320.ms, curve: Curves.easeOutCubic)
              .then(delay: 1400.ms)
              .fadeOut(duration: 400.ms),
        ),
      ],
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({super.key, required this.event, required this.accent});

  final TasbihEvent event;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final goal = event.goal!;
    final dhikr = goal.dhikrId == null ? null : ref.watch(dhikrByIdProvider(goal.dhikrId!));
    final subject = dhikr?.transliteration ?? 'dhikr';

    return Center(
      child: Container(
        width: 280,
        padding: const EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.xl, Space.lg),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 12))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: CustomPaint(painter: _StarPainter(c.gold)),
            ).animate().rotate(begin: -0.1, end: 0, duration: 900.ms, curve: Curves.easeOutBack).scale(
              begin: const Offset(0.4, 0.4),
              duration: 600.ms,
              curve: Curves.easeOutBack,
            ),
            const SizedBox(height: Space.md),
            Text('Daily goal reached', style: text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: Space.xxs),
            Text(
              '${Formatters.count(goal.target)} $subject today',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 260.ms)
          .scale(begin: const Offset(0.92, 0.92), duration: 360.ms, curve: Curves.easeOutCubic)
          .then(delay: 2200.ms)
          .fadeOut(duration: 450.ms)
          .scale(end: const Offset(0.96, 0.96), duration: 450.ms),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawPath(StarGeometry.eightPointStar(c, r), Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawPath(
      StarGeometry.eightPointStar(c, r * 0.78, rotation: math.pi / 8),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
    final check = Path()
      ..moveTo(c.dx - r * 0.26, c.dy + r * 0.02)
      ..lineTo(c.dx - r * 0.06, c.dy + r * 0.22)
      ..lineTo(c.dx + r * 0.3, c.dy - r * 0.2);
    canvas.drawPath(
      check,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.color != color;
}
