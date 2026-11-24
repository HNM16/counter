import 'package:material_ui/material_ui.dart';

import '../../settings/domain/app_settings.dart';
import '../widgets/beads/tasbih_backdrop.dart';
import '../widgets/digital/digital_palette.dart';

/// Colors for everything drawn around the counter (header, footer and the
/// navigation bar while the Tasbih tab is open), derived from the active
/// counter mode so the whole screen feels like one surface.
@immutable
class TasbihChrome {
  const TasbihChrome({
    required this.background,
    required this.foreground,
    required this.secondary,
    required this.accent,
    required this.isDark,
  });

  factory TasbihChrome.of(AppSettings settings) {
    if (settings.counterMode == CounterMode.beads) {
      final b = BackdropStyle.of(settings.tasbihBackground);
      return TasbihChrome(
        background: b.base,
        foreground: b.foreground,
        secondary: b.secondary,
        accent: b.progress,
        isDark: b.isDark,
      );
    }
    final p = DigitalPalette.of(settings);
    return TasbihChrome(
      background: p.background,
      foreground: p.text,
      secondary: p.subtext,
      accent: p.accent,
      isDark: p.isDark,
    );
  }

  final Color background;
  final Color foreground;
  final Color secondary;
  final Color accent;
  final bool isDark;
}
