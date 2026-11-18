import 'package:material_ui/material_ui.dart';

/// Central colour palette for FASAL, derived from the reference UI.
/// Never use raw hex colours inside widgets — add them here instead.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF237B3B); // deep field green
  static const Color primaryDark = Color(0xFF1A5E2D);
  static const Color primaryContainer = Color(0xFFE1F4DD); // selected chip / "now" row
  static const Color onPrimary = Colors.white;

  static const Color secondary = Color(0xFF9C6439); // soil brown (records)
  static const Color secondaryContainer = Color(0xFFFBEADB); // peach note background

  static const Color accent = Color(0xFFE8A23C); // harvest gold
  static const Color dark = Color(0xFF15261A); // "Ask Fasal" card

  // Neutrals
  static const Color background = Color(0xFFF3F6EE);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFE9EDE4); // segmented control track
  static const Color border = Color(0xFFDCE2D6);
  static const Color divider = Color(0xFFE6EAE1);

  static const Color textPrimary = Color(0xFF18211A);
  static const Color textSecondary = Color(0xFF636B60);
  static const Color textMuted = Color(0xFF8E958A);

  // Status
  static const Color success = Color(0xFF237B3B);
  static const Color successContainer = Color(0xFFE1F4DD);
  static const Color warning = Color(0xFFD9822B);
  static const Color warningContainer = Color(0xFFFDF0DC);
  static const Color warningBorder = Color(0xFFE9A04C);
  static const Color error = Color(0xFFC8423A);
  static const Color errorContainer = Color(0xFFFBE4E1);
  static const Color info = Color(0xFF1E87BE);
  static const Color infoContainer = Color(0xFFDDF1FB);

  // Weather
  static const Color weatherCard = Color(0xFF1E87BE);
  static const Color weatherCardDark = Color(0xFF16709F);
  static const Color sunny = Color(0xFFF5B400);
  static const Color rain = Color(0xFF2F8FD6);
  static const Color rainContainer = Color(0xFFDDF1FB);

  // Task icon backgrounds (soft tints)
  static const Color tintBlue = Color(0xFFDDF1FB);
  static const Color tintGreen = Color(0xFFE1F4DD);
  static const Color tintOrange = Color(0xFFFBE9D9);
  static const Color tintYellow = Color(0xFFFFF3CC);
  static const Color tintPurple = Color(0xFFEDE6F8);
  static const Color tintRed = Color(0xFFFBE4E1);
  static const Color tintGrey = Color(0xFFEDEFEA);
}
