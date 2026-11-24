import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/settings/presentation/settings_controller.dart';

/// Arabic text rendered right-to-left in the bundled Naskh face, scaled by
/// the user's Arabic text size preference.
class ArabicText extends ConsumerWidget {
  const ArabicText(
    this.text, {
    super.key,
    this.size = 28,
    this.color,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.weight = FontWeight.w400,
  });

  final String text;
  final double size;
  final Color? color;
  final TextAlign textAlign;
  final int? maxLines;
  final FontWeight weight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(settingsProvider.select((s) => s.arabicScale));
    // Custom dhikr may have no Arabic text.
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      textDirection: TextDirection.rtl,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      locale: const Locale('ar'),
      // Arabic text has its own scale setting; avoid double scaling.
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontFamily: AppFonts.arabic,
        fontSize: size * scale * MediaQuery.textScalerOf(context).scale(1),
        fontWeight: weight,
        // Generous line height keeps harakat (diacritics) clear of each other.
        height: 1.75,
        color: color ?? context.colors.textPrimary,
      ),
    );
  }
}
