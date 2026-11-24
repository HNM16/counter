import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../settings/domain/app_settings.dart';
import '../../domain/bead_loop.dart';
import 'bead_renderer.dart';
import 'loop_geometry.dart';
import 'tasbih_backdrop.dart';

/// Keeps the (relatively expensive) string geometry across repaints and
/// widget rebuilds; it only changes with size or configuration.
class LoopGeometryCache {
  Object? key;
  LoopGeometry? geometry;
}

/// Paints the whole tasbih: string, beads, separators, imam bead, tassel and
/// (for the ring) the round progress arc.
class TasbihLoopPainter extends CustomPainter {
  TasbihLoopPainter({
    required this.loop,
    required this.cursor,
    required this.progress,
    required this.renderer,
    required this.style,
    required this.beadScale,
    required this.backdrop,
    required this.velocity,
    required this.cache,
  }) : super(repaint: Listenable.merge([cursor, progress]));

  final BeadLoop loop;
  final Animation<double> cursor;
  final Animation<double> progress;
  final BeadRenderer renderer;
  final TasbihStyle style;
  final double beadScale;
  final BackdropStyle backdrop;
  final double Function() velocity;
  final LoopGeometryCache cache;

  static const _tassel = TasselPainter();

  /// Ring radius for a given layout size; shared with the center label.
  static double ringRadius(Size size) => math.min(size.width, size.height) / 2 * 0.76;

  /// Bare string at the top of the ring, in slots. Small beads need a wider
  /// gap to read clearly.
  static double ringGapSlots(BeadLoop loop) => loop.beadCount > 40 ? 5 : 1.9;

  /// Bead-to-slot ratio: how much of each slot a bead fills.
  double get _fill => (0.46 * beadScale).clamp(0.36, 0.52);

  LoopGeometry _geometryFor(Size size) {
    final key = (size, style, loop.length, beadScale);
    final cached = cache.geometry;
    if (cached != null && cache.key == key) return cached;
    cache.key = key;
    return cache.geometry = switch (style) {
      TasbihStyle.ring => RingGeometry(
        center: Offset(size.width / 2, size.height / 2),
        radius: ringRadius(size),
        slots: loop.length,
        gapSlots: ringGapSlots(loop),
        beadFill: _fill,
      ),
      TasbihStyle.strand => StrandGeometry(
        size: size,
        slot: (math.min(size.width, size.height) * 0.075).clamp(22.0, 40.0) * beadScale,
        slots: loop.length,
        beadFill: 0.46,
      ),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = _geometryFor(size);
    final c = cursor.value;
    final r = g.beadRadius;

    if (style == TasbihStyle.ring) _paintProgress(canvas, size, g as RingGeometry);

    g.paintString(
      canvas,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.1, r * 0.13)
        ..color = backdrop.thread.withValues(alpha: 0.85),
    );

    final bounds = (Offset.zero & size).inflate(r * 6);
    Offset? imamPos;
    double imamAngle = 0;
    int? transit;
    Offset? transitPos;
    double transitAngle = 0;

    for (var i = 0; i < loop.length; i++) {
      final rel = loop.relativeSlot(i, c);
      final s = BeadLoop.distanceFor(rel, anchor: g.anchor, slot: g.slot, gap: g.gap);
      final (p, a) = g.at(s);
      if (!bounds.contains(p)) continue;
      final kind = loop.items[i];
      if (kind == LoopItemKind.imam) {
        imamPos = p;
        imamAngle = a;
        continue;
      }
      if (rel < 0 && rel > -1 && kind == LoopItemKind.bead) {
        transit = i;
        transitPos = p;
        transitAngle = a;
        continue;
      }
      _paintItem(canvas, kind, p, r, a, i);
    }

    // The bead in transit lifts slightly off the string and is drawn on top.
    if (transit != null) {
      final rel = loop.relativeSlot(transit, c);
      final lift = math.sin(-rel * math.pi);
      renderer.paintBead(canvas, transitPos!, r * (1 + 0.05 * lift), transitAngle, transit, lift: lift);
    }

    if (imamPos != null) {
      renderer.paintImam(canvas, imamPos, r, imamAngle);
      final sway = (velocity() * -0.05).clamp(-0.45, 0.45);
      _tassel.paint(canvas, imamPos + Offset(0, r * 1.15), math.max(r, 7.0), sway: sway);
    }
  }

  void _paintItem(Canvas canvas, LoopItemKind kind, Offset p, double r, double a, int i) {
    switch (kind) {
      case LoopItemKind.bead:
        renderer.paintBead(canvas, p, r, a, i);
      case LoopItemKind.separator:
        renderer.paintSeparator(canvas, p, r, a);
      case LoopItemKind.imam:
        renderer.paintImam(canvas, p, r, a);
    }
  }

  void _paintProgress(Canvas canvas, Size size, RingGeometry g) {
    final radius = g.radius + g.beadRadius + 12;
    final center = g.center;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = backdrop.track,
    );
    final p = progress.value.clamp(0.0, 1.0);
    if (p <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * p,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = backdrop.progress,
    );
    final end = -math.pi / 2 + 2 * math.pi * p;
    canvas.drawCircle(
      Offset(center.dx + radius * math.cos(end), center.dy + radius * math.sin(end)),
      4,
      Paint()..color = backdrop.progress,
    );
  }

  @override
  bool shouldRepaint(TasbihLoopPainter oldDelegate) =>
      oldDelegate.loop != loop ||
      oldDelegate.renderer != renderer ||
      oldDelegate.style != style ||
      oldDelegate.beadScale != beadScale ||
      oldDelegate.backdrop != backdrop ||
      oldDelegate.cursor != cursor;
}
