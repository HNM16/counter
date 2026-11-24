import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/progress_ring.dart';
import '../../../../shared/widgets/rolling_number.dart';
import '../../../settings/domain/app_settings.dart';
import '../../domain/bead_loop.dart';
import 'bead_renderer.dart';
import 'bead_spec.dart';
import 'tasbih_backdrop.dart';
import 'tasbih_loop_painter.dart';

/// Configuration of the virtual tasbih's look.
@immutable
class BeadAppearance {
  const BeadAppearance({
    required this.style,
    required this.material,
    required this.tint,
    required this.size,
    required this.beadCount,
    required this.background,
  });

  factory BeadAppearance.fromSettings(AppSettings s) => BeadAppearance(
    style: s.tasbihStyle,
    material: s.beadMaterial,
    tint: s.beadTint,
    size: s.beadSize,
    beadCount: s.beadCount,
    background: s.tasbihBackground,
  );

  final TasbihStyle style;
  final BeadMaterial material;
  final Color? tint;
  final BeadSize size;
  final int beadCount;
  final TasbihBackground background;

  @override
  bool operator ==(Object other) =>
      other is BeadAppearance &&
      other.style == style &&
      other.material == material &&
      other.tint == tint &&
      other.size == size &&
      other.beadCount == beadCount &&
      other.background == background;

  @override
  int get hashCode => Object.hash(style, material, tint, size, beadCount, background);
}

/// The realistic bead tasbih. Tap anywhere, or pull beads along the string,
/// to count. Beads glide through the gap like a real tasbih between fingers.
class BeadTasbihView extends StatefulWidget {
  const BeadTasbihView({
    super.key,
    required this.appearance,
    required this.totalCount,
    required this.target,
    this.onCount,
    this.showReadout = true,
    this.paused = false,
  });

  final BeadAppearance appearance;
  final int totalCount;

  /// Repetitions per round (drives the progress display).
  final int target;

  /// Null renders a non-interactive preview.
  final VoidCallback? onCount;
  final bool showReadout;
  final bool paused;

  @override
  State<BeadTasbihView> createState() => _BeadTasbihViewState();
}

class _BeadTasbihViewState extends State<BeadTasbihView> with TickerProviderStateMixin {
  late BeadLoop _loop;
  late BeadRenderer _renderer;
  late final AnimationController _cursor;
  late final AnimationController _progress;
  final _geometryCache = LoopGeometryCache();

  double _dragAccumulator = 0;
  double? _lastAngle;

  static final _rendererCache = <BeadSpec, BeadRenderer>{};

  int get _display {
    final t = widget.target;
    final total = widget.totalCount;
    return total > 0 && total % t == 0 ? t : total % t;
  }

  @override
  void initState() {
    super.initState();
    _loop = BeadLoop(widget.appearance.beadCount);
    _renderer = _rendererFor(widget.appearance);
    _cursor = AnimationController.unbounded(vsync: this, value: _loop.cursorFor(widget.totalCount));
    _progress = AnimationController(vsync: this, value: _display / widget.target);
  }

  static BeadRenderer _rendererFor(BeadAppearance a) {
    final spec = BeadSpec.of(a.material, tint: a.tint);
    return _rendererCache.putIfAbsent(spec, () {
      if (_rendererCache.length > 12) _rendererCache.remove(_rendererCache.keys.first);
      return BeadRenderer(spec);
    });
  }

