import 'package:material_ui/material_ui.dart';

/// Brand palette. These are the only raw colors the UI layer should reach for;
/// everything else is derived through [SakinaColors].
abstract final class AppPalette {
  static const ivory = Color(0xFFFAF9F6);
  static const emerald = Color(0xFF176B50);
  static const forest = Color(0xFF103D32);
  static const gold = Color(0xFFC9AE76);
  static const beige = Color(0xFFEDE5D8);
  static const night = Color(0xFF101512);

  static const ink = Color(0xFF14241E);
  static const inkSoft = Color(0xFF55635C);
  static const inkFaint = Color(0xFF8C968F);
  static const hairlineLight = Color(0xFFE5DED2);

  static const nightSurface = Color(0xFF161D19);
  static const nightRaised = Color(0xFF1C2520);
  static const nightHairline = Color(0xFF27312C);
  static const moon = Color(0xFFEDE8DF);
  static const moonSoft = Color(0xFFA3ADA7);
  static const moonFaint = Color(0xFF6E7872);

  static const danger = Color(0xFFB3412F);
  static const dangerDark = Color(0xFFE07A66);

  /// Accent choices offered in the customization studio.
  static const accents = <Color>[
    emerald,
    forest,
    Color(0xFFA8894E), // deep champagne
    Color(0xFF1F6F78), // teal
    Color(0xFF2E3D5C), // midnight
    Color(0xFF8E4F3A), // terracotta
    Color(0xFF5B4A7A), // plum
  ];
}

/// Semantic color tokens exposed to widgets through the theme.
@immutable
class SakinaColors extends ThemeExtension<SakinaColors> {
  const SakinaColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.hairline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.gold,
    required this.danger,
    required this.isDark,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color hairline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color gold;
  final Color danger;
  final bool isDark;

  factory SakinaColors.light(Color accent) => SakinaColors(
    background: AppPalette.ivory,
    surface: Colors.white,
    surfaceMuted: const Color(0xFFF3EEE5),
    hairline: AppPalette.hairlineLight,
    textPrimary: AppPalette.ink,
    textSecondary: AppPalette.inkSoft,
    textTertiary: AppPalette.inkFaint,
    accent: accent,
    accentSoft: Color.alphaBlend(accent.withValues(alpha: 0.10), AppPalette.ivory),
    onAccent: ColorTools.onColor(accent),
    gold: const Color(0xFFA8894E),
    danger: AppPalette.danger,
    isDark: false,
  );

  factory SakinaColors.dark(Color accent) {
    final adjusted = ColorTools.ensureMinLightness(accent, 0.42);
    return SakinaColors(
      background: AppPalette.night,
      surface: AppPalette.nightSurface,
      surfaceMuted: AppPalette.nightRaised,
      hairline: AppPalette.nightHairline,
      textPrimary: AppPalette.moon,
      textSecondary: AppPalette.moonSoft,
      textTertiary: AppPalette.moonFaint,
      accent: adjusted,
      accentSoft: Color.alphaBlend(adjusted.withValues(alpha: 0.16), AppPalette.night),
      onAccent: ColorTools.onColor(adjusted),
      gold: AppPalette.gold,
      danger: AppPalette.dangerDark,
      isDark: true,
    );
  }

  @override
  SakinaColors copyWith({Color? accent}) => SakinaColors(
    background: background,
    surface: surface,
    surfaceMuted: surfaceMuted,
    hairline: hairline,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textTertiary: textTertiary,
    accent: accent ?? this.accent,
    accentSoft: accentSoft,
    onAccent: onAccent,
    gold: gold,
    danger: danger,
    isDark: isDark,
  );

  @override
  SakinaColors lerp(SakinaColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SakinaColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      hairline: l(hairline, other.hairline),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      onAccent: l(onAccent, other.onAccent),
      gold: l(gold, other.gold),
      danger: l(danger, other.danger),
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// Small color math helpers used by theming and procedural rendering.
abstract final class ColorTools {
  static Color lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static Color darken(Color c, double amount) => lighten(c, -amount);

  static Color ensureMinLightness(Color c, double min) {
    final hsl = HSLColor.fromColor(c);
    if (hsl.lightness >= min) return c;
    return hsl.withLightness(min).toColor();
  }

  /// Picks a readable foreground for [background].
  static Color onColor(Color background) =>
      background.computeLuminance() > 0.45 ? AppPalette.ink : const Color(0xFFFBF8F2);

  static String toHex(Color c) {
    final argb = c.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

extension SakinaThemeContext on BuildContext {
  SakinaColors get colors => Theme.of(this).extension<SakinaColors>()!;
}
