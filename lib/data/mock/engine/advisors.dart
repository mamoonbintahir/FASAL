import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../../models/crop.dart';
import '../../models/crop_definition.dart';
import '../../models/farm_task.dart';
import '../../models/guidance.dart';
import '../../models/localized_text.dart';
import '../../models/weather.dart';
import '../guidance_data.dart';

const _en = AppStrings(isUrdu: false);
const _ur = AppStrings(isUrdu: true);

LocalizedText _day(DateTime d) => LocalizedText(_en.weekdayLong(d.weekday), _ur.weekdayLong(d.weekday));

/// Rule-based irrigation status from tasks + forecast (SAMPLE logic).
/// Phase 2: computed by the backend using real forecasts and crop models.
class IrrigationAdvisor {
  const IrrigationAdvisor();

  IrrigationStatus statusFor({
    required Crop crop,
    required CropDefinition def,
    required List<FarmTask> tasks,
    WeatherReport? weather,
    DateTime? now,
  }) {
    final today = AppDates.dateOnly(now ?? DateTime.now());
    final progress = CropProgress.of(crop, def, today: today);
    if (progress.notSownYet) {
      return const IrrigationStatus(
        kind: IrrigationStatusKind.notStarted,
        headline: LocalizedText('Crop not sown yet', 'ابھی بوائی نہیں ہوئی'),
        explanation: LocalizedText(
          'Irrigation guidance starts after sowing.',
          'آبپاشی کی رہنمائی بوائی کے بعد شروع ہو گی۔',
        ),
      );
    }
    final next = tasks
        .where(
          (t) =>
              t.cropId == crop.id &&
              t.type == TaskType.irrigation &&
              !t.isDone &&
              AppDates.daysBetween(today, t.dueDate) >= -3, // ignore long-missed tasks
        )
        .fold<FarmTask?>(null, (best, t) => best == null || t.dueDate.isBefore(best.dueDate) ? t : best);
    final rain = weather?.nextRain(withinDays: 4, threshold: 60);

    if (rain != null && (next == null || AppDates.daysBetween(rain.date, next.dueDate) <= 3)) {
      final d = _day(rain.date);
      return IrrigationStatus(
        kind: IrrigationStatusKind.hold,
        rainDate: rain.date,
        nextDate: next?.dueDate,
        headline: LocalizedText('Hold irrigation — rain expected ${d.en}', 'آبپاشی روکیں — ${d.ur} کو بارش متوقع ہے'),
        explanation: LocalizedText(
          'Rain is expected; review your irrigation plan. After the rain, check soil moisture before watering.',
          'بارش متوقع ہے؛ آبپاشی کا منصوبہ دوبارہ دیکھیں۔ بارش کے بعد پانی دینے سے پہلے زمین کی نمی چیک کریں۔',
        ),
      );
    }
    if (next != null && AppDates.daysBetween(today, next.dueDate) <= 3) {
      return IrrigationStatus(
        kind: IrrigationStatusKind.dueSoon,
        nextDate: next.dueDate,
        headline: const LocalizedText('Irrigation may be required soon', 'جلد پانی کی ضرورت ہو سکتی ہے'),
        explanation: const LocalizedText(
          'Check soil moisture. If the soil is dry at 10 cm depth, plan irrigation in the morning or evening.',
          'زمین کی نمی چیک کریں۔ اگر 10 سینٹی میٹر پر مٹی خشک ہو تو صبح یا شام پانی کا منصوبہ بنائیں۔',
        ),
      );
    }
    return IrrigationStatus(
      kind: IrrigationStatusKind.ok,
      nextDate: next?.dueDate,
      headline: const LocalizedText('No irrigation needed today', 'آج پانی کی ضرورت نہیں'),
      explanation: const LocalizedText(
        'Soil moisture should be enough for now. Keep an eye on the weather.',
        'ابھی زمین میں نمی کافی ہونی چاہیے۔ موسم پر نظر رکھیں۔',
      ),
    );
  }
}

/// Builds personalised SAMPLE advice from crops, tasks and weather.
class AdviceEngine {
  const AdviceEngine({this.irrigation = const IrrigationAdvisor()});

  final IrrigationAdvisor irrigation;

