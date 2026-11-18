import 'localized_text.dart';

enum WeatherCondition { sunny, partlyCloudy, cloudy, lightRain, heavyRain, thunderstorm, fog, windy }

extension WeatherConditionX on WeatherCondition {
  String get emoji => switch (this) {
    WeatherCondition.sunny => '☀️',
    WeatherCondition.partlyCloudy => '⛅',
    WeatherCondition.cloudy => '☁️',
    WeatherCondition.lightRain => '🌦️',
    WeatherCondition.heavyRain => '🌧️',
    WeatherCondition.thunderstorm => '⛈️',
    WeatherCondition.fog => '🌫️',
    WeatherCondition.windy => '💨',
  };

  bool get isRainy =>
      this == WeatherCondition.lightRain || this == WeatherCondition.heavyRain || this == WeatherCondition.thunderstorm;
}

class CurrentWeather {
  const CurrentWeather({
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.humidity,
    required this.windKmh,
    required this.rainChance,
    required this.minTemp,
    required this.maxTemp,
  });

  final int temperature;
  final int feelsLike;
  final WeatherCondition condition;
  final int humidity; // %
  final int windKmh;
  final int rainChance; // %
  final int minTemp;
  final int maxTemp;

  factory CurrentWeather.fromJson(Map<String, dynamic> j) => CurrentWeather(
    temperature: (j['temperature'] as num).round(),
    feelsLike: (j['feelsLike'] as num? ?? j['temperature'] as num).round(),
    condition: WeatherCondition.values.asNameMap()[j['condition']] ?? WeatherCondition.sunny,
    humidity: (j['humidity'] as num? ?? 0).round(),
    windKmh: (j['windKmh'] as num? ?? 0).round(),
    rainChance: (j['rainChance'] as num? ?? 0).round(),
    minTemp: (j['minTemp'] as num? ?? 0).round(),
    maxTemp: (j['maxTemp'] as num? ?? 0).round(),
  );
}

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.condition,
    required this.minTemp,
    required this.maxTemp,
    required this.rainChance,
    required this.windKmh,
    required this.humidity,
  });

  final DateTime date;
  final WeatherCondition condition;
  final int minTemp;
  final int maxTemp;
  final int rainChance;
  final int windKmh;
  final int humidity;

  factory DailyForecast.fromJson(Map<String, dynamic> j) => DailyForecast(
    date: DateTime.parse(j['date'] as String),
    condition: WeatherCondition.values.asNameMap()[j['condition']] ?? WeatherCondition.sunny,
    minTemp: (j['minTemp'] as num).round(),
    maxTemp: (j['maxTemp'] as num).round(),
    rainChance: (j['rainChance'] as num? ?? 0).round(),
    windKmh: (j['windKmh'] as num? ?? 0).round(),
    humidity: (j['humidity'] as num? ?? 0).round(),
  );
}

class WeatherReport {
  const WeatherReport({
    required this.location,
    required this.current,
    required this.daily,
    required this.updatedAt,
    this.isSample = true,
  });

  final String location;
  final CurrentWeather current;
  final List<DailyForecast> daily;
  final DateTime updatedAt;

  /// True while weather comes from mock data (Phase 1).
  final bool isSample;

  /// First upcoming day (within [withinDays]) with rain chance >= [threshold].
  DailyForecast? nextRain({int withinDays = 7, int threshold = 60}) {
    for (final d in daily.take(withinDays)) {
      if (d.rainChance >= threshold) return d;
    }
    return null;
  }
}

enum AlertSeverity { info, warning, severe }

enum AlertType { rain, heavyRain, heat, cold, wind, fog }

extension AlertTypeX on AlertType {
  String get emoji => switch (this) {
    AlertType.rain => '🌦️',
    AlertType.heavyRain => '🌧️',
    AlertType.heat => '🌡️',
    AlertType.cold => '🥶',
    AlertType.wind => '💨',
    AlertType.fog => '🌫️',
  };
}

class WeatherAlert {
  const WeatherAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.action,
    required this.date,
    this.affectedCropTypeIds = const [],
    this.isRead = false,
  });

  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final LocalizedText title;
  final LocalizedText message;
  final LocalizedText action;
  final DateTime date;
  final List<String> affectedCropTypeIds;
  final bool isRead;

  bool isActive(DateTime now) => !date.isBefore(DateTime(now.year, now.month, now.day));

  WeatherAlert copyWith({bool? isRead}) => WeatherAlert(
    id: id,
    type: type,
    severity: severity,
    title: title,
    message: message,
    action: action,
    date: date,
    affectedCropTypeIds: affectedCropTypeIds,
    isRead: isRead ?? this.isRead,
  );
}
