/// Date helpers. Display formatting (month/weekday names) lives in
/// [AppStrings] so it is localised; these helpers are language-neutral.
abstract final class AppDates {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime today() => dateOnly(DateTime.now());

  static bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Whole days from [from] to [to] (date parts only). Positive if [to] is later.
  static int daysBetween(DateTime from, DateTime to) => dateOnly(to).difference(dateOnly(from)).inDays;
}
