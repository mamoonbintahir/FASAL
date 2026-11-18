import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Typography scale. English uses Manrope; Urdu uses Noto Nastaliq Urdu
/// (with Manrope as fallback for digits / Latin words such as "acres").
abstract final class AppTypography {
  static const String latinFamily = 'Manrope';
  static const String urduFamily = 'NotoNastaliqUrdu';

  static bool _isBold(FontWeight w) =>
      w == FontWeight.w600 || w == FontWeight.w700 || w == FontWeight.w800 || w == FontWeight.w900;

  static TextTheme textTheme({required bool urdu}) {
    // Nastaliq glyphs are visually larger and taller — scale down slightly
    // and give extra line height so stacked lines don't collide.
    final double s = urdu ? 0.92 : 1.0;
    final double? h = urdu ? 1.9 : null;

    TextStyle style(double size, FontWeight weight, {Color color = AppColors.textPrimary, double? height}) {
      return TextStyle(
        fontSize: size * s,
        // Nastaliq ships Regular + Bold only.
        fontWeight: urdu && _isBold(weight) ? FontWeight.w700 : weight,
        color: color,
        height: h ?? height,
        letterSpacing: 0,
      );
    }

    return TextTheme(
      // Big numbers (temperature, totals)
      displayLarge: style(56, FontWeight.w800, height: 1.05),
      displayMedium: style(40, FontWeight.w800, height: 1.1),
      displaySmall: style(32, FontWeight.w800, height: 1.15),
      // Screen titles
      headlineLarge: style(30, FontWeight.w800, height: 1.2),
      headlineMedium: style(26, FontWeight.w800, height: 1.2),
      headlineSmall: style(22, FontWeight.w800, height: 1.25),
      // Card titles
      titleLarge: style(20, FontWeight.w700, height: 1.3),
      titleMedium: style(17, FontWeight.w700, height: 1.3),
      titleSmall: style(15, FontWeight.w700, height: 1.3),
      // Body
      bodyLarge: style(17, FontWeight.w500, height: 1.45),
      bodyMedium: style(15, FontWeight.w500, color: AppColors.textSecondary, height: 1.45),
      bodySmall: style(13, FontWeight.w500, color: AppColors.textSecondary, height: 1.4),
      // Labels / buttons
      labelLarge: style(17, FontWeight.w700, height: 1.2),
      labelMedium: style(14, FontWeight.w600, color: AppColors.textSecondary, height: 1.2),
      labelSmall: style(12, FontWeight.w600, color: AppColors.textSecondary, height: 1.2),
    );
  }
}
