import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_strings.dart';

/// Supported app locales. Urdu is right-to-left; Flutter flips layouts
/// automatically from the locale via `GlobalWidgetsLocalizations`.
const List<Locale> kSupportedLocales = [Locale('en'), Locale('ur')];

class AppLocalizationsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en' || locale.languageCode == 'ur';

  @override
  Future<AppStrings> load(Locale locale) => SynchronousFuture(AppStrings(isUrdu: locale.languageCode == 'ur'));

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension AppStringsContext on BuildContext {
  /// Localised strings: `context.s.todaysTasks`.
  AppStrings get s => Localizations.of<AppStrings>(this, AppStrings) ?? const AppStrings(isUrdu: false);

  /// 'en' or 'ur' — used to pick text out of [LocalizedText] content.
  String get lang => s.languageCode;
}
