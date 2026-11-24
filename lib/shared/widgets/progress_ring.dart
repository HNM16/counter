import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// A thin, elegant progress ring. When [ticks] is set (and small enough),
/// the ring is drawn as discrete marks, one per repetition.
class ProgressRingPainter extends CustomPainter {
  const ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 6,
    this.ticks,
    this.glow = 0,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final int? ticks;

  /// 0..1 soft halo used for celebrations.
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - strokeWidth;
    final p = progress.clamp(0.0, 1.0);
    final t = ticks;

    if (glow > 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * (2 + 4 * glow)
          ..color = color.withValues(alpha: 0.18 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * glow),
      );
    }

    if (t != null && t > 1 && t <= 120) {
      final filled = (p * t).round();
      final len = strokeWidth * 2.2;
      for (var i = 0; i < t; i++) {
        final a = -math.pi / 2 + 2 * math.pi * i / t;
        final dir = Offset(math.cos(a), math.sin(a));
        final from = center + dir * (radius - len / 2);
        final to = center + dir * (radius + len / 2);
        canvas.drawLine(
          from,
          to,
          Paint()
            ..strokeWidth = math.max(1.5, strokeWidth * 0.45)
            ..strokeCap = StrokeCap.round
            ..color = i < filled ? color : trackColor,
        );
      }
      return;
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );
    if (p <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * p,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.ticks != ticks ||
      oldDelegate.glow != glow;
}

/// Animated wrapper around [ProgressRingPainter].
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    required this.trackColor,
    this.size = 120,
    this.strokeWidth = 6,
    this.ticks,
    this.child,
    this.duration = const Duration(milliseconds: 420),
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double size;
  final double strokeWidth;
  final int? ticks;
  final Widget? child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => CustomPaint(
          painter: ProgressRingPainter(
            progress: value,
            color: color,
            trackColor: trackColor,
            strokeWidth: strokeWidth,
            ticks: ticks,
          ),
          child: child,
        ),
        child: Center(child: child),
      ),
    );
  }
}
