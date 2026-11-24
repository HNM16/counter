import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../tasbih/widgets/beads/bead_renderer.dart';
import '../../../tasbih/widgets/beads/bead_spec.dart';
import '../../../tasbih/widgets/beads/bead_tasbih_view.dart';
import '../../../tasbih/widgets/beads/tasbih_backdrop.dart';
import '../../../tasbih/widgets/digital/digital_counter_view.dart';
import '../../../tasbih/widgets/digital/digital_palette.dart';
import '../../domain/app_settings.dart';

/// Advances a demo count on a timer so previews show real motion.
mixin _DemoCounter<T extends StatefulWidget> on State<T> {
  int demoCount = 7;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (mounted) setState(() => demoCount++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Live, self-animating preview of the bead tasbih.
class BeadLivePreview extends StatefulWidget {
  const BeadLivePreview({super.key, required this.settings, this.height = 300});

  final AppSettings settings;
  final double height;

  @override
  State<BeadLivePreview> createState() => _BeadLivePreviewState();
}

class _BeadLivePreviewState extends State<BeadLivePreview> with _DemoCounter {
  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.lg),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: TasbihBackdropPainter(s.tasbihBackground)),
            BeadTasbihView(
              appearance: BeadAppearance.fromSettings(s),
              totalCount: demoCount,
              target: s.beadCount,
            ),
          ],
        ),
      ),
    );
  }
}

/// Live, self-animating preview of the digital counter.
class DigitalLivePreview extends StatefulWidget {
  const DigitalLivePreview({super.key, required this.settings, this.height = 300});

  final AppSettings settings;
  final double height;

  @override
  State<DigitalLivePreview> createState() => _DigitalLivePreviewState();
}

class _DigitalLivePreviewState extends State<DigitalLivePreview> with _DemoCounter {
  @override
  Widget build(BuildContext context) {
    final palette = DigitalPalette.of(widget.settings);
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.lg),
      child: AnimatedContainer(
        duration: Motion.medium,
        height: widget.height,
        color: palette.background,
        padding: const EdgeInsets.all(Space.md),
        child: DigitalCounterView(
          layout: widget.settings.digitalLayout,
          palette: palette,
          totalCount: demoCount,
          target: 33,
        ),
      ),
    );
  }
}

/// A single rendered bead, used as a material swatch.
class BeadSwatch extends StatelessWidget {
  const BeadSwatch({super.key, required this.spec, this.size = 44});

  final BeadSpec spec;
  final double size;

  static final _cache = <BeadSpec, BeadRenderer>{};

  @override
  Widget build(BuildContext context) {
    final renderer = _cache.putIfAbsent(spec, () => BeadRenderer(spec));
    return SizedBox.square(dimension: size, child: CustomPaint(painter: _BeadSwatchPainter(renderer)));
  }
}

class _BeadSwatchPainter extends CustomPainter {
  const _BeadSwatchPainter(this.renderer);

  final BeadRenderer renderer;

  @override
  void paint(Canvas canvas, Size size) {
    renderer.paintBead(canvas, size.center(Offset.zero), size.shortestSide * 0.4, 0.5, 1);
  }

  @override
  bool shouldRepaint(_BeadSwatchPainter oldDelegate) => oldDelegate.renderer != renderer;
}

/// A miniature of a backdrop, used as a background swatch.
class BackdropSwatch extends StatelessWidget {
  const BackdropSwatch({super.key, required this.background, this.size = const Size(64, 84)});

  final TasbihBackground background;
  final Size size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(Radii.sm),
    child: CustomPaint(size: size, painter: TasbihBackdropPainter(background)),
  );
}
