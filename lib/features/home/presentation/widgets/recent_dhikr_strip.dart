import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/arabic_text.dart';
import '../../../../shared/widgets/common.dart';
import '../../../dhikr/domain/dhikr.dart';
import '../../../dhikr/presentation/dhikr_providers.dart';
import '../../../statistics/presentation/stats_providers.dart';
import '../../../tasbih/presentation/tasbih_controller.dart';

/// Horizontally scrolling shortcuts to recently used dhikr (or, for new
/// users, the first entries of the library).
class RecentDhikrStrip extends ConsumerWidget {
  const RecentDhikrStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentIds = ref.watch(recentDhikrIdsProvider).value ?? const <String>[];
    final library = ref.watch(dhikrLibraryProvider).value ?? const <Dhikr>[];
    final byId = {for (final d in library) d.id: d};
    final recent = [for (final id in recentIds) ?byId[id]];
    final items = recent.isNotEmpty ? recent : library.take(4).toList();

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: Space.pagePadding,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
        itemBuilder: (context, i) => _RecentCard(dhikr: items[i]),
      ),
    );
  }
}

class _RecentCard extends ConsumerWidget {
  const _RecentCard({required this.dhikr});

  final Dhikr dhikr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Pressable(
      semanticLabel: 'Count ${dhikr.transliteration}',
      onTap: () async {
        final saved = await ref.read(tasbihControllerProvider.notifier).selectDhikr(dhikr);
        if (!context.mounted) return;
        context.go(Routes.tasbih);
        if (saved) showToast(context, 'Previous session saved to history');
      },
      child: Container(
        width: 156,
        padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.md, Space.sm),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: c.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(child: ArabicText(dhikr.arabic, size: 21, maxLines: 1, color: c.textPrimary)),
            ),
            Text(
              dhikr.transliteration,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: text.labelMedium!.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
