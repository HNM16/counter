import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';

enum AppThemeMode {
  system('System'),
  light('Light'),
  dark('Dark');

  const AppThemeMode(this.label);
  final String label;

  ThemeMode get themeMode => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}

enum CounterMode {
  beads('Beads'),
  digital('Digital');

  const CounterMode(this.label);
  final String label;
}

/// How the bead tasbih is laid out on screen.
enum TasbihStyle {
  ring('Ring', 'A closed loop you turn bead by bead'),
  strand('Strand', 'A hanging strand you pull downwards');

  const TasbihStyle(this.label, this.description);
  final String label;
  final String description;
}

enum BeadMaterial {
  walnut('Walnut'),
  sandalwood('Sandalwood'),
  ebony('Ebony'),
  onyx('Black Onyx'),
  turquoise('Turquoise'),
  amethyst('Amethyst'),
  marble('White Marble'),
  jade('Green Jade'),
  pearl('Pearl'),
  amber('Amber');

  const BeadMaterial(this.label);
  final String label;
}

enum BeadSize {
  small('Small', 0.82),
  medium('Medium', 1.0),
  large('Large', 1.2);

  const BeadSize(this.label, this.scale);
  final String label;
  final double scale;
}

enum TasbihBackground {
  ivory('Ivory'),
  linen('Linen'),
  geometric('Geometric'),
  forest('Forest'),
  night('Night');

  const TasbihBackground(this.label);
  final String label;
}

enum DigitalDesign {
  minimalWhite('Minimal White'),
  premiumBlack('Premium Black'),
  emerald('Emerald'),
  warmBeige('Warm Beige'),
  amoled('Dark AMOLED'),
  custom('Custom');

  const DigitalDesign(this.label);
  final String label;
}

enum DigitalLayout {
  ring('Ring', 'Progress ring with the count at its heart'),
  classic('Classic', 'Large number above a generous button'),
  device('Device', 'A handheld counter with an LCD display');

  const DigitalLayout(this.label, this.description);
  final String label;
  final String description;
}

/// Every user preference, persisted locally.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.accent = AppPalette.emerald,
    this.counterMode = CounterMode.beads,
    this.tasbihStyle = TasbihStyle.ring,
    this.beadMaterial = BeadMaterial.walnut,
    this.beadTint,
    this.beadSize = BeadSize.medium,
    this.beadCount = 33,
    this.tasbihBackground = TasbihBackground.ivory,
    this.digitalDesign = DigitalDesign.minimalWhite,
    this.digitalLayout = DigitalLayout.ring,
    this.customDigitalBackground = const Color(0xFF1B2A3A),
    this.customDigitalAccent = const Color(0xFFE2C48A),
    this.defaultTarget = 33,
    this.hapticsEnabled = true,
    this.soundEnabled = false,
    this.arabicScale = 1.0,
    this.textScale = 1.0,
    this.showTransliteration = true,
    this.showTranslation = true,
    this.lastDhikrId,
  });

  final AppThemeMode themeMode;
  final Color accent;
  final CounterMode counterMode;
  final TasbihStyle tasbihStyle;
  final BeadMaterial beadMaterial;

  /// Optional color override for the chosen bead material. `null` keeps the
  /// material's natural color.
  final Color? beadTint;
  final BeadSize beadSize;

  /// Beads on the virtual tasbih: 33 or 99.
  final int beadCount;
  final TasbihBackground tasbihBackground;
  final DigitalDesign digitalDesign;
  final DigitalLayout digitalLayout;
  final Color customDigitalBackground;
  final Color customDigitalAccent;

  /// Round size used when a dhikr has no suggested target.
  final int defaultTarget;
  final bool hapticsEnabled;
  final bool soundEnabled;

  /// Multiplier for Arabic text (0.85 - 1.5).
  final double arabicScale;

  /// Multiplier for interface text (0.9 - 1.3).
  final double textScale;
  final bool showTransliteration;
  final bool showTranslation;
  final String? lastDhikrId;

  static const beadCountOptions = [33, 99];
  static const minArabicScale = 0.85;
  static const maxArabicScale = 1.5;
  static const minTextScale = 0.9;
  static const maxTextScale = 1.3;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    Color? accent,
    CounterMode? counterMode,
    TasbihStyle? tasbihStyle,
    BeadMaterial? beadMaterial,
    Color? beadTint,
    bool clearBeadTint = false,
    BeadSize? beadSize,
    int? beadCount,
    TasbihBackground? tasbihBackground,
    DigitalDesign? digitalDesign,
    DigitalLayout? digitalLayout,
    Color? customDigitalBackground,
    Color? customDigitalAccent,
    int? defaultTarget,
    bool? hapticsEnabled,
    bool? soundEnabled,
    double? arabicScale,
    double? textScale,
    bool? showTransliteration,
    bool? showTranslation,
    String? lastDhikrId,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      counterMode: counterMode ?? this.counterMode,
      tasbihStyle: tasbihStyle ?? this.tasbihStyle,
      beadMaterial: beadMaterial ?? this.beadMaterial,
      beadTint: clearBeadTint ? null : (beadTint ?? this.beadTint),
      beadSize: beadSize ?? this.beadSize,
      beadCount: beadCount ?? this.beadCount,
      tasbihBackground: tasbihBackground ?? this.tasbihBackground,
      digitalDesign: digitalDesign ?? this.digitalDesign,
      digitalLayout: digitalLayout ?? this.digitalLayout,
      customDigitalBackground: customDigitalBackground ?? this.customDigitalBackground,
      customDigitalAccent: customDigitalAccent ?? this.customDigitalAccent,
      defaultTarget: defaultTarget ?? this.defaultTarget,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      arabicScale: arabicScale ?? this.arabicScale,
      textScale: textScale ?? this.textScale,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      showTranslation: showTranslation ?? this.showTranslation,
      lastDhikrId: lastDhikrId ?? this.lastDhikrId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.accent == accent &&
      other.counterMode == counterMode &&
      other.tasbihStyle == tasbihStyle &&
      other.beadMaterial == beadMaterial &&
      other.beadTint == beadTint &&
      other.beadSize == beadSize &&
      other.beadCount == beadCount &&
      other.tasbihBackground == tasbihBackground &&
      other.digitalDesign == digitalDesign &&
      other.digitalLayout == digitalLayout &&
      other.customDigitalBackground == customDigitalBackground &&
      other.customDigitalAccent == customDigitalAccent &&
      other.defaultTarget == defaultTarget &&
      other.hapticsEnabled == hapticsEnabled &&
      other.soundEnabled == soundEnabled &&
      other.arabicScale == arabicScale &&
      other.textScale == textScale &&
      other.showTransliteration == showTransliteration &&
      other.showTranslation == showTranslation &&
      other.lastDhikrId == lastDhikrId;

  @override
  int get hashCode => Object.hashAll([
    themeMode,
    accent,
    counterMode,
    tasbihStyle,
    beadMaterial,
    beadTint,
    beadSize,
    beadCount,
    tasbihBackground,
    digitalDesign,
    digitalLayout,
    customDigitalBackground,
    customDigitalAccent,
    defaultTarget,
    hapticsEnabled,
    soundEnabled,
    arabicScale,
    textScale,
    showTransliteration,
    showTranslation,
    lastDhikrId,
  ]);
}
