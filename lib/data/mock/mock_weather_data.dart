import 'package:fasal_core/models.dart';

/// Realistic SAMPLE weather for a Punjab winter week, generated relative to
/// today so the demo always looks current. Day +3 brings heavy rain.
abstract final class MockWeatherData {
  static WeatherReport report(String location, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    const pattern = [
      (WeatherCondition.sunny, 11, 26, 0, 9, 48),
      (WeatherCondition.partlyCloudy, 12, 24, 10, 11, 55),
      (WeatherCondition.cloudy, 13, 22, 40, 14, 62),
      (WeatherCondition.heavyRain, 12, 19, 85, 24, 88),
      (WeatherCondition.lightRain, 10, 20, 50, 16, 80),
      (WeatherCondition.partlyCloudy, 9, 23, 10, 10, 60),
      (WeatherCondition.sunny, 10, 25, 0, 8, 50),
    ];
    final daily = [
      for (var i = 0; i < pattern.length; i++)
        DailyForecast(
          date: today.add(Duration(days: i)),
          condition: pattern[i].$1,
          minTemp: pattern[i].$2,
          maxTemp: pattern[i].$3,
          rainChance: pattern[i].$4,
          windKmh: pattern[i].$5,
          humidity: pattern[i].$6,
        ),
    ];
    return WeatherReport(
      location: location,
      current: const CurrentWeather(
        temperature: 26,
        feelsLike: 25,
        condition: WeatherCondition.sunny,
        humidity: 48,
        windKmh: 9,
        rainChance: 0,
        minTemp: 11,
        maxTemp: 26,
      ),
      daily: daily,
      updatedAt: now ?? DateTime.now(),
      isSample: true,
    );
  }

  static List<WeatherAlert> alerts({DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    return [
      WeatherAlert(
        id: 'a_rain',
        type: AlertType.heavyRain,
        severity: AlertSeverity.warning,
        date: today.add(const Duration(days: 3)),
        affectedCropTypeIds: const ['wheat', 'potato'],
        title: const LocalizedText('Rain expected', 'بارش متوقع ہے'),
        message: const LocalizedText(
          'Heavy rain is likely in 3 days. Hold your planned irrigation and check field drainage.',
          '3 دن میں تیز بارش کا امکان ہے۔ طے شدہ آبپاشی روک دیں اور کھیت سے پانی کے نکاس کو چیک کریں۔',
        ),
        action: const LocalizedText(
          'Skip irrigation this week. Clear water channels so rain water does not stand in the field.',
          'اس ہفتے پانی نہ دیں۔ کھالے صاف کریں تاکہ بارش کا پانی کھیت میں کھڑا نہ رہے۔',
        ),
      ),
      WeatherAlert(
        id: 'a_wind',
        type: AlertType.wind,
        severity: AlertSeverity.info,
        date: today.add(const Duration(days: 3)),
        affectedCropTypeIds: const ['wheat', 'maize', 'sugarcane'],
        title: const LocalizedText('Strong wind with rain', 'بارش کے ساتھ تیز ہوا'),
        message: const LocalizedText(
          'Wind up to 24 km/h is expected with the rain.',
          'بارش کے ساتھ 24 کلومیٹر فی گھنٹہ تک ہوا متوقع ہے۔',
        ),
        action: const LocalizedText('Do not spray or irrigate on that day.', 'اس دن اسپرے یا آبپاشی نہ کریں۔'),
      ),
      WeatherAlert(
        id: 'a_cold',
        type: AlertType.cold,
        severity: AlertSeverity.info,
        date: today.add(const Duration(days: 5)),
        affectedCropTypeIds: const ['potato'],
        title: const LocalizedText('Cold night ahead', 'سرد رات متوقع'),
        message: const LocalizedText(
          'Night temperature may drop to 9°C. Fog is possible in the morning.',
          'رات کا درجہ حرارت 9°C تک گر سکتا ہے۔ صبح دھند کا امکان ہے۔',
        ),
        action: const LocalizedText(
          'Check potato leaves for blight after foggy mornings.',
          'دھند والی صبح کے بعد آلو کے پتوں پر جھلساؤ دیکھیں۔',
        ),
      ),
      WeatherAlert(
        id: 'a_heat_old',
        type: AlertType.heat,
        severity: AlertSeverity.warning,
        date: today.subtract(const Duration(days: 12)),
        isRead: true,
        title: const LocalizedText('Warm afternoons', 'دوپہر میں گرمی'),
        message: const LocalizedText('Afternoon temperature reached 31°C.', 'دوپہر کا درجہ حرارت 31°C تک پہنچ گیا۔'),
        action: const LocalizedText('Irrigate in the morning or evening.', 'صبح یا شام کو پانی دیں۔'),
      ),
      WeatherAlert(
        id: 'a_fog_old',
        type: AlertType.fog,
        severity: AlertSeverity.info,
        date: today.subtract(const Duration(days: 20)),
        isRead: true,
        title: const LocalizedText('Morning fog', 'صبح کی دھند'),
        message: const LocalizedText('Dense fog was reported in the morning.', 'صبح گھنی دھند رہی۔'),
        action: const LocalizedText('Delay spraying until fog clears.', 'دھند ختم ہونے تک اسپرے مؤخر کریں۔'),
      ),
    ];
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
