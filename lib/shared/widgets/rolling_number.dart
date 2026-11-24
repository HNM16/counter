import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_typography.dart';

/// Odometer-style number: each digit rolls independently when it changes,
/// upwards when the value grows and downwards when it shrinks.
class RollingNumber extends StatefulWidget {
  const RollingNumber({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 260),
  });

  final int value;
  final TextStyle style;
  final Duration duration;

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber> {
  bool _up = true;

  @override
  void didUpdateWidget(RollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _up = widget.value > oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    final digits = widget.value.abs().toString().split('');
    final style = widget.style.copyWith(fontFeatures: AppFonts.tabularFigures);
    return Semantics(
      label: '${widget.value}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < digits.length; i++)
            _Digit(
              key: ValueKey(digits.length - i),
              digit: digits[i],
              up: _up,
              style: style,
              duration: widget.duration,
            ),
        ],
      ),
    );
  }
}

class _Digit extends StatelessWidget {
  const _Digit({super.key, required this.digit, required this.up, required this.style, required this.duration});

  final String digit;
  final bool up;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(alignment: Alignment.center, children: [...previous, ?current]),
        transitionBuilder: (child, animation) {
          final incoming = child.key == ValueKey(digit);
          final dir = up ? 1.0 : -1.0;
          final offset = Tween<Offset>(
            begin: Offset(0, incoming ? 0.55 * dir : -0.55 * dir),
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(
            position: offset,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Text(digit, key: ValueKey(digit), style: style),
      ),
    );
  }
}
