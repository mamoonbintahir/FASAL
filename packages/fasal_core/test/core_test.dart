import 'dart:convert';

import 'package:fasal_core/fasal_core.dart';
import 'package:test/test.dart';

/// Encodes to a JSON string and back, like the network does.
Map<String, dynamic> _wire(Map<String, dynamic> m) => jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

void main() {
  final today = DateTime(2026, 11, 18);
  final wheat = kCropCatalog.firstWhere((c) => c.id == 'wheat');
  final crop = Crop(
    id: 'c1',
    cropTypeId: 'wheat',
    variety: 'Akbar-2019',
    sowingDate: today.subtract(const Duration(days: 38)),
    area: 5,
    seedKg: 50,
    createdAt: today,
  );

  group('JSON round trips (app ⇄ server contract)', () {
    test('crop, profile, task', () {
      final c = Crop.fromJson(_wire(crop.toJson()));
      expect(c.variety, 'Akbar-2019');
      expect(c.seedKg, 50);
      final p = UserProfile.fromJson(
        _wire(const UserProfile(district: 'Sahiwal', farmArea: 2.5, areaUnit: AreaUnit.kanal).toJson()),
      );
      expect(p.areaUnit, AreaUnit.kanal);
      expect(p.farmArea, 2.5);
      final task = const TaskScheduler().generate(crop, wheat, {}).first;
      final back = FarmTask.fromJson(_wire(task.copyWith(completedAt: today).toJson()));
      expect(back.id, task.id);
      expect(back.title, task.title);
      expect(back.isDone, isTrue);
      expect(back.type, task.type);
    });

    test('weather report and alerts', () {
      final report = WeatherReport(
        location: 'Sahiwal',
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
        daily: [
          for (var i = 0; i < 3; i++)
            DailyForecast(
              date: today.add(Duration(days: i)),
              condition: i == 2 ? WeatherCondition.heavyRain : WeatherCondition.sunny,
              minTemp: 3,
              maxTemp: 39,
              rainChance: i == 2 ? 90 : 0,
              windKmh: i == 1 ? 35 : 8,
              humidity: 50,
            ),
        ],
        updatedAt: today,
        isSample: false,
      );
      final back = WeatherReport.fromJson(_wire(report.toJson()));
      expect(back.daily, hasLength(3));
      expect(back.daily[2].condition, WeatherCondition.heavyRain);
      expect(back.nextRain()?.date, today.add(const Duration(days: 2)));

      final alerts = const AlertRules().fromForecast(back, userCropTypes: ['wheat']);
      final types = alerts.map((a) => a.type).toSet();
      expect(types, containsAll([AlertType.heavyRain, AlertType.heat, AlertType.cold, AlertType.wind]));
      expect(alerts.map((a) => a.id).toSet().length, alerts.length, reason: 'ids are unique');
      final a = WeatherAlert.fromJson(_wire(alerts.first.toJson()));
      expect(a.id, alerts.first.id);
      expect(a.affectedCropTypeIds, ['wheat']);
    });

    test('guidance, advice, notifications, records', () {
      for (final g in kFertilizerGuides) {
        expect(FertilizerGuide.fromJson(_wire(g.toJson())).precautions, g.precautions);
      }
      for (final g in kPestGuides) {
        expect(PestGuide.fromJson(_wire(g.toJson())).riskAfterRain, g.riskAfterRain);
      }
      for (final g in kPesticideGuides) {
        expect(PesticideGuide.fromJson(_wire(g.toJson())).warnings, g.warnings);
      }
      for (final g in kIrrigationGuides) {
        expect(IrrigationGuide.fromJson(_wire(g.toJson())).tips, g.tips);
      }
      final advice = const AdviceEngine().build(
        crops: [crop],
        defById: (id) => kCropCatalog.firstWhere((c) => c.id == id),
        tasks: const TaskScheduler().generate(crop, wheat, {}),
        now: today,
      );
      expect(advice, isNotEmpty);
      expect(Advice.fromJson(_wire(advice.first.toJson())).title, advice.first.title);

      final n = AppNotification(
        id: 'n1',
        type: NotificationType.weather,
        title: const LocalizedText('a', 'ب'),
        body: const LocalizedText('b', 'ج'),
        createdAt: today,
        target: 'alerts',
      );
      expect(AppNotification.fromJson(_wire(n.toJson())).target, 'alerts');
      final e = ExpenseRecord(id: 'e1', category: ExpenseCategory.seeds, amount: 9000, date: today);
      expect(ExpenseRecord.fromJson(_wire(e.toJson())).amount, 9000);
    });
  });

  group('rules', () {
    test('tasks due >3 days before adding count as done', () {
      final done = const TaskScheduler().tasksDoneBeforeAdding(crop, wheat);
      expect(done.keys, contains('c1_irr1'));
      expect(done.keys, isNot(contains('c1_irrcheck')), reason: 'due today');
    });

    test('phone normalisation', () {
      expect(normalizePkPhone('0300 1234567'), '+923001234567');
      expect(normalizePkPhone('+92-321-9876543'), '+923219876543');
      expect(normalizePkPhone('042 1234567'), isNull);
    });

    test('districts have coordinates inside Pakistan', () {
      for (final d in kDistricts) {
        expect(d.lat, inInclusiveRange(23.5, 37.5), reason: d.name.en);
        expect(d.lon, inInclusiveRange(60.5, 77.5), reason: d.name.en);
      }
    });

    test('weekday names', () {
      expect(AppDates.weekdayName(DateTime(2026, 11, 18).weekday).en, 'Wednesday');
      expect(AppDates.weekdayName(7).ur, 'اتوار');
    });
  });
}
