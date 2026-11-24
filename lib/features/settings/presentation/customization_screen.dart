import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/arabic_text.dart';
import '../../../shared/widgets/color_picker.dart';
import '../../../shared/widgets/common.dart';
import '../../tasbih/widgets/beads/bead_spec.dart';
import '../../tasbih/widgets/digital/digital_palette.dart';
import '../domain/app_settings.dart';
import 'settings_controller.dart';
import 'widgets/live_previews.dart';

/// The customization studio: every visual choice, with live previews.
class CustomizationScreen extends ConsumerWidget {
  const CustomizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider.select((s) => s.counterMode));
    return DefaultTabController(
      length: 3,
      initialIndex: mode == CounterMode.beads ? 0 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customize'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bead tasbih'),
              Tab(text: 'Digital'),
              Tab(text: 'App'),
            ],
          ),
        ),
        body: const TabBarView(children: [_BeadsTab(), _DigitalTab(), _AppTab()]),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => SectionHeader(text, padding: const EdgeInsets.fromLTRB(0, Space.xl, 0, Space.sm));
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.title, required this.subtitle, required this.selected, required this.onTap});

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: selected ? c.accent : c.hairline, width: selected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: text.titleSmall)),
                  if (selected) Icon(Icons.check_circle, size: 18, color: c.accent),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Preview pinned above a scrolling list of options.
class _StudioTab extends StatelessWidget {
  const _StudioTab({required this.preview, required this.children});

  final Widget preview;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final previewHeight = (height * 0.32).clamp(220.0, 320.0);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.xs),
          child: SizedBox(height: previewHeight, child: preview),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xxxl),
            children: children,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- beads

class _BeadsTab extends ConsumerWidget {
  const _BeadsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final text = Theme.of(context).textTheme;
    final c = context.colors;

