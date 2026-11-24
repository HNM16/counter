import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

/// Single source of truth for preferences. Updates apply instantly in memory
/// and are written through to disk.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> update(AppSettings Function(AppSettings current) change) async {
    final next = change(state);
    if (next == state) return;
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  Future<void> resetAppearance() => update(
    (s) => const AppSettings().copyWith(
      lastDhikrId: s.lastDhikrId,
      defaultTarget: s.defaultTarget,
      hapticsEnabled: s.hapticsEnabled,
      soundEnabled: s.soundEnabled,
    ),
  );
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
