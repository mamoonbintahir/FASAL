import '../dates.dart';
import '../models/localized_text.dart';
import '../models/weather.dart';

/// Turns a forecast into farmer-friendly weather alerts.
///
/// Thresholds are simple, indicative values for Pakistani field crops and
/// should be reviewed by agronomists before production use.
class AlertRules {
  const AlertRules({
    this.rainChance = 60,
    this.heavyRainChance = 80,
    this.heatMax = 38,
    this.coldMin = 4,
    this.windKmh = 30,
  });

  final int rainChance;
  final int heavyRainChance;
  final int heatMax;
  final int coldMin;
  final int windKmh;

  /// Alerts for the coming days. Ids are deterministic (type + date) so read
  /// state survives re-generation.
  List<WeatherAlert> fromForecast(WeatherReport report, {List<String> userCropTypes = const []}) {
    final out = <WeatherAlert>[];
    for (final d in report.daily) {
      final day = AppDates.weekdayName(d.date.weekday);
      final key = AppDates.dateOnly(d.date).toIso8601String().substring(0, 10);
      if (d.rainChance >= rainChance) {
        final heavy = d.rainChance >= heavyRainChance || d.condition == WeatherCondition.heavyRain;
        out.add(
          WeatherAlert(
            id: '${heavy ? 'heavyRain' : 'rain'}_$key',
            type: heavy ? AlertType.heavyRain : AlertType.rain,
            severity: heavy ? AlertSeverity.warning : AlertSeverity.info,
            date: d.date,
            affectedCropTypeIds: userCropTypes,
            title: LocalizedText(
              heavy ? 'Heavy rain expected' : 'Rain expected',
              heavy ? 'تیز بارش متوقع ہے' : 'بارش متوقع ہے',
            ),
            message: LocalizedText(
              'Rain is likely on ${day.en} (${d.rainChance}%). Hold planned irrigation and check field drainage.',
              '${day.ur} کو بارش کا امکان ہے (${d.rainChance}%)۔ طے شدہ آبپاشی روکیں اور نکاس چیک کریں۔',
            ),
            action: const LocalizedText(
              'Skip irrigation before the rain. Avoid spraying or fertilizer just before it. Clear water channels.',
              'بارش سے پہلے پانی نہ دیں۔ اس سے ذرا پہلے اسپرے یا کھاد نہ ڈالیں۔ کھالے صاف رکھیں۔',
            ),
          ),
        );
      }
      if (d.maxTemp >= heatMax) {
        out.add(
          WeatherAlert(
            id: 'heat_$key',
            type: AlertType.heat,
            severity: d.maxTemp >= heatMax + 4 ? AlertSeverity.severe : AlertSeverity.warning,
            date: d.date,
            affectedCropTypeIds: userCropTypes,
            title: const LocalizedText('Very hot day', 'بہت گرم دن'),
            message: LocalizedText(
              'Temperature may reach ${d.maxTemp}°C on ${day.en}.',
              '${day.ur} کو درجہ حرارت ${d.maxTemp}°C تک جا سکتا ہے۔',
            ),
            action: const LocalizedText(
              'Irrigate in the early morning or evening. Do not spray in the afternoon heat.',
              'صبح سویرے یا شام کو پانی دیں۔ دوپہر کی گرمی میں اسپرے نہ کریں۔',
            ),
          ),
        );
      }
      if (d.minTemp <= coldMin) {
        out.add(
          WeatherAlert(
            id: 'cold_$key',
            type: AlertType.cold,
            severity: d.minTemp <= 0 ? AlertSeverity.severe : AlertSeverity.warning,
            date: d.date,
            affectedCropTypeIds: userCropTypes,
            title: const LocalizedText('Cold night / frost risk', 'سرد رات / کہر کا خطرہ'),
            message: LocalizedText(
              'Night temperature may drop to ${d.minTemp}°C on ${day.en}.',
              '${day.ur} کو رات کا درجہ حرارت ${d.minTemp}°C تک گر سکتا ہے۔',
            ),
            action: const LocalizedText(
              'A light irrigation before a frosty night can protect the crop. Check leaves in the morning.',
              'کہر والی رات سے پہلے ہلکا پانی فصل کو بچا سکتا ہے۔ صبح پتے دیکھیں۔',
            ),
          ),
        );
      }
      if (d.windKmh >= windKmh) {
        out.add(
          WeatherAlert(
            id: 'wind_$key',
            type: AlertType.wind,
            severity: AlertSeverity.info,
            date: d.date,
            affectedCropTypeIds: userCropTypes,
            title: const LocalizedText('Strong wind', 'تیز ہوا'),
            message: LocalizedText(
              'Wind up to ${d.windKmh} km/h is expected on ${day.en}.',
              '${day.ur} کو ${d.windKmh} کلومیٹر فی گھنٹہ تک ہوا متوقع ہے۔',
            ),
            action: const LocalizedText('Do not spray or irrigate on that day.', 'اس دن اسپرے یا آبپاشی نہ کریں۔'),
          ),
        );
      }
    }
    return out;
  }
}
