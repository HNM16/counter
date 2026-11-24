import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakina/app.dart';
import 'package:sakina/core/router/app_router.dart';
import 'package:sakina/core/router/routes.dart';
import 'package:sakina/features/dhikr/presentation/widgets/dhikr_tile.dart';
import 'package:sakina/features/settings/domain/app_settings.dart';
import 'package:sakina/features/settings/presentation/settings_controller.dart';
import 'package:sakina/features/tasbih/presentation/tasbih_controller.dart';
import 'package:sakina/features/tasbih/widgets/beads/bead_tasbih_view.dart';
import 'package:sakina/features/tasbih/widgets/digital/digital_counter_view.dart';

import '../support/harness.dart';

void main() {
  late TestClock clock;

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    clock = TestClock(DateTime(2026, 6, 10, 7));
    final db = (await tester.runAsync(() => openTestDatabase()))!;
    final container = (await tester.runAsync(() => createTestContainer(database: db, clock: clock)))!;
    addTearDown(() => tester.runAsync(db.close));
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SakinaApp()));
    await _settle(tester);
    return container;
  }

  int total(ProviderContainer c) => c.read(tasbihControllerProvider).requireValue.session.totalCount;

  Future<void> tapCounter(WidgetTester tester, Type view) async {
    clock.advance(const Duration(milliseconds: 500));
    await tester.tap(find.byType(view));
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('start from home, count, undo and reset with confirmation', (tester) async {
    final c = await pumpApp(tester);

    expect(find.text('Start Tasbih'), findsOneWidget);
    await tester.tap(find.text('Start Tasbih'));
    await _settle(tester);
    expect(find.byType(BeadTasbihView), findsOneWidget);
    expect(find.text('Subhan Allah'), findsWidgets);

    for (var i = 0; i < 3; i++) {
      await tapCounter(tester, BeadTasbihView);
    }
    await _settle(tester);
    expect(total(c), 3);
    expect(find.text('3 total'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await _settle(tester);
    expect(total(c), 2);

    // Reset requires confirmation; cancelling keeps the count.
    await tester.tap(find.byTooltip('More'));
    await _settle(tester);
    await tester.tap(find.text('Reset counter'));
    await _settle(tester);
    expect(find.text('Reset counter?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);
    expect(total(c), 2);

    await tester.tap(find.byTooltip('More'));
    await _settle(tester);
    await tester.tap(find.text('Reset counter'));
    await _settle(tester);
    await tester.tap(find.text('Discard'));
    await _settle(tester);
    expect(total(c), 0);

    await _teardown(tester);
  });

  testWidgets('pause blocks counting until resumed', (tester) async {
    final c = await pumpApp(tester);
    c.read(routerProvider).go(Routes.tasbih);
    await _settle(tester);

    await tapCounter(tester, BeadTasbihView);
    await tester.tap(find.bySemanticsLabel('Pause'));
    await _settle(tester);
    expect(find.text('PAUSED'), findsOneWidget);

    await tapCounter(tester, BeadTasbihView); // resumes, does not count
    await _settle(tester);
    expect(total(c), 1);
    await tapCounter(tester, BeadTasbihView);
    await _settle(tester);
    expect(total(c), 2);

    await _teardown(tester);
  });

  testWidgets('switching to the digital counter keeps the count', (tester) async {
    final c = await pumpApp(tester);
    c.read(routerProvider).go(Routes.tasbih);
    await _settle(tester);
    await tapCounter(tester, BeadTasbihView);
    await tapCounter(tester, BeadTasbihView);

    await tester.tap(find.text('Digital'));
    await _settle(tester);
    expect(c.read(settingsProvider).counterMode, CounterMode.digital);
    expect(find.byType(DigitalCounterView), findsOneWidget);

    await tapCounter(tester, DigitalCounterView);
    await _settle(tester);
    expect(total(c), 3);

    await _teardown(tester);
  });

  testWidgets('starting a dhikr from the library opens the counter with it', (tester) async {
    final c = await pumpApp(tester);
    c.read(routerProvider).push(Routes.library);
    await _settle(tester);
    expect(find.text('Dhikr library'), findsOneWidget);

    final tile = find.widgetWithText(DhikrTile, 'Alhamdulillah');
    await tester.ensureVisible(tile);
    await _settle(tester);
    final start = find.descendant(of: tile, matching: find.text('Start'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await _settle(tester);
    expect(c.read(tasbihControllerProvider).requireValue.session.dhikrId, 'alhamdulillah');
    expect(find.byType(BeadTasbihView), findsOneWidget);

    await _teardown(tester);
  });

  testWidgets('every main tab renders', (tester) async {
    await pumpApp(tester);
    for (final label in ['Statistics', 'Settings', 'Tasbih', 'Home']) {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
      await _settle(tester);
      expect(tester.takeException(), isNull, reason: label);
    }
    await _teardown(tester);
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Unmounts the app so timers and animations stop before the test ends.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}
