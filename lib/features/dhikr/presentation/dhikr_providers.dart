import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/sqlite_dhikr_repository.dart';
import '../domain/dhikr.dart';

final dhikrRepositoryProvider = Provider<DhikrRepository>(
  (ref) => SqliteDhikrRepository(ref.watch(appDatabaseProvider), clock: ref.watch(clockProvider)),
);

class DhikrLibrary extends AsyncNotifier<List<Dhikr>> {
  DhikrRepository get _repo => ref.read(dhikrRepositoryProvider);

  @override
  Future<List<Dhikr>> build() => ref.watch(dhikrRepositoryProvider).all();

  Future<void> _reload() async {
    final items = await _repo.all();
    if (ref.mounted) state = AsyncData(items);
    ref.read(structureRevisionProvider.notifier).bump();
  }

  Future<Dhikr> create({
    required String arabic,
    required String transliteration,
    required String translation,
    int? suggestedCount,
  }) async {
    final created = await _repo.create(
      arabic: arabic,
      transliteration: transliteration,
      translation: translation,
      suggestedCount: suggestedCount,
    );
    await _reload();
    return created;
  }

  Future<void> save(Dhikr dhikr) async {
    await _repo.update(dhikr);
    await _reload();
  }

  Future<void> toggleFavorite(Dhikr dhikr) => save(dhikr.copyWith(isFavorite: !dhikr.isFavorite));

  Future<void> delete(Dhikr dhikr) async {
    if (!dhikr.isCustom) return;
    await _repo.delete(dhikr.id);
    await _reload();
  }
}

final dhikrLibraryProvider = AsyncNotifierProvider<DhikrLibrary, List<Dhikr>>(DhikrLibrary.new);

/// Fast lookup by id for widgets that only hold an id.
final dhikrByIdProvider = Provider.family<Dhikr?, String>((ref, id) {
  final list = ref.watch(dhikrLibraryProvider).value;
  return list?.where((d) => d.id == id).firstOrNull;
});
