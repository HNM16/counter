import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/arabic_text.dart';
import '../../../tasbih/domain/counter_session.dart';

/// One history entry: dhikr, time, repetitions, rounds and duration.
class SessionTile extends StatelessWidget {
  const SessionTile({super.key, required this.session, this.onDelete, this.showDate = false});

  final CounterSession session;
  final VoidCallback? onDelete;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final s = session;
    final when = s.endedAt ?? s.lastActivityAt;
    final time = showDate ? '${Formatters.dayMonth(when)}, ${Formatters.time(when)}' : Formatters.time(when);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 10, Space.xs, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(s.dhikrLabel, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (s.isActive) ...[
                      const SizedBox(width: Space.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.accentSoft,
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: Text('In progress', style: text.labelSmall!.copyWith(color: c.accent, letterSpacing: 0.2)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    time,
                    Formatters.plural(s.totalCount, 'repetition'),
                    Formatters.plural(s.roundsCompleted, 'round'),
                    Formatters.duration(s.activeDuration),
                  ].join('  ·  '),
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: ArabicText(s.dhikrArabic, size: 17, maxLines: 1, textAlign: TextAlign.right, color: c.textSecondary),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete entry',
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: c.textTertiary, size: 20),
            )
          else
            const SizedBox(width: Space.sm),
        ],
      ),
    );
  }
}
