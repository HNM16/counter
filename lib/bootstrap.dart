import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/app_database.dart';
import 'core/providers/core_providers.dart';
import 'core/router/app_router.dart';
import 'core/router/routes.dart';
import 'core/services/notification_service.dart';
import 'core/services/sound_service.dart';
import 'features/dhikr/data/sqlite_dhikr_repository.dart';
import 'features/dhikr/presentation/dhikr_providers.dart';
import 'features/reminders/presentation/reminder_providers.dart';
import 'features/tasbih/presentation/tasbih_controller.dart';

/// Opens local storage, wires platform services and returns a ready
/// [ProviderContainer]. Everything is local; no network access is used.
Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in const [
      ('Amiri', 'OFL-Amiri.txt'),
      ('Manrope', 'OFL-Manrope.txt'),
      ('Cormorant Garamond', 'OFL-CormorantGaramond.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([family], await rootBundle.loadString('assets/licenses/$file'));
    }
  });

  final results = await Future.wait([SharedPreferences.getInstance(), AppDatabase.open()]);
  final prefs = results[0] as SharedPreferences;
  final database = results[1] as AppDatabase;
  await SqliteDhikrRepository(database).ensureSeeded();

  final sound = AudioSoundService();
  final notifications = LocalNotificationService();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(database),
      soundServiceProvider.overrideWithValue(sound),
      notificationServiceProvider.overrideWithValue(notifications),
    ],
  );

  // Non-critical services warm up in the background.
  unawaited(sound.init());
  unawaited(_initNotifications(container, notifications));
  return container;
}

Future<void> _initNotifications(ProviderContainer container, NotificationService notifications) async {
  try {
    await notifications.init();
    await container.read(remindersProvider.notifier).rescheduleAll();
    notifications.taps.listen((payload) => _openFromNotification(container, payload));
    final launch = await notifications.launchPayload();
    if (launch != null) await _openFromNotification(container, launch);
  } catch (e, st) {
    debugPrint('Reminders unavailable: $e\n$st');
  }
}

Future<void> _openFromNotification(ProviderContainer container, String payload) async {
  if (payload.startsWith('dhikr:')) {
    final id = payload.substring('dhikr:'.length);
    final dhikr = await container.read(dhikrRepositoryProvider).byId(id);
    if (dhikr != null) {
      await container.read(tasbihControllerProvider.future);
      await container.read(tasbihControllerProvider.notifier).selectDhikr(dhikr);
    }
  }
  container.read(routerProvider).go(Routes.tasbih);
}
