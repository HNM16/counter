import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/stats_models.dart';

/// Rounded bar chart with tap-to-inspect. Labels thin out automatically when
/// there are many bars.
class ActivityBarChart extends StatefulWidget {
  const ActivityBarChart({
    super.key,
    required this.buckets,
    this.height = 180,
    this.showValues = true,
    this.labelEvery,
    this.selectable = true,
    this.describe,
  });

  final List<ActivityBucket> buckets;
  final double height;
  final bool showValues;

  /// Show every nth label; computed from the bar count when null.
  final int? labelEvery;
  final bool selectable;

  /// Text shown for the selected bar.
  final String Function(ActivityBucket bucket)? describe;

  @override
  State<ActivityBarChart> createState() => _ActivityBarChartState();
}

class _ActivityBarChartState extends State<ActivityBarChart> {
  int? _selected;

  @override
  void didUpdateWidget(ActivityBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buckets.length != widget.buckets.length) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final buckets = widget.buckets;
    final every = widget.labelEvery ?? (buckets.length <= 12 ? 1 : (buckets.length / 6).ceil());
    final selected = _selected;
    final selectedBucket = selected == null ? null : buckets[selected];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.selectable)
          SizedBox(
            height: 22,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                selectedBucket == null
                    ? 'Tap a bar for details'
                    : (widget.describe?.call(selectedBucket) ?? Formatters.count(selectedBucket.count)),
                key: ValueKey(selected),
                style: selectedBucket == null
                    ? text.bodySmall!.copyWith(color: c.textTertiary)
                    : text.labelLarge!.copyWith(color: c.textPrimary),
              ),
            ),
          ),
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: widget.selectable
                    ? (d) {
                        final i = (d.localPosition.dx / constraints.maxWidth * buckets.length)
                            .floor()
                            .clamp(0, buckets.length - 1);
                        setState(() => _selected = _selected == i ? null : i);
                      }
                    : null,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) => CustomPaint(
                    size: constraints.biggest,
                    painter: _BarsPainter(
                      buckets: buckets,
                      grow: t,
                      bar: c.accent,
                      barMuted: c.accent.withValues(alpha: 0.28),
                      today: c.gold,
                      track: c.surfaceMuted,
                      grid: c.hairline,
                      selected: selected,
                      todayIndex: buckets.indexWhere((b) => b.start.isSameDay(DateTime.now())),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < buckets.length; i++)
              Expanded(
                child: Text(
                  i % every == 0 ? buckets[i].label : '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: text.bodySmall!.copyWith(
                    fontSize: 10.5,
                    color: i == selected ? c.textPrimary : c.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter({
    required this.buckets,
    required this.grow,
    required this.bar,
    required this.barMuted,
    required this.today,
    required this.track,
    required this.grid,
    required this.selected,
    required this.todayIndex,
  });

  final List<ActivityBucket> buckets;
  final double grow;
  final Color bar;
  final Color barMuted;
  final Color today;
  final Color track;
  final Color grid;
  final int? selected;
  final int todayIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (buckets.isEmpty) return;
    final maxValue = buckets.map((b) => b.count).fold<int>(0, math.max);
    final slot = size.width / buckets.length;
    final barWidth = math.min(slot * 0.56, 28.0);
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final f in const [0.0, 0.5, 1.0]) {
      final y = size.height * (1 - f);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var i = 0; i < buckets.length; i++) {
      final cx = slot * (i + 0.5);
      final value = buckets[i].count;
      final h = maxValue == 0 ? 0.0 : (value / maxValue) * (size.height - 4) * grow;
      final radius = Radius.circular(math.min(barWidth / 2, 6));
      if (h <= 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(cx - barWidth / 2, size.height - 3, barWidth, 3), radius),
          Paint()..color = track,
        );
        continue;
      }
      final Color color;
      if (selected != null) {
        color = i == selected ? bar : barMuted;
      } else {
        color = i == todayIndex ? today : bar;
      }
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - barWidth / 2, size.height - h, barWidth, h),
          topLeft: radius,
          topRight: radius,
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter oldDelegate) =>
      oldDelegate.buckets != buckets ||
      oldDelegate.grow != grow ||
      oldDelegate.selected != selected ||
      oldDelegate.bar != bar ||
      oldDelegate.track != track;
}

/// GitHub-style calendar of daily activity (weeks as columns).
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({super.key, required this.totals, required this.today, this.weeks = 18});

  final Map<DateTime, int> totals;
  final DateTime today;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final start = today.startOfWeek.addDays(-7 * (weeks - 1));
    final values = totals.values.where((v) => v > 0).toList()..sort();
    // Quartile thresholds make the scale meaningful for light and heavy users.
    int q(double f) => values.isEmpty ? 1 : values[((values.length - 1) * f).round()];
    final thresholds = [q(0.25), q(0.5), q(0.75)];

    Color shade(int v) {
      if (v <= 0) return c.surfaceMuted;
      var level = 1;
      for (final t in thresholds) {
        if (v > t) level++;
      }
      return Color.lerp(c.accentSoft, c.accent, level / 4)!;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 3.0;
        final cell = ((constraints.maxWidth - 22 - gap * (weeks - 1)) / weeks).clamp(6.0, 16.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  for (var d = 0; d < 7; d++)
                    SizedBox(
                      height: cell + gap,
                      child: Text(
                        d.isEven ? Formatters.weekdayNarrow(start.addDays(d)) : '',
                        style: text.bodySmall!.copyWith(fontSize: 9.5, color: c.textTertiary),
                      ),
                    ),
                ],
              ),
            ),
            for (var w = 0; w < weeks; w++)
              Padding(
                padding: EdgeInsets.only(right: w == weeks - 1 ? 0 : gap),
                child: Column(
                  children: [
                    for (var d = 0; d < 7; d++)
                      Builder(
                        builder: (context) {
                          final day = start.addDays(w * 7 + d);
                          final future = day.isAfter(today);
                          final v = totals[day] ?? 0;
                          return Tooltip(
                            message: future ? '' : '${Formatters.dayMonth(day)}: ${Formatters.count(v)}',
                            child: Container(
                              width: cell,
                              height: cell,
                              margin: const EdgeInsets.only(bottom: gap),
                              decoration: BoxDecoration(
                                color: future ? Colors.transparent : shade(v),
                                borderRadius: BorderRadius.circular(cell * 0.25),
                                border: day.isSameDay(today) ? Border.all(color: c.gold, width: 1.2) : null,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
