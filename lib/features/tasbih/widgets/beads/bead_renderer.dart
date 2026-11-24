import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import 'bead_spec.dart';

/// Procedurally paints realistic beads.
///
/// All shaders and texture paths are built once in unit space (a sphere of
/// radius 1 at the origin) and reused for every bead through canvas
/// transforms, so painting a 99-bead tasbih allocates nothing per frame.
///
/// Lighting is fixed (key light from the upper left) while surface texture
/// rotates with the string, the way a real bead turns on its thread.
class BeadRenderer {
  BeadRenderer(this.spec) {
    _build();
  }

  final BeadSpec spec;

  static const variants = 6;
  static const _light = Offset(-0.36, -0.44);

  late final Paint _contactShadow;
  late final Paint _body;
  late final Paint _bounce;
  late final Paint _rim;
  late final Paint _specular;
  late final Paint _glint;
  Paint? _glow;
  Paint? _iridescence;
  late final List<List<(Path, Paint)>> _textures;

  static final _unitCircle = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 1));

  void _build() {
    final s = spec;
    _contactShadow = Paint()
      ..shader = ui.Gradient.radial(
        const Offset(0.14, 0.30),
        1.3,
        [const Color(0x52000000), const Color(0x1F000000), const Color(0x00000000)],
        [0.45, 0.72, 1.0],
      );
    _body = Paint()
      ..shader = ui.Gradient.radial(
        _light,
        1.62,
        [s.highlight, s.base, s.shade, Color.lerp(s.shade, Colors.black, 0.35)!],
        [0.0, 0.40, 0.84, 1.0],
      );
    _bounce = Paint()
      ..shader = ui.Gradient.radial(
        const Offset(0.28, 0.66),
        0.62,
        [ColorTools.lighten(s.base, 0.10).withValues(alpha: 0.42), s.base.withValues(alpha: 0)],
      );
    _rim = Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        1.0,
        [const Color(0x00000000), Color.lerp(s.shade, Colors.black, 0.5)!.withValues(alpha: 0.42)],
        [0.74, 1.0],
      );
    _specular = Paint()
      ..shader = ui.Gradient.radial(
        _light,
        0.46,
        [Colors.white.withValues(alpha: 0.80 * s.gloss), Colors.white.withValues(alpha: 0)],
      );
    _glint = Paint()..color = Colors.white.withValues(alpha: s.gloss > 0.55 ? 0.9 * s.gloss : 0);

    if (s.translucency > 0) {
      _glow = Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0.30, 0.40),
          0.82,
          [ColorTools.lighten(s.highlight, 0.06).withValues(alpha: 0.65 * s.translucency), s.base.withValues(alpha: 0)],
        );
    }
    if (s.finish == BeadFinish.pearl) {
      _iridescence = Paint()
        ..blendMode = BlendMode.softLight
        ..shader = ui.Gradient.sweep(
          Offset.zero,
          const [Color(0x66F4C6D4), Color(0x66C6E7F4), Color(0x66E9F4C6), Color(0x66F4D8C6), Color(0x66F4C6D4)],
          null,
          TileMode.clamp,
        );
    }

    _textures = [for (var v = 0; v < variants; v++) _textureVariant(v)];
  }

  List<(Path, Paint)> _textureVariant(int v) {
    final rnd = math.Random(spec.seed * 101 + v * 7);
    final out = <(Path, Paint)>[];
    final tex = spec.texture;

    switch (spec.finish) {
      case BeadFinish.wood:
        // Long grain lines running along the drill axis, gently wavering.
        final lines = 7 + rnd.nextInt(3);
        for (var k = 0; k < lines; k++) {
          final y0 = -1.0 + (k + 0.5) * (2.0 / lines) + (rnd.nextDouble() - 0.5) * 0.12;
          final amp = 0.03 + rnd.nextDouble() * 0.07;
          final freq = 1.6 + rnd.nextDouble() * 2.2;
          final phase = rnd.nextDouble() * math.pi * 2;
          final path = Path();
          for (var i = 0; i <= 24; i++) {
            final x = -1.1 + i * (2.2 / 24);
            // Lines bow around the poles, as end grain does on a sphere.
            final bow = y0 * (1 - 0.18 * (1 - x * x));
            final y = bow + amp * math.sin(x * freq + phase);
            i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
          }
          out.add((
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.025 + rnd.nextDouble() * 0.05
              ..color = tex.withValues(alpha: 0.22 + rnd.nextDouble() * 0.22),
          ));
        }
        if (rnd.nextDouble() < 0.4) {
          final c = Offset(rnd.nextDouble() * 1.0 - 0.5, rnd.nextDouble() * 1.0 - 0.5);
          out.add((
            Path()..addOval(Rect.fromCenter(center: c, width: 0.34, height: 0.16)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.035
              ..color = tex.withValues(alpha: 0.35),
          ));
        }
      case BeadFinish.marble:
        for (var k = 0; k < 3; k++) {
          final path = _randomWalk(rnd, steps: 12, jitter: 0.22);
          out.add((
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.08 + rnd.nextDouble() * 0.06
              ..color = tex.withValues(alpha: 0.12)
              ..maskFilter = null,
          ));
          out.add((
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.014 + rnd.nextDouble() * 0.018
              ..color = tex.withValues(alpha: 0.5 + rnd.nextDouble() * 0.2),
          ));
        }
      case BeadFinish.stone:
        final isDark = spec.base.computeLuminance() < 0.05;
        if (isDark) {
          // Onyx: faint banding.
          for (var k = 0; k < 2; k++) {
            final r = 0.45 + k * 0.32 + rnd.nextDouble() * 0.08;
            out.add((
              Path()..addOval(Rect.fromCircle(center: Offset(rnd.nextDouble() * 0.4 - 0.2, 0.15), radius: r)),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.05
                ..color = tex.withValues(alpha: 0.10),
            ));
          }
        } else {
          // Turquoise: fine spider-web matrix veins.
          for (var k = 0; k < 4; k++) {
            out.add((
              _randomWalk(rnd, steps: 9, jitter: 0.35, short: true),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.02 + rnd.nextDouble() * 0.02
                ..strokeJoin = StrokeJoin.round
                ..color = tex.withValues(alpha: 0.42 + rnd.nextDouble() * 0.2),
            ));
          }
        }
      case BeadFinish.gem:
        // Soft internal clouds and inclusions.
        for (var k = 0; k < 3; k++) {
          final c = Offset(rnd.nextDouble() * 1.2 - 0.6, rnd.nextDouble() * 1.2 - 0.6);
          final r = 0.35 + rnd.nextDouble() * 0.35;
          out.add((
            Path()..addOval(Rect.fromCircle(center: c, radius: r)),
            Paint()
              ..shader = ui.Gradient.radial(c, r, [
                tex.withValues(alpha: 0.16 + rnd.nextDouble() * 0.1),
                tex.withValues(alpha: 0),
              ]),
          ));
        }
      case BeadFinish.pearl:
        final c = Offset(rnd.nextDouble() * 0.8 - 0.4, rnd.nextDouble() * 0.8 - 0.4);
        out.add((
          Path()..addOval(Rect.fromCircle(center: c, radius: 0.7)),
          Paint()
            ..shader = ui.Gradient.radial(c, 0.7, [tex.withValues(alpha: 0.22), tex.withValues(alpha: 0)]),
        ));
    }
    return out;
  }

  static Path _randomWalk(math.Random rnd, {required int steps, required double jitter, bool short = false}) {
    final path = Path();
    var x = -1.1;
    var y = rnd.nextDouble() * 1.6 - 0.8;
    if (short) {
      x = rnd.nextDouble() * 1.4 - 0.9;
    }
    path.moveTo(x, y);
    final stepLen = short ? 0.14 : 0.2;
    var angle = (rnd.nextDouble() - 0.5) * 0.9;
    for (var i = 0; i < steps; i++) {
      angle += (rnd.nextDouble() - 0.5) * jitter * 2;
      x += math.cos(angle) * stepLen;
      y += math.sin(angle) * stepLen;
      path.lineTo(x, y);
    }
    return path;
  }

  /// Paints a bead of radius [r] centered at [c]. [angle] is the string's
  /// direction at this point; [variant] picks one of the texture variations.
  void paintBead(Canvas canvas, Offset c, double r, double angle, int variant, {double lift = 0}) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(r);
    canvas.drawCircle(Offset(0, 0.05 + lift * 0.25), 1.18 + lift * 0.1, _contactShadow);
    _paintSphere(canvas, angle, variant);
    canvas.restore();
  }

  void _paintSphere(Canvas canvas, double angle, int variant) {
    canvas.drawCircle(Offset.zero, 1, _body);

    canvas.save();
    canvas.clipPath(_unitCircle);
    canvas.save();
    canvas.rotate(angle);
    for (final (path, paint) in _textures[variant % variants]) {
      canvas.drawPath(path, paint);
    }
    canvas.restore();
    final glow = _glow;
    if (glow != null) canvas.drawCircle(Offset.zero, 1, glow);
    final iri = _iridescence;
    if (iri != null) canvas.drawCircle(Offset.zero, 1, iri);
    canvas.drawCircle(Offset.zero, 1, _bounce);
    canvas.drawCircle(Offset.zero, 1, _rim);
    canvas.restore();

    // Broad soft highlight, slightly tilted, then a sharp glint.
    canvas.save();
    canvas.translate(_light.dx, _light.dy);
    canvas.rotate(-0.55);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 0.86, height: 0.5), _specular);
    canvas.restore();
    canvas.drawCircle(const Offset(-0.40, -0.48), 0.085, _glint);
  }

  /// The imam (head) bead: a larger bead capped with gold on both sides.
  void paintImam(Canvas canvas, Offset c, double r, double angle) {
    final rr = r * 1.24;
    canvas.save();
    canvas.translate(c.dx, c.dy);

    // Caps sit on the string axis, before and after the bead.
    canvas.save();
    canvas.rotate(angle);
    for (final side in const [-1.0, 1.0]) {
      final center = Offset(side * rr * 0.98, 0);
      final rect = Rect.fromCenter(center: center, width: rr * 0.42, height: rr * 0.92);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(rr * 0.18)), _goldPaint(rect));
    }
    canvas.restore();

    canvas.scale(rr);
    canvas.drawCircle(const Offset(0, 0.06), 1.18, _contactShadow);
    _paintSphere(canvas, angle, 0);
    canvas.restore();
  }

  /// A flat metal spacer separating thirds of a 99-bead tasbih.
  void paintSeparator(Canvas canvas, Offset c, double r, double angle) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final rect = Rect.fromCenter(center: Offset.zero, width: r * 0.7, height: r * 1.7);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(Offset(r * 0.08, r * 0.14)), Radius.circular(r * 0.3)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r * 0.3)), _goldPaint(rect));
    canvas.restore();
  }

  static Paint _goldPaint(Rect rect) => Paint()
    ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, const [
      Color(0xFFF3E2B5),
      Color(0xFFC9AE76),
      Color(0xFF8A6D36),
      Color(0xFFD9C08A),
    ], const [0.0, 0.38, 0.72, 1.0]);
}

