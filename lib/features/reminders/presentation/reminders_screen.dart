import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/common.dart';
import '../../dhikr/domain/dhikr.dart';
import '../../dhikr/presentation/dhikr_providers.dart';
import '../domain/reminder.dart';
import 'reminder_providers.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  static void _report(BuildContext context, ReminderSaveResult result) {
    switch (result) {
      case ReminderSaveResult.permissionDenied:
        showToast(context, 'Notifications are off for Sakina. Enable them in your device settings.');
      case ReminderSaveResult.scheduled:
        showToast(context, 'Reminder scheduled');
      case ReminderSaveResult.saved:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final reminders = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add_alarm),
        label: const Text('New reminder'),
      ),
      body: reminders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load reminders.\n$e')),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No reminders',
              message: 'Add a quiet daily reminder, for example after Fajr or before sleep. Reminders stay on your device.',
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              for (final r in items) ...[
                _ReminderRow(
                  reminder: r,
                  onTap: () => _edit(context, ref, existing: r),
                  onToggle: (v) async {
                    final result = await ref.read(remindersProvider.notifier).setEnabled(r, v);
                    if (context.mounted && v) _report(context, result);
                  },
                ),
                const Hairline(),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, 0),
                child: Text(
                  'Reminders are delivered quietly at around the chosen time. Tapping one opens your tasbih.',
                  style: text.bodySmall!.copyWith(color: c.textTertiary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, {Reminder? existing}) async {
    final result = await showModalBottomSheet<ReminderSaveResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ReminderEditor(existing: existing),
    );
    if (result != null && context.mounted) _report(context, result);
  }
}

String _daysLabel(Set<int> days) {
  if (days.length == 7) return 'Every day';
  if (days.isEmpty) return 'No days selected';
  if (days.length == 5 && !days.contains(6) && !days.contains(7)) return 'Weekdays';
  if (days.length == 2 && days.contains(6) && days.contains(7)) return 'Weekends';
  final sorted = days.toList()..sort();
  // 2024-01-01 was a Monday.
  return sorted.map((d) => Formatters.weekdayShort(DateTime(2024, 1, d))).join(', ');
}

class _ReminderRow extends ConsumerWidget {
  const _ReminderRow({required this.reminder, required this.onTap, required this.onToggle});

  final Reminder reminder;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final dhikr = reminder.dhikrId == null ? null : ref.watch(dhikrByIdProvider(reminder.dhikrId!));
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.md, Space.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.timeOfDay(reminder.hour, reminder.minute),
                    style: text.headlineMedium!.copyWith(
                      color: reminder.enabled ? c.textPrimary : c.textTertiary,
                    ),
                  ),
                  Text(
                    [_daysLabel(reminder.weekdays), if (dhikr != null) dhikr.transliteration].join('  ·  '),
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            Switch(value: reminder.enabled, onChanged: onToggle),
          ],
        ),
      ),
    );
  }
}

class _ReminderEditor extends ConsumerStatefulWidget {
  const _ReminderEditor({this.existing});

  final Reminder? existing;

  @override
  ConsumerState<_ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends ConsumerState<_ReminderEditor> {
  late TimeOfDay _time = widget.existing == null
      ? const TimeOfDay(hour: 7, minute: 0)
      : TimeOfDay(hour: widget.existing!.hour, minute: widget.existing!.minute);
  late Set<int> _days = {...(widget.existing?.weekdays ?? Reminder.everyDay)};
  late String? _dhikrId = widget.existing?.dhikrId;
  bool _saving = false;

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final base = widget.existing ?? Reminder(hour: 0, minute: 0, weekdays: const {});
    final reminder = base.copyWith(
      hour: _time.hour,
      minute: _time.minute,
      weekdays: _days,
      dhikrId: _dhikrId,
      clearDhikr: _dhikrId == null,
      enabled: true,
    );
    final result = await ref.read(remindersProvider.notifier).save(reminder);
    if (mounted) Navigator.of(context).pop(result);
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    await ref.read(remindersProvider.notifier).remove(existing);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final library = ref.watch(dhikrLibraryProvider).value ?? const <Dhikr>[];

    return Padding(
      padding: EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xl + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.existing == null ? 'New reminder' : 'Edit reminder', style: text.headlineSmall),
                ),
                if (widget.existing != null)
                  IconButton(
                    tooltip: 'Delete reminder',
                    onPressed: _delete,
                    icon: Icon(Icons.delete_outline, color: c.danger),
                  ),
              ],
            ),
            const SizedBox(height: Space.md),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(Radii.md),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: Space.md),
                decoration: BoxDecoration(
                  border: Border.all(color: c.hairline),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Column(
                  children: [
                    Text(Formatters.timeOfDay(_time.hour, _time.minute), style: text.displaySmall),
                    Text('Tap to change time', style: text.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.lg),
            Text('REPEAT ON', style: text.labelSmall),
            const SizedBox(height: Space.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var d = 1; d <= 7; d++)
                  _DayChip(
                    label: Formatters.weekdayNarrow(DateTime(2024, 1, d)),
                    semantic: Formatters.weekdayShort(DateTime(2024, 1, d)),
                    selected: _days.contains(d),
                    onTap: () => setState(() {
                      _days = {..._days};
                      _days.contains(d) ? _days.remove(d) : _days.add(d);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: Space.lg),
            Text('OPEN WITH (OPTIONAL)', style: text.labelSmall),
            const SizedBox(height: Space.xs),
            DropdownButtonFormField<String?>(
              initialValue: _dhikrId,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('My current dhikr')),
                for (final d in library)
                  DropdownMenuItem(value: d.id, child: Text(d.transliteration, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _dhikrId = v),
            ),
            const SizedBox(height: Space.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _days.isEmpty || _saving ? null : _save,
                child: const Text('Save reminder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.semantic, required this.selected, required this.onTap});

  final String label;
  final String semantic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      label: semantic,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? c.accent : Colors.transparent,
            border: Border.all(color: selected ? c.accent : c.hairline),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(color: selected ? c.onAccent : c.textSecondary),
          ),
        ),
      ),
    );
  }
}
