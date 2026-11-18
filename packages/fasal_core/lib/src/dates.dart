import 'models/localized_text.dart';

/// Language-neutral date helpers shared by the app and the server.
abstract final class AppDates {
  static const _daysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _daysUr = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];

  /// Weekday name in English and Urdu (1 = Monday … 7 = Sunday).
  static LocalizedText weekdayName(int weekday) => LocalizedText(_daysEn[weekday - 1], _daysUr[weekday - 1]);

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime today() => dateOnly(DateTime.now());

  static bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Whole days from [from] to [to] (date parts only). Positive if [to] is later.
  static int daysBetween(DateTime from, DateTime to) => dateOnly(to).difference(dateOnly(from)).inDays;
}
