import 'dart:convert';

import 'package:fasal_core/catalog.dart';
import 'package:fasal_core/models.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../http/api.dart';

final _log = Logger('weather');

/// Source of forecasts for a coordinate.
abstract interface class WeatherProvider {
  Future<WeatherReport> forecast({required String location, required double lat, required double lon});
}

/// Live forecasts from Open-Meteo (free, no API key, good Pakistan coverage).
/// https://open-meteo.com — data CC BY 4.0.
class OpenMeteoProvider implements WeatherProvider {
  OpenMeteoProvider({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<WeatherReport> forecast({required String location, required double lat, required double lon}) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lon',
      'current': 'temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,relative_humidity_2m_mean',
      'timezone': 'Asia/Karachi',
      'forecast_days': '7',
      'wind_speed_unit': 'kmh',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw ApiError(503, 'weather_unavailable', 'Weather service returned ${res.statusCode}');
    }
    return parseOpenMeteo(location, jsonDecode(res.body) as Map<String, dynamic>);
  }
}

/// Maps WMO weather codes to FASAL conditions.
WeatherCondition conditionFromWmo(int code) => switch (code) {
  0 => WeatherCondition.sunny,
  1 || 2 => WeatherCondition.partlyCloudy,
  3 => WeatherCondition.cloudy,
  45 || 48 => WeatherCondition.fog,
  51 || 53 || 55 || 56 || 57 || 61 || 63 || 80 || 81 => WeatherCondition.lightRain,
  65 || 66 || 67 || 82 => WeatherCondition.heavyRain,
  95 || 96 || 99 => WeatherCondition.thunderstorm,
  _ => WeatherCondition.cloudy, // snow/other: rare on Pakistani farmland
};

WeatherReport parseOpenMeteo(String location, Map<String, dynamic> j) {
  final cur = j['current'] as Map<String, dynamic>;
  final daily = j['daily'] as Map<String, dynamic>;
  List<num?> col(String k) => [for (final v in (daily[k] as List? ?? const [])) v as num?];
  final dates = [for (final v in daily['time'] as List) DateTime.parse(v as String)];
  final codes = col('weather_code');
  final maxT = col('temperature_2m_max');
  final minT = col('temperature_2m_min');
  final rain = col('precipitation_probability_max');
  final wind = col('wind_speed_10m_max');
  final hum = col('relative_humidity_2m_mean');
  int at(List<num?> l, int i, [num fallback = 0]) => (i < l.length ? l[i] ?? fallback : fallback).round();

  final curHumidity = (cur['relative_humidity_2m'] as num? ?? 0).round();
  final days = [
    for (var i = 0; i < dates.length; i++)
      DailyForecast(
        date: dates[i],
        condition: conditionFromWmo(at(codes, i)),
        minTemp: at(minT, i),
        maxTemp: at(maxT, i),
        rainChance: at(rain, i),
        windKmh: at(wind, i),
        humidity: at(hum, i, curHumidity),
      ),
  ];
  return WeatherReport(
    location: location,
    current: CurrentWeather(
      temperature: (cur['temperature_2m'] as num).round(),
      feelsLike: (cur['apparent_temperature'] as num? ?? cur['temperature_2m'] as num).round(),
      condition: conditionFromWmo((cur['weather_code'] as num? ?? 0).toInt()),
      humidity: curHumidity,
      windKmh: (cur['wind_speed_10m'] as num? ?? 0).round(),
      rainChance: days.isEmpty ? 0 : days.first.rainChance,
      minTemp: days.isEmpty ? 0 : days.first.minTemp,
      maxTemp: days.isEmpty ? 0 : days.first.maxTemp,
    ),
    daily: days,
    updatedAt: DateTime.now(),
    isSample: false,
  );
}

/// Deterministic sample forecast (tests, offline development).
class SampleWeatherProvider implements WeatherProvider {
  @override
  Future<WeatherReport> forecast({required String location, required double lat, required double lon}) async {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    const p = [
      (WeatherCondition.sunny, 11, 26, 0, 9),
      (WeatherCondition.partlyCloudy, 12, 24, 10, 11),
      (WeatherCondition.cloudy, 13, 22, 40, 14),
      (WeatherCondition.heavyRain, 12, 19, 85, 24),
      (WeatherCondition.lightRain, 10, 20, 50, 16),
      (WeatherCondition.partlyCloudy, 9, 23, 10, 10),
      (WeatherCondition.sunny, 10, 25, 0, 8),
    ];
    final days = [
      for (var i = 0; i < p.length; i++)
        DailyForecast(
          date: today.add(Duration(days: i)),
          condition: p[i].$1,
          minTemp: p[i].$2,
          maxTemp: p[i].$3,
          rainChance: p[i].$4,
          windKmh: p[i].$5,
          humidity: 55,
        ),
    ];
    return WeatherReport(
      location: location,
      current: const CurrentWeather(
        temperature: 24,
        feelsLike: 24,
        condition: WeatherCondition.sunny,
        humidity: 48,
        windKmh: 9,
        rainChance: 0,
        minTemp: 11,
        maxTemp: 26,
      ),
      daily: days,
      updatedAt: t,
      isSample: true,
    );
  }
}

/// District → forecast with a short in-memory cache (protects the free API).
class WeatherService {
  WeatherService(this.provider, {this.ttl = const Duration(minutes: 30)});

  final WeatherProvider provider;
  final Duration ttl;
  final Map<String, (DateTime, WeatherReport)> _cache = {};

  Future<WeatherReport> forDistrict(String district) async {
    final d = findDistrict(district);
    if (d == null) throw ApiError(404, 'unknown_district', 'Unknown district "$district"');
    final key = d.name.en;
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.$1) < ttl) return hit.$2;
    try {
      final report = await provider.forecast(location: d.name.en, lat: d.lat, lon: d.lon);
      _cache[key] = (DateTime.now(), report);
      return report;
    } on ApiError {
      rethrow;
    } catch (e) {
      _log.warning('Weather fetch failed for $key: $e');
      if (hit != null) return hit.$2; // stale is better than nothing
      throw const ApiError(503, 'weather_unavailable', 'Weather is temporarily unavailable');
    }
  }
}
