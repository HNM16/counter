import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/domain/app_settings.dart';

/// Colors for one digital counter design.
@immutable
class DigitalPalette {
  const DigitalPalette({
    required this.background,
    required this.text,
    required this.subtext,
    required this.accent,
    required this.track,
    required this.button,
    required this.buttonEdge,
    required this.body,
    required this.lcd,
    required this.lcdInk,
    required this.isDark,
  });

  final Color background;
  final Color text;
  final Color subtext;
  final Color accent;
  final Color track;
  final Color button;
  final Color buttonEdge;

  /// Shell color of the handheld "device" layout.
  final Color body;
  final Color lcd;
  final Color lcdInk;
  final bool isDark;

  factory DigitalPalette.of(AppSettings s) => DigitalPalette.forDesign(
    s.digitalDesign,
    customBackground: s.customDigitalBackground,
    customAccent: s.customDigitalAccent,
  );

  factory DigitalPalette.forDesign(DigitalDesign d, {Color? customBackground, Color? customAccent}) {
    switch (d) {
      case DigitalDesign.minimalWhite:
        return const DigitalPalette(
          background: AppPalette.ivory,
          text: AppPalette.ink,
          subtext: AppPalette.inkSoft,
          accent: AppPalette.emerald,
          track: Color(0xFFE6E0D5),
          button: Colors.white,
          buttonEdge: Color(0xFFE3DCCF),
          body: Color(0xFFF1ECE3),
          lcd: Color(0xFFC9D3C4),
          lcdInk: Color(0xFF1D2B22),
          isDark: false,
        );
      case DigitalDesign.premiumBlack:
        return const DigitalPalette(
          background: Color(0xFF0E0E0F),
          text: Color(0xFFF3EFE6),
          subtext: Color(0xFF8D8A84),
          accent: AppPalette.gold,
          track: Color(0xFF2A2A2C),
          button: Color(0xFF1B1B1D),
          buttonEdge: Color(0xFF34332F),
          body: Color(0xFF1A1A1C),
          lcd: Color(0xFF15130E),
          lcdInk: Color(0xFFE5C98E),
          isDark: true,
        );
      case DigitalDesign.emerald:
        return const DigitalPalette(
          background: AppPalette.forest,
          text: Color(0xFFF4EFE4),
          subtext: Color(0xFFA9C2B7),
          accent: AppPalette.gold,
          track: Color(0xFF1D5546),
          button: AppPalette.emerald,
          buttonEdge: Color(0xFF2A8565),
          body: Color(0xFF176B50),
          lcd: Color(0xFFBFCCB0),
          lcdInk: Color(0xFF13261C),
          isDark: true,
        );
      case DigitalDesign.warmBeige:
        return const DigitalPalette(
          background: AppPalette.beige,
          text: Color(0xFF3A2E22),
          subtext: Color(0xFF7A6B59),
          accent: Color(0xFF8A6A3B),
          track: Color(0xFFDCD1BF),
          button: Color(0xFFF7F2EA),
          buttonEdge: Color(0xFFD9CDB9),
          body: Color(0xFFD9CCB6),
          lcd: Color(0xFFCBC5A8),
          lcdInk: Color(0xFF2F2A1E),
          isDark: false,
        );
      case DigitalDesign.amoled:
        return const DigitalPalette(
          background: Colors.black,
          text: Color(0xFFEDEDED),
          subtext: Color(0xFF7D7D7D),
          accent: Color(0xFF3FBF8F),
          track: Color(0xFF1A1A1A),
          button: Color(0xFF0B0B0B),
          buttonEdge: Color(0xFF222222),
          body: Color(0xFF0D0D0D),
          lcd: Color(0xFF050505),
          lcdInk: Color(0xFF52D6A2),
          isDark: true,
        );
      case DigitalDesign.custom:
        final bg = customBackground ?? const Color(0xFF1B2A3A);
        final accent = customAccent ?? AppPalette.gold;
        final dark = bg.computeLuminance() < 0.4;
        final text = dark ? const Color(0xFFF5F1EA) : AppPalette.ink;
        return DigitalPalette(
          background: bg,
          text: text,
          subtext: text.withValues(alpha: 0.62),
          accent: accent,
          track: Color.alphaBlend(text.withValues(alpha: 0.12), bg),
          button: Color.alphaBlend((dark ? Colors.white : Colors.black).withValues(alpha: 0.06), bg),
          buttonEdge: Color.alphaBlend(text.withValues(alpha: 0.14), bg),
          body: Color.alphaBlend((dark ? Colors.white : Colors.black).withValues(alpha: 0.08), bg),
          lcd: dark ? Color.alphaBlend(Colors.black.withValues(alpha: 0.55), bg) : const Color(0xFFC9D3C4),
          lcdInk: dark ? accent : AppPalette.ink,
          isDark: dark,
        );
    }
  }
}
