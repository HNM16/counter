import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/database/app_database.dart';
import 'package:sakina/core/providers/core_providers.dart';
import 'package:sakina/core/services/haptics_service.dart';
import 'package:sakina/core/services/notification_service.dart';
import 'package:sakina/core/services/sound_service.dart';
import 'package:sakina/features/dhikr/data/sqlite_dhikr_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens a fresh in-memory database with the production schema.
///
/// [isolate] false runs SQLite on the calling isolate, which keeps database
/// futures resolvable inside widget tests' fake-async zone.
Future<AppDatabase> openTestDatabase({bool isolate = false, bool seed = true}) async {
  sqfliteFfiInit();
  final factory = isolate ? databaseFactoryFfi : databaseFactoryFfiNoIsolate;
  final db = await AppDatabase.open(factory: factory, path: inMemoryDatabasePath);
  if (seed) await SqliteDhikrRepository(db).ensureSeeded();
  return db;
}

/// Records haptic patterns instead of vibrating.
class RecordingHaptics implements HapticsService {
  final played = <HapticPattern>[];

  @override
  Future<void> play(HapticPattern pattern) async => played.add(pattern);
}

/// Records sound cues instead of playing audio.
class RecordingSound implements SoundService {
  final played = <SoundCue>[];

  @override
  Future<void> init() async {}

  @override
  void play(SoundCue cue) => played.add(cue);

  @override
  Future<void> dispose() async {}
}

/// A controllable clock for deterministic time-based tests.
class TestClock {
  TestClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration d) => now = now.add(d);
}

/// Builds a container with every platform dependency replaced by a fake.
Future<ProviderContainer> createTestContainer({
  required AppDatabase database,
  TestClock? clock,
  Map<String, Object> prefs = const {},
  RecordingHaptics? haptics,
  RecordingSound? sound,
  NotificationService? notifications,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  return ProviderContainer.test(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      appDatabaseProvider.overrideWithValue(database),
      hapticsServiceProvider.overrideWithValue(haptics ?? RecordingHaptics()),
      soundServiceProvider.overrideWithValue(sound ?? RecordingSound()),
      notificationServiceProvider.overrideWithValue(notifications ?? DisabledNotificationService()),
      if (clock != null) clockProvider.overrideWithValue(clock.call),
    ],
  );
}

/// Loads the bundled fonts (and Material icons) so widget renders use real
/// typography instead of the test font.
Future<void> loadAppFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File(f).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    }
    await loader.load();
  }

  await load('Amiri', ['assets/fonts/Amiri-Regular.ttf', 'assets/fonts/Amiri-Bold.ttf']);
  await load('Manrope', [
    'assets/fonts/Manrope-Regular.ttf',
    'assets/fonts/Manrope-Medium.ttf',
    'assets/fonts/Manrope-SemiBold.ttf',
    'assets/fonts/Manrope-Bold.ttf',
  ]);
  await load('Cormorant', [
    'assets/fonts/CormorantGaramond-Light.ttf',
    'assets/fonts/CormorantGaramond-Regular.ttf',
    'assets/fonts/CormorantGaramond-Medium.ttf',
    'assets/fonts/CormorantGaramond-SemiBold.ttf',
  ]);
  final sdk = Platform.environment['FLUTTER_ROOT'];
  final icons = sdk == null ? null : File('$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons != null && icons.existsSync()) await load('MaterialIcons', [icons.path]);
}
