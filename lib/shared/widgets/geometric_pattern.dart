import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Eight-pointed star (two overlapping squares), the classic motif of
/// Islamic geometric art.
abstract final class StarGeometry {
  /// Star outline with outer radius [r] centered on [c].
  static Path eightPointStar(Offset c, double r, {double rotation = 0}) {
    final inner = r * math.cos(math.pi / 4) / math.cos(math.pi / 8);
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final radius = i.isEven ? r : inner;
      final a = rotation - math.pi / 2 + i * math.pi / 8;
      final p = Offset(c.dx + radius * math.cos(a), c.dy + radius * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }
}

/// Subtle star-and-cross lattice used for backgrounds and headers.
class GeometricPatternPainter extends CustomPainter {
  const GeometricPatternPainter({required this.color, this.tile = 56, this.strokeWidth = 1});

  final Color color;
  final double tile;
  final double strokeWidth;

  static void paintLattice(Canvas canvas, Size size, {required Color color, double tile = 56, double strokeWidth = 1}) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    final r = tile * 0.34;
    final cols = (size.width / tile).ceil() + 1;
    final rows = (size.height / tile).ceil() + 1;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final c = Offset(x * tile, y * tile);
        canvas.drawPath(StarGeometry.eightPointStar(c, r), paint);
        // Diamond joining the neighbouring stars forms the "cross" spaces.
        final m = Offset(c.dx + tile / 2, c.dy + tile / 2);
        final d = tile * 0.16;
        canvas.drawPath(
          Path()
            ..moveTo(m.dx, m.dy - d)
            ..lineTo(m.dx + d, m.dy)
            ..lineTo(m.dx, m.dy + d)
            ..lineTo(m.dx - d, m.dy)
            ..close(),
          paint,
        );
        canvas.drawLine(Offset(c.dx + r, c.dy), Offset(c.dx + tile - r, c.dy), paint);
        canvas.drawLine(Offset(c.dx, c.dy + r), Offset(c.dx, c.dy + tile - r), paint);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintLattice(canvas, size, color: color, tile: tile, strokeWidth: strokeWidth);
  }

  @override
  bool shouldRepaint(GeometricPatternPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.tile != tile || oldDelegate.strokeWidth != strokeWidth;
}

/// The app emblem: an eight-pointed star framing a small circle.
class AppEmblem extends StatelessWidget {
  const AppEmblem({super.key, this.size = 36, required this.color, required this.accent});

  final double size;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _EmblemPainter(color, accent)),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter(this.color, this.accent);

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawPath(StarGeometry.eightPointStar(c, r), Paint()..color = color);
    canvas.drawPath(
      StarGeometry.eightPointStar(c, r * 0.72, rotation: math.pi / 8),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..color = accent,
    );
    canvas.drawCircle(c, r * 0.2, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_EmblemPainter oldDelegate) => oldDelegate.color != color || oldDelegate.accent != accent;
}
