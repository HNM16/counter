import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/arabic_text.dart';
import '../../../shared/widgets/common.dart';
import '../../dhikr/domain/dhikr.dart';
import '../../dhikr/presentation/dhikr_providers.dart';
import '../domain/counter_session.dart';
import 'tasbih_controller.dart';

/// Lets the user choose which dhikr to count.
Future<void> showDhikrPicker(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.94,
      minChildSize: 0.4,
      builder: (context, controller) => _DhikrPickerBody(scrollController: controller, hostContext: context),
    ),
  );
}

class _DhikrPickerBody extends ConsumerWidget {
  const _DhikrPickerBody({required this.scrollController, required this.hostContext});

  final ScrollController scrollController;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final library = ref.watch(dhikrLibraryProvider);
    final currentId = ref.watch(tasbihControllerProvider).value?.session.dhikrId;

    return library.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load the library.\n$e', textAlign: TextAlign.center)),
      data: (items) {
        final sorted = [...items]..sort((a, b) => (b.isFavorite ? 1 : 0).compareTo(a.isFavorite ? 1 : 0));
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.only(bottom: Space.xl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.sm),
              child: Row(
                children: [
                  Expanded(child: Text('Choose dhikr', style: text.headlineSmall)),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      hostContext.push(Routes.library);
                    },
                    child: const Text('Library'),
                  ),
                ],
              ),
            ),
            for (final d in sorted)
              _PickerRow(
                dhikr: d,
                selected: d.id == currentId,
                onTap: () async {
                  Navigator.of(context).pop();
                  final saved = await ref.read(tasbihControllerProvider.notifier).selectDhikr(d);
                  if (saved && hostContext.mounted) showToast(hostContext, 'Previous session saved to history');
                },
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, 0),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  hostContext.push(Routes.newDhikr);
                },
                icon: Icon(Icons.add, color: c.accent),
                label: const Text('Create your own dhikr'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.dhikr, required this.selected, required this.onTap});

  final Dhikr dhikr;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: Space.sm),
        color: selected ? c.accentSoft : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dhikr.transliteration, style: text.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    dhikr.suggestedCount == null ? 'Your own target' : 'Suggested ${dhikr.suggestedCount}',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.sm),
            Flexible(child: ArabicText(dhikr.arabic, size: 22, textAlign: TextAlign.right, maxLines: 1)),
            const SizedBox(width: Space.sm),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected ? c.accent : c.hairline,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets the user change the number of repetitions per round.
Future<int?> showTargetPicker(BuildContext context, {required int current}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _TargetPicker(current: current),
  );
}

class _TargetPicker extends StatefulWidget {
  const _TargetPicker({required this.current});

  final int current;

  @override
  State<_TargetPicker> createState() => _TargetPickerState();
}

class _TargetPickerState extends State<_TargetPicker> {
  static const presets = [33, 99, 100, 1000];
  late final _field = TextEditingController(text: presets.contains(widget.current) ? '' : '${widget.current}');
  late int? _selected = presets.contains(widget.current) ? widget.current : null;
  String? _error;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  int? get _value => _selected ?? int.tryParse(_field.text.trim());

  void _submit() {
    final v = _value;
    if (v == null || v < 1 || v > 100000) {
      setState(() => _error = 'Enter a number between 1 and 100,000');
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Repetitions per round', style: text.headlineSmall),
          const SizedBox(height: Space.xs),
          Text(
            'When a round completes you will feel a gentle vibration and the next round begins automatically.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: Space.lg),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final p in presets)
                ChoiceChip(
                  label: Text(Formatters.count(p)),
                  selected: _selected == p,
                  onSelected: (_) => setState(() {
                    _selected = p;
                    _field.clear();
                    _error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _field,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            decoration: InputDecoration(labelText: 'Custom number', errorText: _error),
            onChanged: (_) => setState(() {
              _selected = null;
              _error = null;
            }),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Space.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _value == null ? null : _submit, child: const Text('Apply')),
          ),
        ],
      ),
    );
  }
}

enum ResetChoice { save, discard }

/// Confirms a reset, offering to keep the repetitions in history.
Future<ResetChoice?> showResetDialog(BuildContext context, CounterSession session) {
  final c = context.colors;
  return showDialog<ResetChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reset counter?'),
      content: Text(
        'You have counted ${Formatters.plural(session.totalCount, 'repetition')} in this session. '
        'Save them to your history, or discard them completely.',
      ),
      actionsOverflowButtonSpacing: 4,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: c.textSecondary),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ResetChoice.discard),
          style: TextButton.styleFrom(foregroundColor: c.danger),
          child: const Text('Discard'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ResetChoice.save),
          child: const Text('Save & reset'),
        ),
      ],
    ),
  );
}

/// Shown after a session is saved.
Future<void> showSessionSummary(BuildContext context, CounterSession s) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) {
      final text = Theme.of(context).textTheme;
      final c = context.colors;
      return Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: c.accent, size: 36),
            const SizedBox(height: Space.sm),
            Text('Session saved', style: text.headlineSmall),
            const SizedBox(height: Space.xs),
            ArabicText(s.dhikrArabic, size: 26),
            Text(s.dhikrLabel, style: text.bodyMedium),
            const SizedBox(height: Space.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatPair(value: Formatters.count(s.totalCount), label: 'Repetitions'),
                StatPair(value: '${s.roundsCompleted}', label: 'Rounds'),
                StatPair(value: Formatters.duration(s.activeDuration), label: 'Focused time'),
              ],
            ),
            const SizedBox(height: Space.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Continue')),
            ),
          ],
        ),
      );
    },
  );
}
