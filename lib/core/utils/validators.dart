import '../l10n/app_strings.dart';

/// Form validators. They return a localised error message, or null if valid.
class Validators {
  Validators(this.s);

  final AppStrings s;

  static const double maxAreaAcres = 10000;

  String? requiredText(String? v) => (v == null || v.trim().isEmpty) ? s.errRequired : null;

  String? optionalName(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length > 40) return s.errTooLong;
    return null;
  }

  String? area(String? v) {
    if (v == null || v.trim().isEmpty) return s.errAreaRequired;
    final value = double.tryParse(v.trim());
    if (value == null) return s.errNumber;
    if (value <= 0) return s.errAreaPositive;
    if (value > maxAreaAcres) return s.errAreaTooLarge;
    return null;
  }

  String? optionalPositiveNumber(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final value = double.tryParse(v.trim());
    if (value == null) return s.errNumber;
    if (value <= 0) return s.errPositive;
    if (value > 100000) return s.errTooLarge;
    return null;
  }

  String? amount(String? v) {
    if (v == null || v.trim().isEmpty) return s.errAmountRequired;
    final value = int.tryParse(v.trim().replaceAll(',', ''));
    if (value == null) return s.errWholeNumber;
    if (value <= 0) return s.errPositive;
    if (value > 100000000) return s.errTooLarge;
    return null;
  }

  /// Sowing date may be up to 1 year in the past and 60 days in the future.
  String? sowingDate(DateTime? d, DateTime today) {
    if (d == null) return s.errSowingDateRequired;
    final diff = d.difference(today).inDays;
    if (diff > 60) return s.errSowingDateFuture;
    if (diff < -365) return s.errSowingDatePast;
    return null;
  }
}
