import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light(Color accent) => _build(SakinaColors.light(accent), Brightness.light);

  static ThemeData dark(Color accent) => _build(SakinaColors.dark(accent), Brightness.dark);

  static ThemeData _build(SakinaColors c, Brightness brightness) {
    final text = AppTypography.textTheme(c.textPrimary, c.textSecondary);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.textPrimary,
      secondary: c.gold,
      onSecondary: AppPalette.ink,
      tertiary: c.gold,
      onTertiary: AppPalette.ink,
      error: c.danger,
      onError: Colors.white,
      surface: c.background,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceMuted,
      surfaceContainerHighest: c.surfaceMuted,
      outline: c.hairline,
      outlineVariant: c.hairline,
      shadow: Colors.black,
      inverseSurface: c.textPrimary,
      onInverseSurface: c.background,
    );

    final overlay = brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      fontFamily: AppFonts.sans,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      extensions: [c],
      dividerTheme: DividerThemeData(color: c.hairline, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: overlay.copyWith(statusBarColor: Colors.transparent),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.accentSoft,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium!.copyWith(
            color: states.contains(WidgetState.selected) ? c.textPrimary : c.textTertiary,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? c.accent : c.textTertiary,
            size: 24,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: c.hairline),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: c.textPrimary)),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.gutter),
        iconColor: c.textSecondary,
        titleTextStyle: text.titleSmall!.copyWith(fontWeight: FontWeight.w500, fontSize: 15.5),
        subtitleTextStyle: text.bodySmall,
        minVerticalPadding: 12,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onAccent : c.textTertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.transparent : c.hairline,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accent,
        inactiveTrackColor: c.hairline,
        thumbColor: c.accent,
        overlayColor: c.accent.withValues(alpha: 0.12),
        trackHeight: 3,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: c.textSecondary,
          selectedBackgroundColor: c.accentSoft,
          selectedForegroundColor: c.textPrimary,
          side: BorderSide(color: c.hairline),
          textStyle: text.labelMedium,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: c.accentSoft,
        side: BorderSide(color: c.hairline),
        labelStyle: text.labelMedium!.copyWith(color: c.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.pill)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.background,
        showDragHandle: true,
        dragHandleColor: c.hairline,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: text.bodyMedium!.copyWith(color: c.background),
        actionTextColor: c.isDark ? AppPalette.emerald : AppPalette.gold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 14),
        labelStyle: text.bodyMedium,
        hintStyle: text.bodyMedium!.copyWith(color: c.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: c.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: c.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: c.accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: c.danger),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        elevation: 1,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        extendedTextStyle: text.labelLarge,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent, linearTrackColor: c.hairline),
      tabBarTheme: TabBarThemeData(
        labelColor: c.textPrimary,
        unselectedLabelColor: c.textTertiary,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        indicatorColor: c.accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: c.hairline,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: c.background,
        dialBackgroundColor: c.surfaceMuted,
        hourMinuteColor: c.surfaceMuted,
      ),
    );
  }
}
