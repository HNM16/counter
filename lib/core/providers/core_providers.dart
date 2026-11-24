import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../services/haptics_service.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';

/// Provided by bootstrap (or tests) once the instance is ready.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// Provided by bootstrap (or tests) once the database is open.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

final hapticsServiceProvider = Provider<HapticsService>((ref) => const SystemHapticsService());

final soundServiceProvider = Provider<SoundService>((ref) => const SilentSoundService());

final notificationServiceProvider = Provider<NotificationService>((ref) => DisabledNotificationService());

/// Injectable clock so time-dependent logic is testable.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Monotonic revision counters used to refresh read models.
///
/// * [countingRevisionProvider] ticks (debounced) while the user counts.
/// * [structureRevisionProvider] ticks when sessions are finished, deleted or
///   discarded, or when goals/library entries change.
class RevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final countingRevisionProvider = NotifierProvider<RevisionNotifier, int>(RevisionNotifier.new);

final structureRevisionProvider = NotifierProvider<RevisionNotifier, int>(RevisionNotifier.new);

/// Convenience: watch both revisions to refresh on any data change.
final anyRevisionProvider = Provider<(int, int)>(
  (ref) => (ref.watch(countingRevisionProvider), ref.watch(structureRevisionProvider)),
);
