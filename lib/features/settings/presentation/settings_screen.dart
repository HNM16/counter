import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/common.dart';
import '../../tasbih/presentation/tasbih_controller.dart';
import '../../tasbih/presentation/tasbih_sheets.dart';
import '../domain/app_settings.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final text = Theme.of(context).textTheme;
    final c = context.colors;

    final look = s.counterMode == CounterMode.beads
        ? '${s.beadMaterial.label}  ·  ${s.tasbihStyle.label}  ·  ${s.beadCount} beads'
        : '${s.digitalDesign.label}  ·  ${s.digitalLayout.label}';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, 0),
              child: Text('Settings', style: text.headlineLarge),
            ),
            const SectionHeader('Personalize'),
            ListTile(
              leading: Icon(Icons.palette_outlined, color: c.accent),
              title: const Text('Customization studio'),
              subtitle: Text(look),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.customize),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xs, Space.gutter, Space.xs),
              child: SegmentedButton<AppThemeMode>(
                showSelectedIcon: false,
                segments: [
                  for (final m in AppThemeMode.values)
                    ButtonSegment(
                      value: m,
                      label: Text(m.label),
                      icon: Icon(switch (m) {
                        AppThemeMode.system => Icons.brightness_auto_outlined,
                        AppThemeMode.light => Icons.light_mode_outlined,
                        AppThemeMode.dark => Icons.dark_mode_outlined,
                      }, size: 18),
                    ),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (v) => ctrl.update((x) => x.copyWith(themeMode: v.first)),
              ),
            ),
            const SectionHeader('Counting'),
            ListTile(
              leading: const Icon(Icons.adjust),
              title: const Text('Default round size'),
              subtitle: Text('${s.defaultTarget} repetitions, for dhikr without a suggested number'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final t = await showTargetPicker(context, current: s.defaultTarget);
                if (t != null) await ctrl.update((x) => x.copyWith(defaultTarget: t));
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: const Text('Vibration'),
              subtitle: const Text('Haptic feedback while counting'),
              value: s.hapticsEnabled,
              onChanged: (v) => ctrl.update((x) => x.copyWith(hapticsEnabled: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.volume_up_outlined),
              title: const Text('Sound'),
              subtitle: const Text('Bead click and round chime'),
              value: s.soundEnabled,
              onChanged: (v) => ctrl.update((x) => x.copyWith(soundEnabled: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.translate),
              title: const Text('Show transliteration'),
              value: s.showTransliteration,
              onChanged: (v) => ctrl.update((x) => x.copyWith(showTransliteration: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.short_text),
              title: const Text('Show translation'),
              value: s.showTranslation,
              onChanged: (v) => ctrl.update((x) => x.copyWith(showTranslation: v)),
            ),
            const SectionHeader('Your practice'),
            _NavTile(icon: Icons.menu_book_outlined, title: 'Dhikr library', route: Routes.library),
            _NavTile(icon: Icons.flag_outlined, title: 'Daily goals', route: Routes.goals),
            _NavTile(icon: Icons.notifications_none_rounded, title: 'Reminders', route: Routes.reminders),
            _NavTile(icon: Icons.history, title: 'History', route: Routes.history),
            const SectionHeader('Data'),
            ListTile(
              leading: Icon(Icons.delete_sweep_outlined, color: c.danger),
              title: Text('Clear all history', style: TextStyle(color: c.danger)),
              subtitle: const Text('Removes every session and statistic from this device'),
              onTap: () async {
                final ok = await confirmAction(
                  context,
                  title: 'Clear all history?',
                  message:
                      'Every session, statistic and record will be permanently deleted from this device. '
                      'Your library, goals and settings are kept.',
                  confirmLabel: 'Clear history',
                  destructive: true,
                );
                if (!ok) return;
                await ref.read(tasbihControllerProvider.notifier).clearAllHistory();
                if (context.mounted) showToast(context, 'History cleared');
              },
            ),
            const SectionHeader('About'),
            _NavTile(icon: Icons.info_outline, title: 'About Sakina', route: Routes.about),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Open-source licenses'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(context: context, applicationName: 'Sakina'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.title, required this.route});

  final IconData icon;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.push(route),
  );
}
