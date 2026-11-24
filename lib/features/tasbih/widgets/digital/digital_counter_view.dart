import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/progress_ring.dart';
import '../../../../shared/widgets/rolling_number.dart';
import '../../../settings/domain/app_settings.dart';
import 'digital_palette.dart';
import 'seven_segment.dart';

/// The minimal digital counter in one of three layouts. The whole surface is
/// the touch target; the visible button echoes every count with a press.
class DigitalCounterView extends StatefulWidget {
  const DigitalCounterView({
    super.key,
    required this.layout,
    required this.palette,
    required this.totalCount,
    required this.target,
    this.onCount,
    this.paused = false,
  });

  final DigitalLayout layout;
  final DigitalPalette palette;
  final int totalCount;
  final int target;
  final VoidCallback? onCount;
  final bool paused;

  @override
  State<DigitalCounterView> createState() => _DigitalCounterViewState();
}

class _DigitalCounterViewState extends State<DigitalCounterView> with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 220),
  );

  int get _display {
    final t = widget.target;
    final total = widget.totalCount;
    return total > 0 && total % t == 0 ? t : total % t;
  }

  int get _round => widget.totalCount > 0 && widget.totalCount % widget.target == 0
      ? widget.totalCount ~/ widget.target
      : widget.totalCount ~/ widget.target + 1;

  @override
  void didUpdateWidget(DigitalCounterView old) {
    super.didUpdateWidget(old);
    if (widget.totalCount > old.totalCount) {
      _press.forward(from: 0).then((_) {
        if (mounted) _press.reverse();
      });
    }
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return switch (widget.layout) {
          DigitalLayout.ring => _ringLayout(context, size),
          DigitalLayout.classic => _classicLayout(context, size),
          DigitalLayout.device => _deviceLayout(context, size),
        };
      },
    );
    if (widget.onCount == null) return IgnorePointer(child: content);
    return Semantics(
      button: true,
      label: 'Counter. Tap to count.',
      value: '$_display of ${widget.target}',
      onTap: widget.onCount,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onCount,
        onTapDown: (_) => _press.forward(),
        onTapCancel: () => _press.reverse(),
        child: content,
      ),
    );
  }

  TextStyle _numberStyle(double size) => TextStyle(
    fontFamily: AppFonts.serif,
    fontWeight: FontWeight.w300,
    fontSize: size,
    height: 1,
    color: widget.palette.text,
  );

  TextStyle get _caption => Theme.of(
    context,
  ).textTheme.labelMedium!.copyWith(color: widget.palette.subtext, letterSpacing: 0.8, fontWeight: FontWeight.w600);

  /// Round info lives in the screen footer; here we only surface "paused".
  Widget _status() => AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: widget.paused
        ? Text('PAUSED', key: const ValueKey('p'), style: _caption.copyWith(color: widget.palette.accent))
        : SizedBox(key: const ValueKey('r'), height: _caption.fontSize! * 1.3),
  );

  // ------------------------------------------------------------------ ring

  Widget _ringLayout(BuildContext context, Size size) {
    final p = widget.palette;
    final d = math.min(size.width * 0.84, size.height * 0.86);
    return Center(
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, child) => Transform.scale(scale: 1 - 0.015 * _press.value, child: child),
        child: ProgressRing(
          progress: _display / widget.target,
          color: p.accent,
          trackColor: p.track,
          size: d,
          strokeWidth: d * 0.018,
          ticks: widget.target <= 100 ? widget.target : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RollingNumber(value: _display, style: _numberStyle(d * 0.3)),
              const SizedBox(height: 4),
              Text('of ${widget.target}', style: _caption),
              const SizedBox(height: 10),
              _status(),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- classic

  Widget _classicLayout(BuildContext context, Size size) {
    final p = widget.palette;
    final button = math.min(size.width * 0.52, size.height * 0.4).clamp(120.0, 220.0);
    final numberSize = math.min(size.width * 0.34, size.height * 0.24);
    return Column(
      children: [
        const Spacer(flex: 2),
        RollingNumber(value: _display, style: _numberStyle(numberSize)),
        const SizedBox(height: 8),
        Text('of ${widget.target}', style: _caption),
        const SizedBox(height: 18),
        SizedBox(
          width: math.min(size.width * 0.5, 220),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: _display / widget.target),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 3,
                color: p.accent,
                backgroundColor: p.track,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _status(),
        const Spacer(flex: 2),
        AnimatedBuilder(
          animation: _press,
          builder: (context, _) => CustomPaint(
            size: Size.square(button),
            painter: _CountButtonPainter(palette: p, press: _press.value),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  // ---------------------------------------------------------------- device

  Widget _deviceLayout(BuildContext context, Size size) {
    final p = widget.palette;
    // Fit the 1:1.3 body inside the available area on any screen.
    final width = math.min(320.0, math.min(size.width * 0.74, size.height * 0.74));
    final height = width * 1.3;
    final digits = math.max(4, widget.target.toString().length);
    final lcdHeight = width * 0.2;
    final segment = math.max(12.0, math.min(width * 0.62 / digits / 0.66, lcdHeight * 0.68));
    return Center(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _DeviceBodyPainter(p),
          child: Column(
            children: [
              SizedBox(height: width * 0.14),
              Container(
                width: width * 0.76,
                height: lcdHeight + 26,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: p.lcd,
                  borderRadius: BorderRadius.circular(width * 0.05),
                  border: Border.all(color: Color.alphaBlend(Colors.black.withValues(alpha: 0.18), p.body), width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 2, offset: const Offset(0, 1)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.paused ? 'PAUSE' : 'R${_round.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontFamily: AppFonts.sans,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: p.lcdInk.withValues(alpha: 0.75),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '/${widget.target}',
                          style: TextStyle(
                            fontFamily: AppFonts.sans,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: p.lcdInk.withValues(alpha: 0.75),
                            fontFeatures: AppFonts.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SevenSegmentDisplay(
                            value: _display,
                            digits: digits,
                            ink: p.lcdInk,
                            height: segment,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _press,
                builder: (context, _) => CustomPaint(
                  size: Size.square(width * 0.46),
                  painter: _CountButtonPainter(palette: p, press: _press.value, raised: true),
                ),
              ),
              SizedBox(height: width * 0.14),
            ],
          ),
        ),
      ),
    );
  }
}

/// The big round counting button.
class _CountButtonPainter extends CustomPainter {
  const _CountButtonPainter({required this.palette, required this.press, this.raised = false});

  final DigitalPalette palette;
  final double press;
  final bool raised;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final p = palette;
    final depth = (raised ? 6.0 : 4.0) * (1 - press);

    // Soft drop shadow, shorter while pressed.
    canvas.drawCircle(
      c + Offset(0, depth + 2),
      r * 0.92,
      Paint()
        ..color = Colors.black.withValues(alpha: p.isDark ? 0.5 : 0.16)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + depth * 1.5),
    );
    // Outer bezel.
    canvas.drawCircle(c, r * 0.96, Paint()..color = p.buttonEdge);
    // Face.
    final face = r * (0.86 - 0.01 * press);
    final faceColor = raised ? p.accent : p.button;
    canvas.drawCircle(
      c + Offset(0, press * 1.5),
      face,
      Paint()
        ..shader = ui.Gradient.radial(
          c + Offset(-face * 0.3, -face * 0.4),
          face * 1.5,
          [
            Color.lerp(faceColor, Colors.white, p.isDark ? 0.10 : 0.35)!,
            faceColor,
            Color.lerp(faceColor, Colors.black, 0.12 + 0.08 * press)!,
          ],
          [0.0, 0.55, 1.0],
        ),
    );
    // Concentric grip rings.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = (raised ? Colors.white : p.accent).withValues(alpha: 0.16 + 0.12 * press);
    for (final f in const [0.62, 0.42]) {
      canvas.drawCircle(c + Offset(0, press * 1.5), face * f, ring);
    }
    // Pressed glow.
    if (press > 0) {
      canvas.drawCircle(
        c,
        face * (1.02 + 0.06 * press),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = p.accent.withValues(alpha: 0.35 * press),
      );
    }
  }

  @override
  bool shouldRepaint(_CountButtonPainter oldDelegate) =>
      oldDelegate.press != press || oldDelegate.palette != palette || oldDelegate.raised != raised;
}

/// The handheld counter's shell: a soft egg-like body with a lanyard loop.
class _DeviceBodyPainter extends CustomPainter {
  const _DeviceBodyPainter(this.palette);

  final DigitalPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.92, 0, w, h * 0.18, w, h * 0.46)
      ..cubicTo(w, h * 0.82, w * 0.82, h, w * 0.5, h)
      ..cubicTo(w * 0.18, h, 0, h * 0.82, 0, h * 0.46)
      ..cubicTo(0, h * 0.18, w * 0.08, 0, w * 0.5, 0)
      ..close();

    canvas.drawShadow(body, Colors.black, 14, false);
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, 0), Offset(w, h), [
          Color.lerp(palette.body, Colors.white, palette.isDark ? 0.08 : 0.3)!,
          palette.body,
          Color.lerp(palette.body, Colors.black, 0.18)!,
        ], [0.0, 0.5, 1.0]),
    );
    // Inner highlight edge.
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: palette.isDark ? 0.08 : 0.4),
    );
    // Lanyard loop at the side.
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.97, h * 0.2), radius: w * 0.07),
      -math.pi * 0.6,
      math.pi * 1.2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.025
        ..color = Color.lerp(palette.body, Colors.black, 0.25)!,
    );
  }

  @override
  bool shouldRepaint(_DeviceBodyPainter oldDelegate) => oldDelegate.palette != palette;
}
