import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/common.dart';
import '../domain/dhikr.dart';
import 'dhikr_providers.dart';
import 'widgets/dhikr_tile.dart';

class DhikrLibraryScreen extends ConsumerStatefulWidget {
  const DhikrLibraryScreen({super.key});

  @override
  ConsumerState<DhikrLibraryScreen> createState() => _DhikrLibraryScreenState();
}

class _DhikrLibraryScreenState extends ConsumerState<DhikrLibraryScreen> {
  String _query = '';

  bool _matches(Dhikr d) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return d.transliteration.toLowerCase().contains(q) ||
        d.translation.toLowerCase().contains(q) ||
        d.arabic.contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final library = ref.watch(dhikrLibraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dhikr library'),
        actions: [
          IconButton(
            tooltip: 'Create dhikr',
            onPressed: () => context.push(Routes.newDhikr),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: library.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load the library.\n$e', textAlign: TextAlign.center)),
        data: (items) {
          final filtered = items.where(_matches).toList();
          final favorites = filtered.where((d) => d.isFavorite).toList();
          final builtIn = filtered.where((d) => !d.isCustom && !d.isFavorite).toList();
          final custom = filtered.where((d) => d.isCustom && !d.isFavorite).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: Space.xxxl),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xs, Space.gutter, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by name, meaning or Arabic',
                    prefixIcon: Icon(Icons.search, color: c.textTertiary),
                  ),
                ),
              ),
              if (filtered.isEmpty)
                EmptyState(
                  icon: Icons.search_off,
                  title: 'Nothing found',
                  message: 'Try another word, or create your own dhikr.',
                  action: FilledButton(onPressed: () => context.push(Routes.newDhikr), child: const Text('Create dhikr')),
                ),
              if (favorites.isNotEmpty) ...[
                const SectionHeader('Favourites'),
                for (final d in favorites) DhikrTile(dhikr: d),
              ],
              if (builtIn.isNotEmpty) ...[
                const SectionHeader('Essential dhikr'),
                for (final d in builtIn) DhikrTile(dhikr: d),
              ],
              const SectionHeader('Your dhikr'),
              if (custom.isEmpty && _query.isEmpty)
                Padding(
                  padding: Space.pagePadding,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(Routes.newDhikr),
                    icon: Icon(Icons.add, color: c.accent),
                    label: const Text('Create your own dhikr'),
                  ),
                ),
              for (final d in custom) DhikrTile(dhikr: d),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xxl, Space.gutter, 0),
                child: Text(
                  'Suggested numbers are shown only where a well-known narration mentions one; otherwise choose '
                  'your own. Sources are provided for further reading. Please consult a qualified scholar for '
                  'religious guidance.',
                  style: text.bodySmall!.copyWith(color: c.textTertiary),
                ),
              ),
            ].animate(interval: 25.ms).fadeIn(duration: 260.ms),
          );
        },
      ),
    );
  }
}
