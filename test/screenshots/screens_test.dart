// Renders every main screen to PNG for design review.
//
// Run with:  SAKINA_SCREENSHOTS=1 flutter test test/screenshots
// Output:    build/screenshots/*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakina/app.dart';
import 'package:sakina/core/router/app_router.dart';
import 'package:sakina/core/router/routes.dart';
import 'package:sakina/features/settings/domain/app_settings.dart';
import 'package:sakina/features/settings/presentation/settings_controller.dart';
import 'package:sakina/features/tasbih/presentation/tasbih_controller.dart';

import '../support/harness.dart';
import '../support/seed.dart';

final _enabled = Platform.environment.containsKey('SAKINA_SCREENSHOTS');
final _boundary = GlobalKey();

class _Device {
  const _Device(this.name, this.size);

  final String name;
  final Size size;
}

const _devices = [_Device('phone', Size(390, 844)), _Device('small', Size(360, 640))];

Future<void> _settle(WidgetTester tester, {int frames = 30}) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 4)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  final error = tester.takeException();
  if (error != null) {
    // ignore: avoid_print
    print('Exception before screenshot $name: $error');
  }
  await tester.runAsync(() async {
    final boundary = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/screenshots/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  for (final device in _devices) {
    testWidgets('screens on ${device.name}', (tester) async {
      await loadAppFonts();
      tester.view.physicalSize = device.size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      final now = DateTime.now();
      final db = (await tester.runAsync(() => openTestDatabase()))!;
      await tester.runAsync(() => seedSampleHistory(db, now));
      final clock = TestClock(now);
      final container = (await tester.runAsync(() => createTestContainer(database: db, clock: clock)))!;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(key: _boundary, child: const SakinaApp()),
        ),
      );
      await _settle(tester);

      final router = container.read(routerProvider);
      final settings = container.read(settingsProvider.notifier);
      final p = device.name;

      // Count a little so the counter and today's progress have content.
      await tester.runAsync(() => container.read(tasbihControllerProvider.future));
      for (var i = 0; i < 21; i++) {
        clock.advance(const Duration(milliseconds: 900));
        container.read(tasbihControllerProvider.notifier).increment();
        await tester.pump(const Duration(milliseconds: 120));
      }
      await _settle(tester);

      await _shot(tester, '$p-01-home');

      router.go(Routes.tasbih);
      await _settle(tester);
      await _shot(tester, '$p-02-tasbih-ring-walnut');

      await tester.runAsync(
        () => settings.update(
          (s) => s.copyWith(tasbihStyle: TasbihStyle.strand, beadMaterial: BeadMaterial.turquoise),
        ),
      );
      await _settle(tester);
      await _shot(tester, '$p-03-tasbih-strand-turquoise');

      await tester.runAsync(
        () => settings.update(
          (s) => s.copyWith(
            tasbihStyle: TasbihStyle.ring,
            beadCount: 99,
            beadMaterial: BeadMaterial.amethyst,
            tasbihBackground: TasbihBackground.forest,
          ),
        ),
      );
      await _settle(tester);
      await _shot(tester, '$p-04-tasbih-ring99-amethyst-forest');

      await tester.runAsync(
        () => settings.update(
          (s) => s.copyWith(
            beadCount: 33,
            beadMaterial: BeadMaterial.marble,
            tasbihBackground: TasbihBackground.night,
          ),
        ),
      );
      await _settle(tester);
      await _shot(tester, '$p-05-tasbih-marble-night');

      // Reach the seeded 33 x Subhan Allah goal to capture the celebration.
      for (var i = 0; i < 12; i++) {
        clock.advance(const Duration(milliseconds: 900));
        container.read(tasbihControllerProvider.notifier).increment();
        await tester.pump(const Duration(milliseconds: 60));
      }
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      await _shot(tester, '$p-05b-goal-celebration');
      await _settle(tester, frames: 80);

      for (final (i, design, layout) in [
        (6, DigitalDesign.minimalWhite, DigitalLayout.ring),
        (7, DigitalDesign.premiumBlack, DigitalLayout.classic),
        (8, DigitalDesign.emerald, DigitalLayout.device),
        (9, DigitalDesign.warmBeige, DigitalLayout.device),
      ]) {
        await tester.runAsync(
          () => settings.update(
            (s) => s.copyWith(counterMode: CounterMode.digital, digitalDesign: design, digitalLayout: layout),
          ),
        );
        await _settle(tester);
        await _shot(tester, '$p-0$i-digital-${design.name}-${layout.name}');
      }

      router.go(Routes.stats);
      await _settle(tester);
      await _shot(tester, '$p-10-statistics');

      router.go(Routes.settings);
      await _settle(tester);
      await _shot(tester, '$p-11-settings');

      router.push(Routes.library);
      await _settle(tester);
      await _shot(tester, '$p-12-library');
      router.pop();

      router.push(Routes.customize);
      await _settle(tester);
      await _shot(tester, '$p-13-customize');
      router.pop();

      router.push(Routes.goals);
      await _settle(tester);
      await _shot(tester, '$p-14-goals');
      router.pop();

      router.push(Routes.history);
      await _settle(tester);
      await _shot(tester, '$p-15-history');
      router.pop();

      await tester.runAsync(() => settings.update((s) => s.copyWith(themeMode: AppThemeMode.dark)));
      router.go(Routes.home);
      await _settle(tester);
      await _shot(tester, '$p-16-home-dark');

      router.go(Routes.stats);
      await _settle(tester);
      await _shot(tester, '$p-17-statistics-dark');

      // Tear down the tree so periodic timers (live previews, clocks) stop.
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => db.close());
    }, skip: !_enabled);
  }
}
