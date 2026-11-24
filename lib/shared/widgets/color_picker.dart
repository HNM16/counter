import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Opens a compact HSV color picker. Returns the chosen color, or null.
Future<Color?> showColorPicker(BuildContext context, {required Color initial, String title = 'Custom color'}) {
  return showModalBottomSheet<Color>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => _ColorPickerSheet(initial: initial, title: title),
  );
}

class _ColorPickerSheet extends StatefulWidget {
  const _ColorPickerSheet({required this.initial, required this.title});

  final Color initial;
  final String title;

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = _hsv.toColor();
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.title, style: text.headlineSmall)),
              AnimatedContainer(
                duration: Motion.fast,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.hairline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(ColorTools.toHex(color), style: text.bodySmall),
          const SizedBox(height: Space.lg),
          _GradientSlider(
            label: 'Hue',
            value: _hsv.hue / 360,
            colors: [for (var h = 0; h <= 360; h += 60) HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor()],
            onChanged: (v) => setState(() => _hsv = _hsv.withHue(v * 360)),
          ),
          _GradientSlider(
            label: 'Saturation',
            value: _hsv.saturation,
            colors: [_hsv.withSaturation(0).toColor(), _hsv.withSaturation(1).toColor()],
            onChanged: (v) => setState(() => _hsv = _hsv.withSaturation(v)),
          ),
          _GradientSlider(
            label: 'Brightness',
            value: _hsv.value,
            colors: [Colors.black, _hsv.withValue(1).toColor()],
            onChanged: (v) => setState(() => _hsv = _hsv.withValue(v)),
          ),
          const SizedBox(height: Space.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: () => Navigator.of(context).pop(color), child: const Text('Use this color')),
          ),
        ],
      ),
    );
  }
}

class _GradientSlider extends StatelessWidget {
  const _GradientSlider({required this.label, required this.value, required this.colors, required this.onChanged});

  final String label;
  final double value;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: text.labelSmall),
          const SizedBox(height: Space.xs),
          Semantics(
            slider: true,
            label: label,
            value: '${(value * 100).round()}%',
            increasedValue: '${((value + 0.05).clamp(0, 1) * 100).round()}%',
            decreasedValue: '${((value - 0.05).clamp(0, 1) * 100).round()}%',
            onIncrease: () => onChanged((value + 0.05).clamp(0.0, 1.0)),
            onDecrease: () => onChanged((value - 0.05).clamp(0.0, 1.0)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                void update(Offset p) => onChanged((p.dx / w).clamp(0.0, 1.0));
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => update(d.localPosition),
                  onHorizontalDragUpdate: (d) => update(d.localPosition),
                  child: SizedBox(
                    height: 32,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Radii.pill),
                            gradient: LinearGradient(colors: colors),
                          ),
                        ),
                        Positioned(
                          left: (value * w - 13).clamp(-4.0, w - 22),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Round color swatch used across the customization studio.
class ColorSwatchButton extends StatelessWidget {
  const ColorSwatchButton({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.label,
    this.size = 40,
    this.child,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String label;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          width: size + 8,
          height: size + 8,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: selected ? c.accent : Colors.transparent, width: 2),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