  List<Advice> build({
    required List<Crop> crops,
    required CropDefinition? Function(String) defById,
    required List<FarmTask> tasks,
    WeatherReport? weather,
    DateTime? now,
  }) {
    final today = AppDates.dateOnly(now ?? DateTime.now());
    final out = <Advice>[];

    // Weather-wide advice
    final rain = weather?.nextRain(withinDays: 5);
    if (rain != null) {
      final d = _day(rain.date);
      out.add(
        Advice(
          id: 'wx_rain',
          category: AdviceCategory.weather,
          emoji: '🌧️',
          important: true,
          title: LocalizedText('Rain likely on ${d.en}', '${d.ur} کو بارش کا امکان'),
          body: const LocalizedText(
            'Avoid spraying and fertilizer just before rain. Clear field channels for drainage.',
            'بارش سے ذرا پہلے اسپرے اور کھاد نہ ڈالیں۔ پانی کے نکاس کے لیے کھالے صاف کریں۔',
          ),
        ),
      );
    }
    final windy = weather?.daily.take(5).where((d) => d.windKmh >= 20).firstOrNull;
    if (windy != null) {
      final d = _day(windy.date);
      out.add(
        Advice(
          id: 'wx_wind',
          category: AdviceCategory.weather,
          emoji: '💨',
          title: LocalizedText('Windy on ${d.en}', '${d.ur} کو تیز ہوا'),
          body: const LocalizedText(
            'Do not spray in wind — the spray drifts and wastes money.',
            'ہوا میں اسپرے نہ کریں — دوا اڑ جاتی ہے اور پیسہ ضائع ہوتا ہے۔',
          ),
        ),
      );
    }

    for (final crop in crops) {
      final def = defById(crop.cropTypeId);
      if (def == null) continue;
      final p = CropProgress.of(crop, def, today: today);
      final stage = def.stages[p.stageIndex];

      // Today: tasks due today / overdue
      for (final t in tasks.where((t) => t.cropId == crop.id)) {
        final st = t.statusOn(today);
        if (st == TaskStatus.today || st == TaskStatus.overdue) {
          out.add(
            Advice(
              id: 'today_${t.id}',
              category: AdviceCategory.today,
              emoji: _emojiFor(t.type),
              cropId: crop.id,
              important: t.importance == Importance.high || st == TaskStatus.overdue,
              title: LocalizedText('${def.name.en}: ${t.title.en}', '${def.name.ur}: ${t.title.ur}'),
              body: t.description,
            ),
          );
        }
      }

      // Crop care: stage summary + what to avoid
      out.add(
        Advice(
          id: 'care_${crop.id}',
          category: AdviceCategory.cropCare,
          emoji: def.emoji,
          cropId: crop.id,
          title: LocalizedText('${def.name.en} — ${stage.name.en} stage', '${def.name.ur} — ${stage.name.ur} کا مرحلہ'),
          body: stage.summary,
        ),
      );
      out.add(
        Advice(
          id: 'avoid_${crop.id}',
          category: AdviceCategory.cropCare,
          emoji: '⚠️',
          cropId: crop.id,
          title: LocalizedText('Avoid now (${def.name.en})', 'ابھی بچیں (${def.name.ur})'),
          body: def.avoidNow[p.stageIndex < def.avoidNow.length ? p.stageIndex : def.avoidNow.length - 1],
        ),
      );

      // Irrigation
      final irr = irrigation.statusFor(crop: crop, def: def, tasks: tasks, weather: weather, now: today);
      out.add(
        Advice(
          id: 'irr_${crop.id}',
          category: AdviceCategory.irrigation,
          emoji: '💧',
          cropId: crop.id,
          important: irr.kind == IrrigationStatusKind.hold || irr.kind == IrrigationStatusKind.dueSoon,
          title: LocalizedText('${def.name.en}: ${irr.headline.en}', '${def.name.ur}: ${irr.headline.ur}'),
          body: irr.explanation,
        ),
      );

      // Fertilizer for the current stage
      for (final f in kFertilizerGuides.where((f) => f.cropTypeId == def.id && f.stageIndex == p.stageIndex)) {
        out.add(
          Advice(
            id: 'fert_${f.id}',
            category: AdviceCategory.fertilizer,
            emoji: '🧪',
            cropId: crop.id,
            title: LocalizedText('${def.name.en}: ${f.name.en}', '${def.name.ur}: ${f.name.ur}'),
            body: f.howTo,
          ),
        );
      }

      // Pests relevant now (rain raises disease risk)
      for (final pest in kPestGuides.where((g) => g.cropTypeId == def.id)) {
        if (pest.riskAfterRain && rain == null) continue;
        out.add(
          Advice(
            id: 'pest_${crop.id}_${pest.id}',
            category: AdviceCategory.pests,
            emoji: pest.emoji,
            cropId: crop.id,
            important: pest.riskAfterRain && rain != null,
            title: LocalizedText('${def.name.en}: ${pest.name.en}', '${def.name.ur}: ${pest.name.ur}'),
            body: pest.prevention,
          ),
        );
      }
    }
    return out;
  }

