import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/arabic_text.dart';
import '../../../shared/widgets/common.dart';
import '../../dhikr/presentation/dhikr_providers.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/counter_session.dart';
import '../widgets/beads/bead_tasbih_view.dart';
import '../widgets/beads/tasbih_backdrop.dart';
import '../widgets/digital/digital_counter_view.dart';
import '../widgets/digital/digital_palette.dart';
import '../widgets/mode_toggle.dart';
import 'celebration_overlay.dart';
import 'tasbih_chrome.dart';
import 'tasbih_controller.dart';
import 'tasbih_sheets.dart';

class TasbihScreen extends ConsumerWidget {
  const TasbihScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final async = ref.watch(tasbihControllerProvider);

    final beads = settings.counterMode == CounterMode.beads;
    final backdrop = BackdropStyle.of(settings.tasbihBackground);
    final palette = DigitalPalette.of(settings);
    final chrome = TasbihChrome.of(settings);

    final overlay = chrome.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: beads ? backdrop.base : palette.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: Motion.medium,
              child: beads
                  ? CustomPaint(
                      key: ValueKey(settings.tasbihBackground),
                      painter: TasbihBackdropPainter(settings.tasbihBackground),
                    )
                  : ColoredBox(key: ValueKey(palette.background), color: palette.background),
            ),
            SafeArea(
              bottom: false,
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Space.xl),
                    child: Text('Something went wrong while loading your session.\n$e', textAlign: TextAlign.center),
                  ),
                ),
                data: (state) => _TasbihBody(
                  session: state.session,
                  settings: settings,
                  chrome: chrome,
                  palette: palette,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasbihBody extends ConsumerWidget {
  const _TasbihBody({required this.session, required this.settings, required this.chrome, required this.palette});

  final CounterSession session;
  final AppSettings settings;
  final TasbihChrome chrome;
  final DigitalPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(tasbihControllerProvider.notifier);
    final dhikr = ref.watch(dhikrByIdProvider(session.dhikrId));
    final arabic = dhikr?.arabic ?? session.dhikrArabic;
    final label = dhikr?.transliteration ?? session.dhikrLabel;
    final text = Theme.of(context).textTheme;
    final beads = settings.counterMode == CounterMode.beads;
    final compact = MediaQuery.sizeOf(context).height < 700;

    return Column(
      children: [
        _Header(chrome: chrome, session: session, settings: settings),
        GestureDetector(
          onTap: () => showDhikrPicker(context, ref),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: Column(
              children: [
                ArabicText(arabic, size: compact ? 26 : 32, color: chrome.foreground, maxLines: 2),
                if (settings.showTransliteration)
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: text.titleSmall!.copyWith(color: chrome.foreground, fontWeight: FontWeight.w500),
                  ),
                if (settings.showTranslation && dhikr != null && !compact)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      dhikr.translation,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall!.copyWith(color: chrome.secondary),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: Motion.medium,
                child: beads
                    ? BeadTasbihView(
                        key: const ValueKey('beads'),
                        appearance: BeadAppearance.fromSettings(settings),
                        totalCount: session.totalCount,
                        target: session.target,
                        paused: session.isPaused,
                        onCount: controller.increment,
                      )
                    : DigitalCounterView(
                        key: const ValueKey('digital'),
                        layout: settings.digitalLayout,
                        palette: palette,
                        totalCount: session.totalCount,
                        target: session.target,
                        paused: session.isPaused,
                        onCount: controller.increment,
                      ),
              ),
              CelebrationOverlay(foreground: chrome.foreground, accent: chrome.accent),
            ],
          ),
        ),
        _Footer(session: session, chrome: chrome),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.chrome, required this.session, required this.settings});

  final TasbihChrome chrome;
  final CounterSession session;
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xs, Space.xs, Space.xs, Space.xs),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Choose dhikr',
            onPressed: () => showDhikrPicker(context, ref),
            icon: Icon(Icons.menu_book_outlined, color: chrome.foreground),
          ),
          const Spacer(),
          ModeToggle(
            mode: settings.counterMode,
            foreground: chrome.foreground,
            secondary: chrome.secondary,
            onChanged: (m) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(counterMode: m)),
          ),
          const Spacer(),
          PopupMenuButton<_MenuAction>(
            tooltip: 'More',
            icon: Icon(Icons.more_horiz, color: chrome.foreground),
            onSelected: (action) => _onMenu(context, ref, action),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _MenuAction.target,
                child: _MenuRow(Icons.adjust, 'Repetitions per round (${session.target})'),
              ),
              const PopupMenuItem(value: _MenuAction.customize, child: _MenuRow(Icons.palette_outlined, 'Customize')),
              const PopupMenuItem(value: _MenuAction.library, child: _MenuRow(Icons.menu_book_outlined, 'Dhikr library')),
              PopupMenuItem(
                value: _MenuAction.reset,
                enabled: session.totalCount > 0,
                child: const _MenuRow(Icons.restart_alt, 'Reset counter'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, WidgetRef ref, _MenuAction action) async {
    final controller = ref.read(tasbihControllerProvider.notifier);
    switch (action) {
      case _MenuAction.target:
        final t = await showTargetPicker(context, current: session.target);
        if (t != null) controller.setTarget(t);
      case _MenuAction.customize:
        context.push(Routes.customize);
      case _MenuAction.library:
        context.push(Routes.library);
      case _MenuAction.reset:
        final choice = await showResetDialog(context, session);
        if (choice == null) return;
        await controller.reset(keepInHistory: choice == ResetChoice.save);
        if (context.mounted) {
          showToast(context, choice == ResetChoice.save ? 'Saved to history. Counter reset.' : 'Counter reset.');
        }
    }
  }
}

