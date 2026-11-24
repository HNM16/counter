import 'package:material_ui/material_ui.dart';

/// Font families bundled with the app (see pubspec.yaml). Everything is
/// shipped offline; no runtime font downloads.
abstract final class AppFonts {
  /// Interface text.
  static const sans = 'Manrope';

  /// Editorial headings and large numerals.
  static const serif = 'Cormorant';

  /// Arabic script (Naskh), rendered right-to-left.
  static const arabic = 'Amiri';

  static const tabularFigures = [FontFeature.tabularFigures(), FontFeature.liningFigures()];
}

abstract final class AppTypography {
  static TextTheme textTheme(Color primary, Color secondary) {
    TextStyle sans(double size, FontWeight weight, {double height = 1.4, double spacing = 0, Color? color}) =>
        TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: spacing,
          color: color ?? primary,
        );
    TextStyle serif(double size, FontWeight weight, {double height = 1.15, double spacing = 0}) => TextStyle(
      fontFamily: AppFonts.serif,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
      color: primary,
      // Cormorant defaults to old-style figures; statistics read better lining.
      fontFeatures: const [FontFeature.liningFigures()],
    );

    return TextTheme(
      displayLarge: serif(64, FontWeight.w300, height: 1.0, spacing: -1),
      displayMedium: serif(48, FontWeight.w300, height: 1.0, spacing: -0.5),
      displaySmall: serif(38, FontWeight.w400, height: 1.05),
      headlineLarge: serif(34, FontWeight.w500, spacing: -0.2),
      headlineMedium: serif(28, FontWeight.w500),
      headlineSmall: serif(23, FontWeight.w600),
      titleLarge: sans(19, FontWeight.w600, height: 1.3, spacing: -0.2),
      titleMedium: sans(16, FontWeight.w600, height: 1.35, spacing: -0.1),
      titleSmall: sans(14, FontWeight.w600, height: 1.35),
      bodyLarge: sans(16, FontWeight.w400, height: 1.5),
      bodyMedium: sans(14.5, FontWeight.w400, height: 1.5, color: secondary),
      bodySmall: sans(12.5, FontWeight.w400, height: 1.45, color: secondary),
      labelLarge: sans(15, FontWeight.w600, height: 1.2, spacing: 0.1),
      labelMedium: sans(12.5, FontWeight.w600, height: 1.2, spacing: 0.2, color: secondary),
      labelSmall: sans(11, FontWeight.w700, height: 1.2, spacing: 1.1, color: secondary),
    );
  }
}
