import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/geometric_pattern.dart';
import '../../../settings/domain/app_settings.dart';

/// Colors that sit on top of a bead backdrop.
@immutable
class BackdropStyle {
  const BackdropStyle({
    required this.base,
    required this.foreground,
    required this.secondary,
    required this.thread,
    required this.progress,
    required this.track,
    required this.isDark,
  });

  final Color base;
  final Color foreground;
  final Color secondary;
  final Color thread;
  final Color progress;
  final Color track;
  final bool isDark;

  factory BackdropStyle.of(TasbihBackground bg) => switch (bg) {
    TasbihBackground.ivory => const BackdropStyle(
      base: AppPalette.ivory,
      foreground: AppPalette.ink,
      secondary: AppPalette.inkSoft,
      thread: Color(0xFF6E5A43),
      progress: Color(0xFFA8894E),
      track: Color(0xFFE6DFD2),
      isDark: false,
    ),
    TasbihBackground.linen => const BackdropStyle(
      base: Color(0xFFEDE5D8),
      foreground: Color(0xFF2E261D),
      secondary: Color(0xFF6D6152),
      thread: Color(0xFF5E4A35),
      progress: Color(0xFF8A6A3B),
      track: Color(0xFFDCD1BF),
      isDark: false,
    ),
    TasbihBackground.geometric => const BackdropStyle(
      base: Color(0xFFF7F4EE),
      foreground: AppPalette.forest,
      secondary: Color(0xFF52665D),
      thread: Color(0xFF6E5A43),
      progress: AppPalette.emerald,
      track: Color(0xFFE3DDD0),
      isDark: false,
    ),
    TasbihBackground.forest => const BackdropStyle(
      base: AppPalette.forest,
      foreground: Color(0xFFF3EEE3),
      secondary: Color(0xFFA9BFB5),
      thread: Color(0xFFC9AE76),
      progress: AppPalette.gold,
      track: Color(0xFF1C5244),
      isDark: true,
    ),
    TasbihBackground.night => const BackdropStyle(
      base: Color(0xFF0B0F0D),
      foreground: Color(0xFFEDE8DF),
      secondary: Color(0xFF8E9993),
      thread: Color(0xFFB59B66),
      progress: AppPalette.gold,
      track: Color(0xFF1E2622),
      isDark: true,
    ),
  };
}

class TasbihBackdropPainter extends CustomPainter {
  const TasbihBackdropPainter(this.background);

  final TasbihBackground background;

  @override
  void paint(Canvas canvas, Size size) {
    final style = BackdropStyle.of(background);
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = style.base);
    final center = Offset(size.width / 2, size.height * 0.45);
    final radius = math.max(size.width, size.height) * 0.75;

    switch (background) {
      case TasbihBackground.ivory:
        canvas.drawRect(
          rect,
          Paint()
            ..shader = ui.Gradient.radial(center, radius, [
              const Color(0x00000000),
              const Color(0x14A8894E),
            ], [0.55, 1.0]),
        );
      case TasbihBackground.linen:
        final weave = Paint()
          ..strokeWidth = 0.6
          ..color = const Color(0x0F5E4A35);
        for (double y = 0; y < size.height; y += 3) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), weave);
        }
        final warp = Paint()
          ..strokeWidth = 0.6
          ..color = const Color(0x0A5E4A35);
        for (double x = 0; x < size.width; x += 3) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), warp);
        }
        canvas.drawRect(
          rect,
          Paint()
            ..shader = ui.Gradient.radial(center, radius, [
              const Color(0x00000000),
              const Color(0x1A5E4A35),
            ], [0.5, 1.0]),
        );
      case TasbihBackground.geometric:
        GeometricPatternPainter.paintLattice(
          canvas,
          size,
          color: const Color(0x1A176B50),
          tile: 64,
        );
      case TasbihBackground.forest:
        canvas.drawRect(
          rect,
          Paint()
            ..shader = ui.Gradient.radial(center, radius, [
              const Color(0xFF17503F),
              AppPalette.forest,
              const Color(0xFF0A2B22),
            ], [0.0, 0.55, 1.0]),
        );
      case TasbihBackground.night:
        GeometricPatternPainter.paintLattice(canvas, size, color: const Color(0x0FC9AE76), tile: 72);
        canvas.drawRect(
          rect,
          Paint()
            ..shader = ui.Gradient.radial(center, radius, [
              const Color(0x00000000),
              const Color(0x99000000),
            ], [0.45, 1.0]),
        );
    }
  }

  @override
  bool shouldRepaint(TasbihBackdropPainter oldDelegate) => oldDelegate.background != background;
}
