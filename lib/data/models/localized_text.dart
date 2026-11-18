/// Content that ships in both English and Urdu (crop names, stage names,
/// guidance text). In Phase 2 the backend returns this same shape.
class LocalizedText {
  const LocalizedText(this.en, this.ur);

  final String en;
  final String ur;

  String of(String languageCode) => languageCode == 'ur' ? ur : en;

  /// Joins several texts into sentences (used for voice: title + body).
  static LocalizedText joinAll(List<LocalizedText> parts) =>
      LocalizedText(_join(parts.map((p) => p.en), '.'), _join(parts.map((p) => p.ur), '۔'));

  static String _join(Iterable<String> parts, String stop) {
    final buf = StringBuffer();
    for (final raw in parts) {
      final p = raw.trim();
      if (p.isEmpty) continue;
      if (buf.isNotEmpty) buf.write(' ');
      buf.write(p);
      if (!RegExp(r'[.!?۔؟]$').hasMatch(p)) buf.write(stop);
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {'en': en, 'ur': ur};

  factory LocalizedText.fromJson(Map<String, dynamic> json) =>
      LocalizedText(json['en'] as String? ?? '', json['ur'] as String? ?? '');

  @override
  bool operator ==(Object other) => other is LocalizedText && other.en == en && other.ur == ur;

  @override
  int get hashCode => Object.hash(en, ur);
}
