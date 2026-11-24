import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../features/settings/presentation/settings_controller.dart';
import '../../features/tasbih/presentation/tasbih_chrome.dart';
import '../../features/tasbih/widgets/mode_toggle.dart';

/// Bottom navigation shell hosting the four main sections.
///
/// While the Tasbih tab is open the bar takes on the counter's palette so the
/// counting surface reads as one calm, uninterrupted space.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  static const tasbihIndex = 1;

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final immersive = shell.currentIndex == tasbihIndex;
    final chrome = immersive ? TasbihChrome.of(ref.watch(settingsProvider)) : null;
    final base = Theme.of(context);
    var c = context.colors;
    var theme = base;
    if (chrome != null) {
      theme = base.copyWith(
        navigationBarTheme: base.navigationBarTheme.copyWith(
          backgroundColor: chrome.background,
          indicatorColor: chrome.foreground.withValues(alpha: 0.1),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => base.textTheme.labelMedium!.copyWith(
              color: s.contains(WidgetState.selected) ? chrome.foreground : chrome.secondary,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(color: s.contains(WidgetState.selected) ? chrome.accent : chrome.secondary, size: 24),
          ),
        ),
      );
      c = c.copyWith(accent: chrome.accent);
    }
    final hairline = chrome == null ? c.hairline : chrome.foreground.withValues(alpha: 0.08);
    final inactiveIcon = chrome?.secondary ?? c.textTertiary;

    return Scaffold(
      body: shell,
      bottomNavigationBar: Theme(
        data: theme,
        child: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: hairline))),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: BeadsGlyph(color: inactiveIcon),
              selectedIcon: BeadsGlyph(color: c.accent),
              label: 'Tasbih',
            ),
            const NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Statistics',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
      ),
    );
  }
}
