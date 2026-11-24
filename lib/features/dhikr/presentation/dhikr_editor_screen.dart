import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/arabic_text.dart';
import '../../../shared/widgets/common.dart';
import '../domain/dhikr.dart';
import 'dhikr_providers.dart';

/// Create or edit a custom dhikr.
class DhikrEditorScreen extends ConsumerStatefulWidget {
  const DhikrEditorScreen({super.key, this.dhikrId});

  final String? dhikrId;

  @override
  ConsumerState<DhikrEditorScreen> createState() => _DhikrEditorScreenState();
}

class _DhikrEditorScreenState extends ConsumerState<DhikrEditorScreen> {
  final _form = GlobalKey<FormState>();
  final _arabic = TextEditingController();
  final _transliteration = TextEditingController();
  final _translation = TextEditingController();
  final _target = TextEditingController();
  Dhikr? _editing;
  bool _loaded = false;
  bool _saving = false;

  bool get _isEdit => widget.dhikrId != null;

  @override
  void dispose() {
    _arabic.dispose();
    _transliteration.dispose();
    _translation.dispose();
    _target.dispose();
    super.dispose();
  }

  void _load(List<Dhikr> items) {
    if (_loaded) return;
    _loaded = true;
    if (!_isEdit) return;
    final d = items.where((x) => x.id == widget.dhikrId).firstOrNull;
    if (d == null) return;
    _editing = d;
    _arabic.text = d.arabic;
    _transliteration.text = d.transliteration;
    _translation.text = d.translation;
    _target.text = d.suggestedCount?.toString() ?? '';
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final target = int.tryParse(_target.text.trim());
    final notifier = ref.read(dhikrLibraryProvider.notifier);
    final editing = _editing;
    if (editing == null) {
      await notifier.create(
        arabic: _arabic.text,
        transliteration: _transliteration.text,
        translation: _translation.text,
        suggestedCount: target,
      );
    } else {
      await notifier.save(
        editing.copyWith(
          arabic: _arabic.text.trim(),
          transliteration: _transliteration.text.trim(),
          translation: _translation.text.trim(),
          suggestedCount: target,
          clearSuggestedCount: target == null,
        ),
      );
    }
    if (!mounted) return;
    showToast(context, editing == null ? 'Dhikr added to your library' : 'Changes saved');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final library = ref.watch(dhikrLibraryProvider);
    library.whenData(_load);

    if (_isEdit && _loaded && _editing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.help_outline,
          title: 'Dhikr not found',
          message: 'It may have been deleted.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit dhikr' : 'New dhikr')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xs, Space.gutter, Space.xxl),
          children: [
            // Live preview.
            Container(
              padding: const EdgeInsets.symmetric(vertical: Space.lg, horizontal: Space.md),
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: ListenableBuilder(
                listenable: Listenable.merge([_arabic, _transliteration, _translation]),
                builder: (context, _) => Column(
                  children: [
                    if (_arabic.text.trim().isNotEmpty) ArabicText(_arabic.text.trim(), size: 30),
                    Text(
                      _transliteration.text.trim().isEmpty ? 'Transliteration' : _transliteration.text.trim(),
                      style: text.titleMedium!.copyWith(
                        color: _transliteration.text.trim().isEmpty ? c.textTertiary : c.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_translation.text.trim().isNotEmpty)
                      Text(_translation.text.trim(), style: text.bodyMedium, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.xl),
            TextFormField(
              controller: _arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: AppFonts.arabic, fontSize: 22, height: 1.6),
              decoration: const InputDecoration(
                labelText: 'Arabic text (optional)',
                helperText: 'Shown right-to-left in an Arabic typeface',
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _transliteration,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Transliteration or name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter a name or transliteration' : null,
              maxLength: 80,
            ),
            const SizedBox(height: Space.xs),
            TextFormField(
              controller: _translation,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Translation or meaning (optional)'),
              maxLines: 3,
              minLines: 1,
              maxLength: 240,
            ),
            const SizedBox(height: Space.xs),
            TextFormField(
              controller: _target,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              decoration: const InputDecoration(
                labelText: 'Default repetitions per round (optional)',
                helperText: 'Leave empty to use your default round size',
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null;
                final n = int.tryParse(t);
                if (n == null || n < 1 || n > 100000) return 'Enter a number between 1 and 100,000';
                return null;
              },
            ),
            const SizedBox(height: Space.xl),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEdit ? 'Save changes' : 'Add to library'),
            ),
          ],
        ),
      ),
    );
  }
}
