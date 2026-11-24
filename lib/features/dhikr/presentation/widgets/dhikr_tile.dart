import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/arabic_text.dart';
import '../../../../shared/widgets/common.dart';
import '../../../tasbih/presentation/tasbih_controller.dart';
import '../../domain/dhikr.dart';
import '../dhikr_providers.dart';

/// A library entry with Arabic, transliteration, translation, suggested
/// target, optional source and actions.
class DhikrTile extends ConsumerStatefulWidget {
  const DhikrTile({super.key, required this.dhikr});

  final Dhikr dhikr;

  @override
  ConsumerState<DhikrTile> createState() => _DhikrTileState();
}

class _DhikrTileState extends ConsumerState<DhikrTile> {
  bool _showSource = false;

  Future<void> _start() async {
    final d = widget.dhikr;
    final saved = await ref.read(tasbihControllerProvider.notifier).selectDhikr(d, target: d.suggestedCount);
    if (!mounted) return;
    context.go(Routes.tasbih);
    if (saved) showToast(context, 'Previous session saved to history');
  }

  Future<void> _delete() async {
    final ok = await confirmAction(
      context,
      title: 'Delete "${widget.dhikr.transliteration}"?',
      message: 'It will be removed from your library along with its goals. Your history is kept.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok) await ref.read(dhikrLibraryProvider.notifier).delete(widget.dhikr);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dhikr;
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.xs, Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (d.arabic.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: Space.sm),
              child: ArabicText(d.arabic, size: 28, textAlign: TextAlign.right),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.transliteration, style: text.titleMedium),
                    if (d.translation.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(d.translation, style: text.bodyMedium),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: d.isFavorite ? 'Remove from favourites' : 'Add to favourites',
                onPressed: () => ref.read(dhikrLibraryProvider.notifier).toggleFavorite(d),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                  child: Icon(
                    d.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    key: ValueKey(d.isFavorite),
                    color: d.isFavorite ? c.gold : c.textTertiary,
                  ),
                ),
              ),
              if (d.isCustom)
                PopupMenuButton<String>(
                  tooltip: 'More',
                  icon: Icon(Icons.more_vert, color: c.textSecondary),
                  onSelected: (v) => v == 'edit' ? context.push(Routes.editDhikr(d.id)) : _delete(),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Padding(
            padding: const EdgeInsets.only(right: Space.sm),
            child: Row(
              children: [
                Flexible(child: _TargetChip(count: d.suggestedCount)),
                if (d.reference != null)
                  IconButton(
                    tooltip: _showSource ? 'Hide source' : 'Show source',
                    onPressed: () => setState(() => _showSource = !_showSource),
                    isSelected: _showSource,
                    icon: Icon(Icons.info_outline, color: c.textSecondary, size: 20),
                    selectedIcon: Icon(Icons.info, color: c.accent, size: 20),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _start,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.only(left: 12, right: 16),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Start'),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _showSource && d.reference != null
                ? Padding(
                    padding: const EdgeInsets.only(top: Space.xs, right: Space.sm),
                    child: Container(
                      padding: const EdgeInsets.all(Space.sm),
                      decoration: BoxDecoration(
                        color: c.surfaceMuted,
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Text(d.reference!, style: text.bodySmall),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: Space.xs),
          Divider(color: c.hairline, height: 1, endIndent: Space.sm),
        ],
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: c.hairline),
      ),
      child: Text(
        count == null ? 'No fixed number' : 'Suggested $count',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.labelMedium!.copyWith(color: count == null ? c.textTertiary : c.textPrimary),
      ),
    );
  }
}
