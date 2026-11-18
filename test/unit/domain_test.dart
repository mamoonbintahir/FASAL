import 'package:fasal/core/l10n/app_strings.dart';
import 'package:fasal/core/utils/formatters.dart';
import 'package:fasal/core/utils/validators.dart';
import 'package:fasal/data/mock/crop_catalog.dart';
import 'package:fasal/data/mock/engine/advisors.dart';
import 'package:fasal/data/mock/engine/task_scheduler.dart';
import 'package:fasal/data/mock/mock_weather_data.dart';
import 'package:fasal/data/models/crop.dart';
import 'package:fasal/data/models/farm_task.dart';
import 'package:fasal/data/models/guidance.dart';
import 'package:fasal/data/models/user_profile.dart';
import 'package:fasal/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';

final _wheat = kCropCatalog.firstWhere((c) => c.id == 'wheat');
final _today = DateTime(2026, 11, 18);

Crop _crop({int day = 38, String type = 'wheat'}) => Crop(
  id: 'c1',
  cropTypeId: type,
  sowingDate: _today.subtract(Duration(days: day)),
  area: 5,
  createdAt: _today,
);

void main() {
  group('Crop catalog (sample data integrity)', () {
    test('every crop has ordered, contiguous stages and matching "avoid" tips', () {
      for (final def in kCropCatalog) {
        expect(def.stages, isNotEmpty, reason: def.id);
        expect(def.avoidNow.length, def.stages.length, reason: def.id);
        expect(def.stages.first.startDay, 0, reason: def.id);
        for (var i = 1; i < def.stages.length; i++) {
          expect(def.stages[i].startDay, def.stages[i - 1].endDay + 1, reason: '${def.id} stage $i');
        }
        expect(def.stages.last.endDay, def.durationDays, reason: def.id);
        expect(def.templates.map((t) => t.id).toSet().length, def.templates.length, reason: '${def.id} template ids');
      }
    });

    test('guidance text never contains numeric doses', () {
      final dose = RegExp(r'\d+\s*(kg|g|ml|l|litre|liter|bag|bags)\b', caseSensitive: false);
      for (final def in kCropCatalog) {
        for (final t in def.templates) {
          expect(dose.hasMatch(t.description.en), isFalse, reason: t.description.en);
        }
      }
    });
  });

  group('CropProgress', () {
    test('day 38 wheat is in Tillering (stage 2 of 6)', () {
      final p = CropProgress.of(_crop(), _wheat, today: _today);
      expect(p.day, 38);
      expect(p.stageIndex, 1);
      expect(_wheat.stages[p.stageIndex].name.en, 'Tillering');
      expect(p.notSownYet, isFalse);
      expect(p.fraction, closeTo(38 / 150, 0.001));
    });

    test('future sowing date is "not sown yet"', () {
      final p = CropProgress.of(_crop(day: -5), _wheat, today: _today);
      expect(p.notSownYet, isTrue);
      expect(p.stageIndex, 0);
      expect(p.fraction, 0);
    });

    test('harvest window is after sowing and ready near the end', () {
      final p = CropProgress.of(_crop(day: 145), _wheat, today: _today);
      expect(p.readyForHarvest, isTrue);
      expect(p.harvestEnd.isAfter(p.harvestStart), isTrue);
    });
  });

  group('TaskScheduler', () {
    test('generates dated, sorted tasks with stable ids and user state', () {
      final crop = _crop();
      final tasks = const TaskScheduler().generate(crop, _wheat, {'c1_irrcheck': TaskUserState(completedAt: _today)});
      expect(tasks.length, _wheat.templates.length);
      for (var i = 1; i < tasks.length; i++) {
        expect(tasks[i].dueDate.isBefore(tasks[i - 1].dueDate), isFalse);
      }
      final check = tasks.firstWhere((t) => t.id == 'c1_irrcheck');
      expect(check.isDone, isTrue);
      expect(check.statusOn(_today), TaskStatus.done);
      final aphid = tasks.firstWhere((t) => t.id == 'c1_aphid1');
      expect(aphid.statusOn(_today), TaskStatus.today);
      final firstIrr = tasks.firstWhere((t) => t.id == 'c1_irr1');
      expect(firstIrr.statusOn(_today), TaskStatus.overdue);
      final jointing = tasks.firstWhere((t) => t.id == 'c1_irr2');
      expect(jointing.statusOn(_today), TaskStatus.upcoming);
    });
  });

  group('Irrigation advisor', () {
    test('holds irrigation when heavy rain is forecast', () {
      final crop = _crop(day: 45); // next irrigation (jointing) due in 5 days, rain in 3
      final tasks = const TaskScheduler().generate(crop, _wheat, {});
      final status = const IrrigationAdvisor().statusFor(
        crop: crop,
        def: _wheat,
        tasks: tasks,
        weather: MockWeatherData.report('Sahiwal', now: _today),
        now: _today,
      );
      expect(status.kind, IrrigationStatusKind.hold);
      expect(status.rainDate, isNotNull);
    });

    test('not started before sowing', () {
      final crop = _crop(day: -3);
      final status = const IrrigationAdvisor().statusFor(crop: crop, def: _wheat, tasks: const [], now: _today);
      expect(status.kind, IrrigationStatusKind.notStarted);
    });
  });

  group('Ask Fasal (sample rules)', () {
    test('answers water questions from irrigation status, in both languages', () {
      final crop = _crop();
      final a = const AssistantEngine().answer(
        question: 'When should I water my crop?',
        crops: [crop],
        defById: (id) => kCropCatalog.firstWhere((c) => c.id == id),
        tasks: const TaskScheduler().generate(crop, _wheat, {}),
        weather: MockWeatherData.report('Sahiwal', now: _today),
        now: _today,
      );
      expect(a.en.toLowerCase(), contains('irrigation'));
      expect(a.ur, isNotEmpty);
    });

    test('asks to add a crop when there are none', () {
      final a = const AssistantEngine().answer(
        question: 'fertilizer?',
        crops: const [],
        defById: (_) => null,
        tasks: const [],
      );
      expect(a.en, contains('Add a crop'));
    });
  });

  group('Validators', () {
    final v = Validators(const AppStrings(isUrdu: false));
    test('farm area', () {
      expect(v.area(''), isNotNull);
      expect(v.area('abc'), isNotNull);
      expect(v.area('0'), isNotNull);
      expect(v.area('5'), isNull);
      expect(v.area('2.5'), isNull);
    });
    test('amount', () {
      expect(v.amount(''), isNotNull);
      expect(v.amount('12.5'), isNotNull);
      expect(v.amount('9000'), isNull);
    });
    test('sowing date window', () {
      expect(v.sowingDate(null, _today), isNotNull);
      expect(v.sowingDate(_today.add(const Duration(days: 90)), _today), isNotNull);
      expect(v.sowingDate(_today.subtract(const Duration(days: 400)), _today), isNotNull);
      expect(v.sowingDate(_today.subtract(const Duration(days: 38)), _today), isNull);
    });
  });

  group('Formatting & localisation', () {
    test('thousands and area', () {
      expect(Fmt.thousands(23500), '23,500');
      expect(Fmt.thousands(500), '500');
      expect(Fmt.thousands(1234567), '1,234,567');
      expect(Fmt.area(5), '5');
      expect(Fmt.area(2.5), '2.5');
    });

    test('Urdu and English strings differ and dates localise', () {
      const en = AppStrings(isUrdu: false);
      const ur = AppStrings(isUrdu: true);
      expect(en.todaysTasks, isNot(ur.todaysTasks));
      expect(en.shortDate(DateTime(2026, 11, 15)), '15 Nov');
      expect(ur.shortDate(DateTime(2026, 11, 15)), '15 نومبر');
      expect(en.areaWithUnit(5, AreaUnit.acre), '5 acres');
      expect(en.areaWithUnit(1, AreaUnit.acre), '1 acre');
    });

    test('settings survive a JSON round trip', () {
      const s = AppSettings(languageCode: 'ur', setupDone: true, speechRate: 0.6, areaUnit: AreaUnit.kanal);
      final back = AppSettings.fromJson(s.toJson());
      expect(back.languageCode, 'ur');
      expect(back.setupDone, isTrue);
      expect(back.speechRate, 0.6);
      expect(back.areaUnit, AreaUnit.kanal);
      expect(back.isUrdu, isTrue);
    });
  });
}
