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

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'feelsLike': feelsLike,
    'condition': condition.name,
    'humidity': humidity,
    'windKmh': windKmh,
    'rainChance': rainChance,
    'minTemp': minTemp,
    'maxTemp': maxTemp,
  };

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

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'condition': condition.name,
    'minTemp': minTemp,
    'maxTemp': maxTemp,
    'rainChance': rainChance,
    'windKmh': windKmh,
    'humidity': humidity,
  };

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

  Map<String, dynamic> toJson() => {
    'location': location,
    'current': current.toJson(),
    'daily': [for (final d in daily) d.toJson()],
    'updatedAt': updatedAt.toIso8601String(),
    'isSample': isSample,
  };

  factory WeatherReport.fromJson(Map<String, dynamic> j) => WeatherReport(
    location: j['location'] as String? ?? '',
    current: CurrentWeather.fromJson(j['current'] as Map<String, dynamic>),
    daily: [
      for (final d in (j['daily'] as List? ?? const []).whereType<Map<String, dynamic>>()) DailyForecast.fromJson(d),
    ],
    updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now(),
    isSample: j['isSample'] as bool? ?? false,
  );

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'severity': severity.name,
    'title': title.toJson(),
    'message': message.toJson(),
    'action': action.toJson(),
    'date': date.toIso8601String(),
    'affectedCropTypeIds': affectedCropTypeIds,
    'isRead': isRead,
  };

  factory WeatherAlert.fromJson(Map<String, dynamic> j) => WeatherAlert(
    id: j['id'] as String,
    type: AlertType.values.asNameMap()[j['type']] ?? AlertType.rain,
    severity: AlertSeverity.values.asNameMap()[j['severity']] ?? AlertSeverity.info,
    title: LocalizedText.fromJson(j['title'] as Map<String, dynamic>),
    message: LocalizedText.fromJson(j['message'] as Map<String, dynamic>),
    action: LocalizedText.fromJson(j['action'] as Map<String, dynamic>),
    date: DateTime.parse(j['date'] as String),
    affectedCropTypeIds: [for (final c in (j['affectedCropTypeIds'] as List? ?? const [])) c.toString()],
    isRead: j['isRead'] as bool? ?? false,
  );

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
