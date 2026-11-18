import 'localized_text.dart';

/// Where a piece of agricultural guidance came from.
/// Phase 1 content is all [sample]. Only expert-reviewed backend content
/// may be marked [verified].
enum GuidanceSource { sample, verified }

class FertilizerGuide {
  const FertilizerGuide({
    required this.id,
    required this.cropTypeId,
    required this.stageIndex,
    required this.name,
    required this.purpose,
    required this.timing,
    required this.howTo,
    required this.precautions,
    this.source = GuidanceSource.sample,
  });

  final String id;
  final String cropTypeId;
  final int stageIndex;
  final LocalizedText name;
  final LocalizedText purpose;
  final LocalizedText timing;
  final LocalizedText howTo;
  final List<LocalizedText> precautions;
  final GuidanceSource source;
}

enum PestKind { pest, disease }

class PestGuide {
  const PestGuide({
    required this.id,
    required this.cropTypeId,
    required this.kind,
    required this.emoji,
    required this.name,
    required this.watchWindow,
    required this.symptoms,
    required this.prevention,
    this.riskAfterRain = false,
    this.source = GuidanceSource.sample,
  });

  final String id;
  final String cropTypeId;
  final PestKind kind;
  final String emoji;
  final LocalizedText name;
  final LocalizedText watchWindow;
  final LocalizedText symptoms;
  final LocalizedText prevention;
  final bool riskAfterRain;
  final GuidanceSource source;
}

/// Pesticide guidance is intentionally limited to a product CATEGORY,
/// timing and safety. No product names or doses are shown in Phase 1.
class PesticideGuide {
  const PesticideGuide({
    required this.id,
    required this.cropTypeId,
    required this.problem,
    required this.category,
    required this.purpose,
    required this.timing,
    required this.safety,
    required this.warnings,
    this.source = GuidanceSource.sample,
  });

  final String id;
  final String cropTypeId;
  final LocalizedText problem;
  final LocalizedText category;
  final LocalizedText purpose;
  final LocalizedText timing;
  final List<LocalizedText> safety;
  final List<LocalizedText> warnings;
  final GuidanceSource source;
}

class IrrigationGuide {
  const IrrigationGuide({
    required this.cropTypeId,
    required this.criticalStages,
    required this.tips,
    this.source = GuidanceSource.sample,
  });

  final String cropTypeId;
  final List<LocalizedText> criticalStages;
  final List<LocalizedText> tips;
  final GuidanceSource source;
}

enum IrrigationStatusKind { hold, dueSoon, ok, notStarted }

/// Computed irrigation advice for one crop at this moment.
class IrrigationStatus {
  const IrrigationStatus({
    required this.kind,
    required this.headline,
    required this.explanation,
    this.nextDate,
    this.rainDate,
  });

  final IrrigationStatusKind kind;
  final LocalizedText headline;
  final LocalizedText explanation;
  final DateTime? nextDate;
  final DateTime? rainDate;
}

enum AdviceCategory { today, cropCare, irrigation, fertilizer, pests, weather }

class Advice {
  const Advice({
    required this.id,
    required this.category,
    required this.emoji,
    required this.title,
    required this.body,
    this.cropId,
    this.important = false,
    this.source = GuidanceSource.sample,
  });

  final String id;
  final AdviceCategory category;
  final String emoji;
  final LocalizedText title;
  final LocalizedText body;
  final String? cropId;
  final bool important;
  final GuidanceSource source;
}

/// Answer produced by "Ask Fasal". Phase 1 answers are rule-based samples.
class AssistantAnswer {
  const AssistantAnswer({required this.question, required this.answer, this.isSample = true});

  final String question;
  final LocalizedText answer;
  final bool isSample;
}
