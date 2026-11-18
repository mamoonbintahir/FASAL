import 'package:flutter/widgets.dart';

/// Spacing, radius and sizing tokens. Use these instead of magic numbers.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal page padding used on every screen.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets card = EdgeInsets.all(20);

  /// Minimum touch target for farmers (larger than Material's 48 where possible).
  static const double minTouch = 52;
  static const double buttonHeight = 58;

  /// Max content width on tablets / large phones in landscape.
  static const double maxContentWidth = 600;
}

abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 28;
  static const double pill = 999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
}