  @override
  void didUpdateWidget(BeadTasbihView old) {
    super.didUpdateWidget(old);
    final a = widget.appearance;
    if (a.beadCount != old.appearance.beadCount) {
      _loop = BeadLoop(a.beadCount);
      _cursor.value = _loop.cursorFor(widget.totalCount);
    }
    if (a.material != old.appearance.material || a.tint != old.appearance.tint) {
      _renderer = _rendererFor(a);
    }
    if (widget.totalCount != old.totalCount) {
      final target = _loop.animationTarget(_cursor.value, _loop.cursorFor(widget.totalCount));
      final distance = (target - _cursor.value).abs();
      final ms = distance <= 1.01 ? 300 : (220 + 45 * distance).clamp(320, 1400).toInt();
      _cursor.animateTo(target, duration: Duration(milliseconds: ms), curve: Curves.easeOutCubic);
    }
    final p = _display / widget.target;
    if (p != _progress.value) {
      final newRound = widget.totalCount > old.totalCount && p < _progress.value;
      if (newRound) _progress.value = 0;
      _progress.animateTo(p, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _cursor.dispose();
    _progress.dispose();
    super.dispose();
  }

  /// Angle the ring turns per bead (must match the painter's ring layout).
  double get _slotAngle => 2 * math.pi / (_loop.length + TasbihLoopPainter.ringGapSlots(_loop));

  void _onPanStart(DragStartDetails d, Size size) {
    _dragAccumulator = 0;
    final center = size.center(Offset.zero);
    _lastAngle = math.atan2(d.localPosition.dy - center.dy, d.localPosition.dx - center.dx);
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    final onCount = widget.onCount;
    if (onCount == null) return;
    if (widget.appearance.style == TasbihStyle.strand) {
      _dragAccumulator += d.delta.dy;
      final step = (math.min(size.width, size.height) * 0.075).clamp(22.0, 40.0) * widget.appearance.size.scale;
      while (_dragAccumulator >= step * 0.8) {
        _dragAccumulator -= step;
        onCount();
      }
      if (_dragAccumulator < 0) _dragAccumulator = 0;
      return;
    }
    // Ring: turning the loop clockwise with a thumb counts one bead per slot.
    final center = size.center(Offset.zero);
    final angle = math.atan2(d.localPosition.dy - center.dy, d.localPosition.dx - center.dx);
    final last = _lastAngle ?? angle;
    var delta = angle - last;
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;
    _lastAngle = angle;
    _dragAccumulator = math.max(0, _dragAccumulator + delta);
    final step = _slotAngle;
    while (step > 0 && _dragAccumulator >= step * 0.9) {
      _dragAccumulator -= step;
      onCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appearance;
    final backdrop = BackdropStyle.of(a.background);
    final interactive = widget.onCount != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final painter = CustomPaint(
          size: size,
          painter: TasbihLoopPainter(
            loop: _loop,
            cursor: _cursor,
            progress: _progress,
            renderer: _renderer,
            style: a.style,
            beadScale: a.size.scale,
            backdrop: backdrop,
            velocity: () => _cursor.velocity,
            cache: _geometryCache,
          ),
        );

        // The strand runs off the top and bottom of its area; fade it out
        // softly instead of cutting it off.
        final strand = a.style == TasbihStyle.strand;
        final loop = strand
            ? ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
                  stops: [0.0, 0.1, 0.9, 1.0],
                ).createShader(rect),
                child: painter,
              )
            : painter;

        final stack = Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(child: ClipRect(child: loop)),
            if (widget.showReadout) _readout(context, size, backdrop),
          ],
        );

        if (!interactive) return IgnorePointer(child: stack);

        return Semantics(
          button: true,
          label: 'Tasbih. Tap to count.',
          value: '$_display of ${widget.target}',
          onTap: widget.onCount,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onCount,
            onPanStart: (d) => _onPanStart(d, size),
            onPanUpdate: (d) => _onPanUpdate(d, size),
            child: stack,
          ),
        );
      },
    );
  }

  Widget _readout(BuildContext context, Size size, BackdropStyle backdrop) {
    final text = Theme.of(context).textTheme;
    final ring = widget.appearance.style == TasbihStyle.ring;
    final numberSize = ring
        ? (TasbihLoopPainter.ringRadius(size) * 0.62).clamp(40.0, 96.0)
        : (size.width * 0.2).clamp(44.0, 92.0);
    final numberStyle = TextStyle(
      fontFamily: AppFonts.serif,
      fontWeight: FontWeight.w300,
      fontSize: numberSize,
      height: 1.0,
      color: backdrop.foreground,
    );
    final caption = text.labelMedium!.copyWith(color: backdrop.secondary, letterSpacing: 0.6);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RollingNumber(value: _display, style: numberStyle),
        const SizedBox(height: 6),
        Text('of ${widget.target}', style: caption),
        if (widget.paused) ...[
          const SizedBox(height: 10),
          Text('PAUSED', style: caption.copyWith(color: backdrop.progress, fontWeight: FontWeight.w700)),
        ],
      ],
    );

    if (ring) return Center(child: content);

    // Strand: the count sits to the left of the gap, inside a slim ring.
    return Align(
      alignment: const Alignment(-0.62, -0.02),
      child: ProgressRing(
        progress: _display / widget.target,
        color: backdrop.progress,
        trackColor: backdrop.track,
        size: (size.width * 0.42).clamp(130.0, 200.0),
        strokeWidth: 3,
        child: content,
      ),
    );
  }
}