/// The tassel hanging from the imam bead. Always hangs with gravity; [sway]
/// (radians) lets it swing when the loop moves.
class TasselPainter {
  const TasselPainter();

  static const _thread = [Color(0xFFD8C08C), Color(0xFFB79A5F), Color(0xFFE6D3A6), Color(0xFFA88B52)];

  void paint(Canvas canvas, Offset anchor, double scale, {double sway = 0}) {
    final s = scale;
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(sway);

    // Cord from the bead down to the cap.
    canvas.drawLine(
      Offset.zero,
      Offset(0, s * 0.9),
      Paint()
        ..color = const Color(0xFF9C7F45)
        ..strokeWidth = math.max(1.0, s * 0.1),
    );

    // Cap.
    final cap = Path()
      ..moveTo(-s * 0.28, s * 0.9)
      ..quadraticBezierTo(0, s * 0.55, s * 0.28, s * 0.9)
      ..lineTo(s * 0.38, s * 1.6)
      ..lineTo(-s * 0.38, s * 1.6)
      ..close();
    final capRect = Rect.fromLTRB(-s * 0.4, s * 0.6, s * 0.4, s * 1.6);
    canvas.drawPath(cap, BeadRenderer._goldPaint(capRect));

    // Fringe.
    const strands = 17;
    final length = s * 3.4;
    final top = s * 1.55;
    for (var i = 0; i < strands; i++) {
      final t = i / (strands - 1) - 0.5;
      final start = Offset(t * s * 0.66, top);
      final end = Offset(t * s * 1.35 - sway * s * 0.9, top + length * (0.93 + 0.07 * math.cos(i * 1.7)));
      final ctrl = Offset(t * s * 0.9 - sway * s * 0.4, top + length * 0.5);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(0.8, s * 0.075)
          ..color = _thread[i % _thread.length],
      );
    }
    // Binding band.
    final band = Rect.fromCenter(center: Offset(0, top + s * 0.35), width: s * 0.82, height: s * 0.22);
    canvas.drawRRect(RRect.fromRectAndRadius(band, Radius.circular(s * 0.08)), BeadRenderer._goldPaint(band));
    canvas.restore();
  }
}
