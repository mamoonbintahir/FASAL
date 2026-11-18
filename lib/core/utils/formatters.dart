/// Number formatting helpers (Western digits, as commonly used in Pakistan apps).
abstract final class Fmt {
  /// 23500 -> "23,500"
  static String thousands(int value) {
    final negative = value < 0;
    final digits = value.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return negative ? '-$buf' : buf.toString();
  }

  /// 5.0 -> "5", 2.5 -> "2.5", 1.25 -> "1.25"
  static String area(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    final s = value.toStringAsFixed(2);
    return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
  }
}
