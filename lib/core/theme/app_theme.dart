import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Builds the app [ThemeData]. Component styling lives in the reusable
/// widgets under `lib/core/widgets`, so the theme stays small and stable.
abstract final class AppTheme {
  static ThemeData light({required bool urdu}) {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.secondaryContainer,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: urdu ? AppTypography.urduFamily : AppTypography.latinFamily,
      fontFamilyFallback: urdu ? const [AppTypography.latinFamily] : const [AppTypography.urduFamily],
      textTheme: AppTypography.textTheme(urdu: urdu),
      splashFactory: InkRipple.splashFactory,
      dividerColor: AppColors.divider,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.dark,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    );
  }
}
