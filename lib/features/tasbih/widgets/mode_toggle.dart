import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../settings/domain/app_settings.dart';

/// Pill-shaped switch between the bead tasbih and the digital counter.
class ModeToggle extends StatelessWidget {
  const ModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
    required this.foreground,
    required this.secondary,
  });

  final CounterMode mode;
  final ValueChanged<CounterMode> onChanged;
  final Color foreground;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium!;
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: foreground.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in CounterMode.values)
            Semantics(
              selected: m == mode,
              button: true,
              label: '${m.label} mode',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => onChanged(m),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: Motion.medium,
                  curve: Motion.emphasized,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: m == mode ? foreground.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      m == CounterMode.beads
                          ? BeadsGlyph(color: m == mode ? foreground : secondary, size: 16)
                          : Icon(Icons.onetwothree_rounded, size: 20, color: m == mode ? foreground : secondary),
                      const SizedBox(width: 6),
                      Text(
                        m.label,
                        style: style.copyWith(
                          color: m == mode ? foreground : secondary,
                          fontWeight: m == mode ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small icon of beads on an arc, used for the bead tasbih.
class BeadsGlyph extends StatelessWidget {
  const BeadsGlyph({super.key, required this.color, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: size, child: CustomPaint(painter: _BeadsGlyphPainter(color)));
}

class _BeadsGlyphPainter extends CustomPainter {
  const _BeadsGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height * 0.42);
    final radius = s * 0.36;
    final string = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.06
      ..color = color.withValues(alpha: 0.6);
    canvas.drawCircle(center, radius, string);
    final fill = Paint()..color = color;
    for (var i = 0; i < 7; i++) {
      final a = math.pi * 0.62 + i * (math.pi * 1.76 / 6);
      canvas.drawCircle(center + Offset(math.cos(a), math.sin(a)) * radius, s * 0.105, fill);
    }
    // Imam bead and tassel at the bottom.
    final bottom = center + Offset(0, radius);
    canvas.drawCircle(bottom, s * 0.12, fill);
    canvas.drawLine(bottom, bottom + Offset(0, s * 0.3), string..strokeWidth = s * 0.08);
  }

  @override
  bool shouldRepaint(_BeadsGlyphPainter oldDelegate) => oldDelegate.color != color;
}
