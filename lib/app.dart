import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/settings_controller.dart';
import 'features/tasbih/presentation/tasbih_controller.dart';

class SakinaApp extends ConsumerStatefulWidget {
  const SakinaApp({super.key});

  @override
  ConsumerState<SakinaApp> createState() => _SakinaAppState();
}

class _SakinaAppState extends ConsumerState<SakinaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Make sure every count is on disk before the OS may suspend the app.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final controller = ref.read(tasbihControllerProvider);
      if (controller.hasValue) ref.read(tasbihControllerProvider.notifier).flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Sakina',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.accent),
      darkTheme: AppTheme.dark(settings.accent),
      themeMode: settings.themeMode.themeMode,
      routerConfig: router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final scaler = TextScaler.linear(media.textScaler.scale(1) * settings.textScale);
        return MediaQuery(
          data: media.copyWith(textScaler: scaler.clamp(maxScaleFactor: 1.8)),
          child: child!,
        );
      },
    );
  }
}