enum _MenuAction { target, customize, library, reset }

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: Space.sm),
      Flexible(child: Text(label)),
    ],
  );
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.session, required this.chrome});

  final CounterSession session;
  final TasbihChrome chrome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(tasbihControllerProvider.notifier);
    final text = Theme.of(context).textTheme;
    final caption = text.bodySmall!.copyWith(color: chrome.secondary);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.md, Space.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Round ${session.currentRound}', style: caption),
                _dot(caption),
                Text('${Formatters.count(session.totalCount)} total', style: caption),
                _dot(caption),
                _LiveClock(session: session, style: caption),
              ],
            ),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Expanded(
                  child: _FooterButton(
                    icon: Icons.undo_rounded,
                    label: 'Undo',
                    color: chrome.foreground,
                    onTap: session.totalCount > 0 ? controller.undo : null,
                  ),
                ),
                _PauseButton(session: session, chrome: chrome, onTap: controller.togglePause),
                Expanded(
                  child: _FooterButton(
                    icon: Icons.check_rounded,
                    label: 'Finish',
                    color: chrome.foreground,
                    onTap: session.totalCount > 0
                        ? () async {
                            final finished = await controller.finish();
                            if (finished != null && context.mounted) await showSessionSummary(context, finished);
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(TextStyle style) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('·', style: style));
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final c = enabled ? color : color.withValues(alpha: 0.3);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: c, size: 22),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.labelMedium!.copyWith(color: c)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.session, required this.chrome, required this.onTap});

  final CounterSession session;
  final TasbihChrome chrome;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final paused = session.isPaused;
    return Semantics(
      button: true,
      label: paused ? 'Resume' : 'Pause',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.medium,
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: paused ? chrome.accent : Colors.transparent,
            border: Border.all(color: paused ? chrome.accent : chrome.foreground.withValues(alpha: 0.25), width: 1.5),
          ),
          child: Icon(
            paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            color: paused ? (chrome.isDark ? Colors.black : Colors.white) : chrome.foreground,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// Session clock that ticks once per second while counting.
class _LiveClock extends StatefulWidget {
  const _LiveClock({required this.session, required this.style});

  final CounterSession session;
  final TextStyle style;

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_LiveClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final running = !widget.session.isPaused && widget.session.totalCount > 0;
    if (running && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!running) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.session.liveDuration(DateTime.now());
    return Text(Formatters.clock(d), style: widget.style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]));
  }
}
