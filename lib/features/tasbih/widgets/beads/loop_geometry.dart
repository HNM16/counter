import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Maps a distance along the tasbih string to a point and direction on screen.
abstract class LoopGeometry {
  /// Slot length (distance between bead centers).
  double get slot;

  /// Bare string between the waiting beads and the counted beads.
  double get gap;

  /// Where the next bead to be counted rests.
  double get anchor;

  double get beadRadius;

  /// Position and tangent angle at distance [s].
  (Offset, double) at(double s);

  void paintString(Canvas canvas, Paint paint);
}

/// A closed circular loop. Its circumference is exactly the beads plus the
/// gap, so beads flow continuously around it with no seam.
class RingGeometry implements LoopGeometry {
  RingGeometry({
    required this.center,
    required this.radius,
    required int slots,
    required double gapSlots,
    required double beadFill,
  }) : slot = 2 * math.pi * radius / (slots + gapSlots) {
    gap = gapSlots * slot;
    anchor = -(gap + slot) / 2;
    beadRadius = slot * beadFill;
  }

  final Offset center;
  final double radius;

  @override
  final double slot;
  @override
  late final double gap;
  @override
  late final double anchor;
  @override
  late final double beadRadius;

  @override
  (Offset, double) at(double s) {
    final a = -math.pi / 2 + s / radius;
    return (Offset(center.dx + radius * math.cos(a), center.dy + radius * math.sin(a)), a + math.pi / 2);
  }

  @override
  void paintString(Canvas canvas, Paint paint) => canvas.drawCircle(center, radius, paint);
}

/// A long hanging strand that sways gently across the screen. It extends far
/// beyond the visible area so the loop's seam is never seen.
class StrandGeometry implements LoopGeometry {
  StrandGeometry({required Size size, required this.slot, required int slots, required double beadFill}) {
    beadRadius = slot * beadFill;
    final extra = (slots / 2 + 4) * slot;
    final cx = size.width * 0.58;
    final amp = size.width * 0.09;
    final wave = size.height * 1.7;
    final anchorY = size.height * 0.34;
    gap = size.height * 0.2;

    double xAt(double y) => cx + amp * math.sin(2 * math.pi * (y - size.height * 0.15) / wave);

    const step = 4.0;
    var total = 0.0;
    Offset? prev;
    for (var y = -extra; y <= size.height + extra; y += step) {
      final p = Offset(xAt(y), y);
      if (prev != null) total += (p - prev).distance;
      if (y <= anchorY) anchor = total;
      _points.add(p);
      _lengths.add(total);
      prev = p;
    }
    _path = Path()..addPolygon(_points, false);
  }

  final _points = <Offset>[];
  final _lengths = <double>[];
  late final Path _path;

  @override
  final double slot;
  @override
  late final double gap;
  @override
  double anchor = 0;
  @override
  late final double beadRadius;

  @override
  (Offset, double) at(double s) {
    final clamped = s.clamp(0.0, _lengths.last);
    var lo = 0;
    var hi = _lengths.length - 1;
    while (lo < hi - 1) {
      final mid = (lo + hi) >> 1;
      if (_lengths[mid] <= clamped) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final a = _points[lo];
    final b = _points[hi];
    final segment = _lengths[hi] - _lengths[lo];
    final t = segment == 0 ? 0.0 : (clamped - _lengths[lo]) / segment;
    final p = Offset.lerp(a, b, t)!;
    final d = b - a;
    return (p, math.atan2(d.dy, d.dx));
  }

  @override
  void paintString(Canvas canvas, Paint paint) => canvas.drawPath(_path, paint);
}