    return _StudioTab(
      preview: BeadLivePreview(settings: s),
      children: [
        const _Label('Style'),
        Row(
          children: [
            for (final (i, st) in TasbihStyle.values.indexed) ...[
              if (i > 0) const SizedBox(width: Space.sm),
              Expanded(
                child: _OptionCard(
                  title: st.label,
                  subtitle: st.description,
                  selected: s.tasbihStyle == st,
                  onTap: () => ctrl.update((x) => x.copyWith(tasbihStyle: st)),
                ),
              ),
            ],
          ],
        ),
        const _Label('Material'),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.78,
          children: [
            for (final m in BeadMaterial.values)
              Semantics(
                button: true,
                selected: s.beadMaterial == m,
                label: m.label,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => ctrl.update((x) => x.copyWith(beadMaterial: m, clearBeadTint: true)),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: Motion.fast,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: s.beadMaterial == m ? c.accent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: BeadSwatch(spec: BeadSpec.of(m), size: 46),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: text.bodySmall!.copyWith(
                          fontSize: 11,
                          height: 1.2,
                          color: s.beadMaterial == m ? c.textPrimary : c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const _Label('Color'),
        Wrap(
          spacing: 2,
          runSpacing: 2,
          children: [
            ColorSwatchButton(
              color: BeadSpec.naturalColor(s.beadMaterial),
              selected: s.beadTint == null,
              label: 'Natural color',
              onTap: () => ctrl.update((x) => x.copyWith(clearBeadTint: true)),
              child: const Center(child: Icon(Icons.eco_outlined, size: 16, color: Colors.white70)),
            ),
            for (final t in BeadTints.options)
              ColorSwatchButton(
                color: t,
                selected: s.beadTint == t,
                label: 'Bead color ${ColorTools.toHex(t)}',
                onTap: () => ctrl.update((x) => x.copyWith(beadTint: t)),
              ),
            ColorSwatchButton(
              color: c.surfaceMuted,
              selected: s.beadTint != null && !BeadTints.options.contains(s.beadTint),
              label: 'Custom bead color',
              onTap: () async {
                final picked = await showColorPicker(
                  context,
                  initial: s.beadTint ?? BeadSpec.naturalColor(s.beadMaterial),
                  title: 'Bead color',
                );
                if (picked != null) await ctrl.update((x) => x.copyWith(beadTint: picked));
              },
              child: Icon(Icons.colorize, size: 18, color: c.textSecondary),
            ),
          ],
        ),
        const _Label('Bead size'),
        SegmentedButton<BeadSize>(
          showSelectedIcon: false,
          segments: [for (final b in BeadSize.values) ButtonSegment(value: b, label: Text(b.label))],
          selected: {s.beadSize},
          onSelectionChanged: (v) => ctrl.update((x) => x.copyWith(beadSize: v.first)),
        ),
        const _Label('Number of beads'),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 33, label: Text('33 beads')),
            ButtonSegment(value: 99, label: Text('99 beads')),
          ],
          selected: {s.beadCount},
          onSelectionChanged: (v) => ctrl.update((x) => x.copyWith(beadCount: v.first)),
        ),
        const SizedBox(height: Space.xs),
        Text(
          'A 99-bead tasbih is divided into thirds by two spacers. Your repetitions per round are set separately '
          'on the counter.',
          style: text.bodySmall,
        ),
        const _Label('Background'),
        SizedBox(
          height: 112,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final b in TasbihBackground.values)
                Padding(
                  padding: const EdgeInsets.only(right: Space.sm),
                  child: Semantics(
                    button: true,
                    selected: s.tasbihBackground == b,
                    label: '${b.label} background',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => ctrl.update((x) => x.copyWith(tasbihBackground: b)),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: Motion.fast,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Radii.sm + 2),
                              border: Border.all(
                                color: s.tasbihBackground == b ? c.accent : c.hairline,
                                width: s.tasbihBackground == b ? 2 : 1,
                              ),
                            ),
                            child: BackdropSwatch(background: b),
                          ),
                          const SizedBox(height: 4),
                          Text(b.label, style: text.bodySmall!.copyWith(fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------- digital

class _DigitalTab extends ConsumerWidget {
  const _DigitalTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final text = Theme.of(context).textTheme;
    final c = context.colors;

    return _StudioTab(
      preview: DigitalLivePreview(settings: s),
      children: [
        const _Label('Design'),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final d in DigitalDesign.values)
              Builder(
                builder: (context) {
                  final p = DigitalPalette.of(s.copyWith(digitalDesign: d));
                  final selected = s.digitalDesign == d;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: '${d.label} design',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => ctrl.update((x) => x.copyWith(digitalDesign: d)),
                      child: AnimatedContainer(
                        duration: Motion.fast,
                        width: 104,
                        padding: const EdgeInsets.all(Space.sm),
                        decoration: BoxDecoration(
                          color: p.background,
                          borderRadius: BorderRadius.circular(Radii.md),
                          border: Border.all(color: selected ? c.accent : c.hairline, width: selected ? 2 : 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('33', style: text.titleLarge!.copyWith(color: p.text)),
                                const Spacer(),
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                            const SizedBox(height: Space.xs),
                            Text(
                              d.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall!.copyWith(color: p.subtext, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        if (s.digitalDesign == DigitalDesign.custom) ...[
          const _Label('Custom colors'),
          Row(
            children: [
              Expanded(
                child: _ColorRow(
                  label: 'Background',
                  color: s.customDigitalBackground,
                  onTap: () async {
                    final picked = await showColorPicker(context, initial: s.customDigitalBackground, title: 'Background');
                    if (picked != null) await ctrl.update((x) => x.copyWith(customDigitalBackground: picked));
                  },
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: _ColorRow(
                  label: 'Accent',
                  color: s.customDigitalAccent,
                  onTap: () async {
                    final picked = await showColorPicker(context, initial: s.customDigitalAccent, title: 'Accent');
                    if (picked != null) await ctrl.update((x) => x.copyWith(customDigitalAccent: picked));
                  },
                ),
              ),
            ],
          ),
        ],
        const _Label('Layout'),
        for (final l in DigitalLayout.values)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: _OptionCard(
              title: l.label,
              subtitle: l.description,
              selected: s.digitalLayout == l,
              onTap: () => ctrl.update((x) => x.copyWith(digitalLayout: l)),
            ),
          ),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: c.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: text.titleSmall),
                  Text(ColorTools.toHex(color), style: text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ app

class _AppTab extends ConsumerWidget {
  const _AppTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final text = Theme.of(context).textTheme;
    final c = context.colors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xxxl),
      children: [
        const _Label('Theme'),
        SegmentedButton<AppThemeMode>(
          showSelectedIcon: false,
          segments: [for (final m in AppThemeMode.values) ButtonSegment(value: m, label: Text(m.label))],
          selected: {s.themeMode},
          onSelectionChanged: (v) => ctrl.update((x) => x.copyWith(themeMode: v.first)),
        ),
        const _Label('Accent color'),
        Wrap(
          spacing: 2,
          runSpacing: 2,
          children: [
            for (final a in AppPalette.accents)
              ColorSwatchButton(
                color: a,
                selected: s.accent == a,
                label: 'Accent ${ColorTools.toHex(a)}',
                onTap: () => ctrl.update((x) => x.copyWith(accent: a)),
              ),
            ColorSwatchButton(
              color: c.surfaceMuted,
              selected: !AppPalette.accents.contains(s.accent),
              label: 'Custom accent color',
              onTap: () async {
                final picked = await showColorPicker(context, initial: s.accent, title: 'Accent color');
                if (picked != null) await ctrl.update((x) => x.copyWith(accent: picked));
              },
              child: Icon(Icons.colorize, size: 18, color: c.textSecondary),
            ),
          ],
        ),
        const _Label('Arabic text size'),
        Container(
          padding: const EdgeInsets.symmetric(vertical: Space.sm),
          decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(Radii.md)),
          child: const ArabicText('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', size: 28),
        ),
        Slider(
          value: s.arabicScale,
          min: AppSettings.minArabicScale,
          max: AppSettings.maxArabicScale,
          divisions: 13,
          label: '${(s.arabicScale * 100).round()}%',
          onChanged: (v) => ctrl.update((x) => x.copyWith(arabicScale: v)),
        ),
        const _Label('Interface text size'),
        Text('The quick brown fox remembers. Round 2 of 33.', style: text.bodyLarge),
        Slider(
          value: s.textScale,
          min: AppSettings.minTextScale,
          max: AppSettings.maxTextScale,
          divisions: 8,
          label: '${(s.textScale * 100).round()}%',
          onChanged: (v) => ctrl.update((x) => x.copyWith(textScale: v)),
        ),
        const _Label('Feedback'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Vibration'),
          subtitle: const Text('A soft tap on every count, stronger at each round'),
          value: s.hapticsEnabled,
          onChanged: (v) => ctrl.update((x) => x.copyWith(hapticsEnabled: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Sound'),
          subtitle: const Text('A quiet bead click; a soft chime at each round'),
          value: s.soundEnabled,
          onChanged: (v) => ctrl.update((x) => x.copyWith(soundEnabled: v)),
        ),
        const SizedBox(height: Space.xl),
        OutlinedButton(
          onPressed: () async {
            final ok = await confirmAction(
              context,
              title: 'Reset appearance?',
              message: 'Theme, colors, bead and counter designs and text sizes return to their defaults.',
              confirmLabel: 'Reset',
            );
            if (ok) await ctrl.resetAppearance();
          },
          child: const Text('Reset to defaults'),
        ),
      ],
    );
  }
}
