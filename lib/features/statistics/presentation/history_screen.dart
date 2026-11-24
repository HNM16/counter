import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/common.dart';
import '../../tasbih/domain/counter_session.dart';
import 'stats_providers.dart';
import 'widgets/session_tile.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) ref.read(historyProvider.notifier).loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _delete(CounterSession s) async {
    final ok = await confirmAction(
      context,
      title: 'Delete this entry?',
      message:
          '${Formatters.plural(s.totalCount, 'repetition')} of ${s.dhikrLabel} will be removed from your history and statistics.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(historyProvider.notifier).delete(s);
    if (mounted) showToast(context, 'Entry deleted');
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final now = ref.watch(clockProvider)();
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load history.\n$e', textAlign: TextAlign.center)),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: 'No sessions yet',
              message: 'Each time you finish or switch dhikr, your session is saved here.',
            );
          }
          // Group by calendar day of the session's last activity.
          final groups = <DateTime, List<CounterSession>>{};
          for (final s in sessions) {
            final t = s.endedAt ?? s.lastActivityAt;
            groups.putIfAbsent(DateTime(t.year, t.month, t.day), () => []).add(s);
          }
          final entries = groups.entries.toList();
          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.only(bottom: Space.xxl),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final day = entries[i].key;
              final items = entries[i].value;
              final total = items.fold<int>(0, (a, s) => a + s.totalCount);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, Space.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(Formatters.relativeDay(day, now).toUpperCase(), style: text.labelSmall),
                        ),
                        Text(Formatters.count(total), style: text.labelMedium!.copyWith(color: c.textPrimary)),
                      ],
                    ),
                  ),
                  for (final s in items)
                    s.isActive
                        ? SessionTile(session: s)
                        : Dismissible(
                            key: ValueKey('session-${s.id}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              await _delete(s);
                              return false;
                            },
                            background: Container(
                              color: c.danger.withValues(alpha: 0.12),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: Space.xl),
                              child: Icon(Icons.delete_outline, color: c.danger),
                            ),
                            child: SessionTile(session: s, onDelete: () => _delete(s)),
                          ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
