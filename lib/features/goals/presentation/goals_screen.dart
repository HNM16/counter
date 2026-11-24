import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../dhikr/domain/dhikr.dart';
import '../../dhikr/presentation/dhikr_providers.dart';
import '../../home/presentation/widgets/goals_overview.dart';
import '../domain/goal.dart';
import 'goal_providers.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final progress = ref.watch(goalProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showGoalEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New goal'),
      ),
      body: progress.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load goals.\n$e')),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.flag_outlined,
              title: 'No goals yet',
              message:
                  'Goals reset every day. Choose a number of repetitions for one dhikr, or for all your dhikr combined.',
            );
          }
          final overall = GoalProgress.overall(items);
          final done = items.where((p) => p.isComplete).length;
          return ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.md),
                child: Row(
                  children: [
                    ProgressRing(
                      progress: overall,
                      color: done == items.length ? c.gold : c.accent,
                      trackColor: c.surfaceMuted,
                      size: 84,
                      strokeWidth: 5,
                      child: Text('${(overall * 100).round()}%', style: text.titleMedium),
                    ),
                    const SizedBox(width: Space.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today', style: text.headlineSmall),
                          Text('$done of ${items.length} goals complete', style: text.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Hairline(),
              for (final p in items)
                GoalProgressRow(
                  progress: p,
                  onTap: () => showGoalEditor(context, ref, existing: p.goal),
                  trailing: IconButton(
                    tooltip: 'Delete goal',
                    icon: Icon(Icons.delete_outline, color: c.textTertiary, size: 20),
                    onPressed: () async {
                      final ok = await confirmAction(
                        context,
                        title: 'Delete goal?',
                        message: 'Your counting history is not affected.',
                        confirmLabel: 'Delete',
                        destructive: true,
                      );
                      if (ok) await ref.read(goalsProvider.notifier).remove(p.goal);
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, 0),
                child: Text(
                  'Goals reset at midnight. When you reach one while counting, you will feel it and see a short celebration.',
                  style: text.bodySmall!.copyWith(color: c.textTertiary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Create or edit a goal.
Future<void> showGoalEditor(BuildContext context, WidgetRef ref, {Goal? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _GoalEditor(existing: existing),
  );
}

class _GoalEditor extends ConsumerStatefulWidget {
  const _GoalEditor({this.existing});

  final Goal? existing;

  @override
  ConsumerState<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends ConsumerState<_GoalEditor> {
  late String? _dhikrId = widget.existing?.dhikrId;
  late int? _preset = Goal.presets.contains(widget.existing?.target ?? 100) ? (widget.existing?.target ?? 100) : null;
  late final _custom = TextEditingController(
    text: widget.existing != null && !Goal.presets.contains(widget.existing!.target) ? '${widget.existing!.target}' : '',
  );
  String? _error;

  int? get _target => _preset ?? int.tryParse(_custom.text.trim());

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = _target;
    if (t == null || t < 1 || t > 1000000) {
      setState(() => _error = 'Enter a number between 1 and 1,000,000');
      return;
    }
    final notifier = ref.read(goalsProvider.notifier);
    final existing = widget.existing;
    if (existing == null) {
      await notifier.add(target: t, dhikrId: _dhikrId);
    } else {
      await notifier.save(existing.copyWith(target: t, dhikrId: _dhikrId, overall: _dhikrId == null));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final library = ref.watch(dhikrLibraryProvider).value ?? const <Dhikr>[];

    return Padding(
      padding: EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xl + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existing == null ? 'New daily goal' : 'Edit goal', style: text.headlineSmall),
            const SizedBox(height: Space.lg),
            Text('DHIKR', style: text.labelSmall),
            const SizedBox(height: Space.xs),
            DropdownButtonFormField<String?>(
              initialValue: _dhikrId,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('All dhikr combined')),
                for (final d in library)
                  DropdownMenuItem(value: d.id, child: Text(d.transliteration, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _dhikrId = v),
            ),
            const SizedBox(height: Space.lg),
            Text('REPETITIONS PER DAY', style: text.labelSmall),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final p in Goal.presets)
                  ChoiceChip(
                    label: Text(Formatters.count(p)),
                    selected: _preset == p,
                    onSelected: (_) => setState(() {
                      _preset = p;
                      _custom.clear();
                      _error = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _custom,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
              decoration: InputDecoration(labelText: 'Custom number', errorText: _error),
              onChanged: (_) => setState(() {
                _preset = null;
                _error = null;
              }),
            ),
            const SizedBox(height: Space.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _target == null ? null : _save,
                child: Text(widget.existing == null ? 'Add goal' : 'Save goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