  static String _emojiFor(TaskType t) => switch (t) {
    TaskType.irrigation => '💧',
    TaskType.fertilizer => '🧪',
    TaskType.weeding => '🌱',
    TaskType.pestMonitoring => '🔍',
    TaskType.harvest || TaskType.harvestPrep => '🌾',
    _ => '📋',
  };
}

/// Rule-based "Ask Fasal" answers (SAMPLE — not AI).
class AssistantEngine {
  const AssistantEngine({this.irrigation = const IrrigationAdvisor()});

  final IrrigationAdvisor irrigation;

  LocalizedText answer({
    required String question,
    required List<Crop> crops,
    required CropDefinition? Function(String) defById,
    required List<FarmTask> tasks,
    WeatherReport? weather,
    DateTime? now,
  }) {
    final today = AppDates.dateOnly(now ?? DateTime.now());
    final q = question.toLowerCase();
    if (crops.isEmpty) {
      return const LocalizedText(
        'Add a crop first, then I can tell you what to do and when.',
        'پہلے فصل شامل کریں، پھر میں بتا سکوں گا کہ کیا کرنا ہے اور کب۔',
      );
    }
    final crop = crops.first;
    final def = defById(crop.cropTypeId);
    if (def == null) {
      return const LocalizedText('I could not find information for this crop.', 'اس فصل کی معلومات نہیں ملیں۔');
    }
    final p = CropProgress.of(crop, def, today: today);
    final stage = def.stages[p.stageIndex];

    bool has(List<String> words) => words.any(q.contains);

    if (has(['water', 'irrigat', 'پانی', 'آبپاشی'])) {
      final s = irrigation.statusFor(crop: crop, def: def, tasks: tasks, weather: weather, now: today);
      return LocalizedText('${s.headline.en}. ${s.explanation.en}', '${s.headline.ur}۔ ${s.explanation.ur}');
    }
    if (has(['fertil', 'کھاد'])) {
      final guides = kFertilizerGuides.where((f) => f.cropTypeId == def.id && f.stageIndex == p.stageIndex).toList();
      if (guides.isEmpty) {
        return LocalizedText(
          'No fertilizer is due for your ${def.name.en} in the ${stage.name.en} stage. Check Crop care for the next one.',
          'آپ کی ${def.name.ur} کو ${stage.name.ur} کے مرحلے میں کوئی کھاد نہیں چاہیے۔ اگلی کھاد کے لیے فصل کی دیکھ بھال دیکھیں۔',
        );
      }
      final g = guides.first;
      return LocalizedText('${g.name.en}: ${g.howTo.en}', '${g.name.ur}: ${g.howTo.ur}');
    }
    if (has(['pest', 'insect', 'disease', 'کیڑ', 'بیماری'])) {
      final pests = kPestGuides.where((g) => g.cropTypeId == def.id).take(2).toList();
      if (pests.isEmpty) {
        return const LocalizedText(
          'Walk your field weekly and look under leaves.',
          'ہر ہفتے کھیت میں چلیں اور پتوں کے نیچے دیکھیں۔',
        );
      }
      return LocalizedText(
        'Watch for ${pests.map((e) => e.name.en).join(' and ')}. ${pests.first.prevention.en}',
        '${pests.map((e) => e.name.ur).join(' اور ')} پر نظر رکھیں۔ ${pests.first.prevention.ur}',
      );
    }
    if (has(['rain', 'weather', 'بارش', 'موسم'])) {
      final rain = weather?.nextRain();
      if (rain == null) {
        return const LocalizedText('No significant rain is expected this week.', 'اس ہفتے خاص بارش متوقع نہیں۔');
      }
      final d = _day(rain.date);
      return LocalizedText(
        'Rain is likely on ${d.en} (${rain.rainChance}%). Avoid spraying and fertilizer just before it.',
        '${d.ur} کو بارش کا امکان ہے (${rain.rainChance}%)۔ اس سے ذرا پہلے اسپرے اور کھاد نہ ڈالیں۔',
      );
    }
    return LocalizedText(
      'Your ${def.name.en} is on day ${p.day}, in the ${stage.name.en} stage. ${stage.summary.en}',
      'آپ کی ${def.name.ur} دن ${p.day} پر ہے، ${stage.name.ur} کے مرحلے میں۔ ${stage.summary.ur}',
    );
  }
}
