import 'package:material_ui/material_ui.dart';

/// Seven-segment LCD digits, drawn as vector shapes. Unlit segments are
/// shown as faint "ghost" segments like a real LCD panel.
class SevenSegmentDisplay extends StatelessWidget {
  const SevenSegmentDisplay({
    super.key,
    required this.value,
    required this.digits,
    required this.ink,
    this.height = 64,
  });

  final int value;
  final int digits;
  final Color ink;
  final double height;

  @override
  Widget build(BuildContext context) {
    final width = height * 0.56;
    final text = value.toString();
    final padded = text.length >= digits ? text.substring(text.length - digits) : text.padLeft(digits);
    return Semantics(
      label: '$value',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final ch in padded.split(''))
            Padding(
              padding: EdgeInsets.symmetric(horizontal: height * 0.05),
              child: CustomPaint(
                size: Size(width, height),
                painter: _DigitPainter(ch == ' ' ? null : int.parse(ch), ink),
              ),
            ),
        ],
      ),
    );
  }
}

class _DigitPainter extends CustomPainter {
  const _DigitPainter(this.digit, this.ink);

  final int? digit;
  final Color ink;

  // Segments: a (top), b (top right), c (bottom right), d (bottom),
  // e (bottom left), f (top left), g (middle).
  static const _map = <int, String>{
    0: 'abcdef',
    1: 'bc',
    2: 'abged',
    3: 'abgcd',
    4: 'fgbc',
    5: 'afgcd',
    6: 'afgedc',
    7: 'abc',
    8: 'abcdefg',
    9: 'abcdfg',
  };

  @override
  void paint(Canvas canvas, Size size) {
    final on = digit == null ? '' : _map[digit]!;
    final w = size.width;
    final h = size.height;
    final t = w * 0.17; // segment thickness
    final skew = w * 0.08;

    Path horizontal(double y) {
      final x0 = t * 0.55;
      final x1 = w - t * 0.55;
      return Path()
        ..moveTo(x0, y)
        ..lineTo(x0 + t / 2, y - t / 2)
        ..lineTo(x1 - t / 2, y - t / 2)
        ..lineTo(x1, y)
        ..lineTo(x1 - t / 2, y + t / 2)
        ..lineTo(x0 + t / 2, y + t / 2)
        ..close();
    }

    Path vertical(double x, double y0, double y1) {
      final a = y0 + t * 0.55;
      final b = y1 - t * 0.55;
      return Path()
        ..moveTo(x, a)
        ..lineTo(x + t / 2, a + t / 2)
        ..lineTo(x + t / 2, b - t / 2)
        ..lineTo(x, b)
        ..lineTo(x - t / 2, b - t / 2)
        ..lineTo(x - t / 2, a + t / 2)
        ..close();
    }

    final mid = h / 2;
    final segments = <String, Path>{
      'a': horizontal(t / 2),
      'g': horizontal(mid),
      'd': horizontal(h - t / 2),
      'f': vertical(t / 2, t / 2, mid),
      'b': vertical(w - t / 2, t / 2, mid),
      'e': vertical(t / 2, mid, h - t / 2),
      'c': vertical(w - t / 2, mid, h - t / 2),
    };

    canvas.save();
    // A slight italic slant, as on real LCD counters.
    canvas.transform(Matrix4.skewX(-skew / h).storage);
    canvas.translate(skew * 0.5, 0);
    final lit = Paint()..color = ink;
    final ghost = Paint()..color = ink.withValues(alpha: 0.08);
    segments.forEach((name, path) => canvas.drawPath(path, on.contains(name) ? lit : ghost));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DigitPainter oldDelegate) => oldDelegate.digit != digit || oldDelegate.ink != ink;
}
