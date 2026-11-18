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

  Map<String, dynamic> toJson() => {
    'id': id,
    'cropTypeId': cropTypeId,
    'stageIndex': stageIndex,
    'name': name.toJson(),
    'purpose': purpose.toJson(),
    'timing': timing.toJson(),
    'howTo': howTo.toJson(),
    'precautions': LocalizedText.listToJson(precautions),
    'source': source.name,
  };

  factory FertilizerGuide.fromJson(Map<String, dynamic> j) => FertilizerGuide(
    id: j['id'] as String,
    cropTypeId: j['cropTypeId'] as String,
    stageIndex: (j['stageIndex'] as num?)?.toInt() ?? 0,
    name: LocalizedText.fromJson(j['name'] as Map<String, dynamic>),
    purpose: LocalizedText.fromJson(j['purpose'] as Map<String, dynamic>),
    timing: LocalizedText.fromJson(j['timing'] as Map<String, dynamic>),
    howTo: LocalizedText.fromJson(j['howTo'] as Map<String, dynamic>),
    precautions: LocalizedText.listFromJson(j['precautions']),
    source: GuidanceSource.values.asNameMap()[j['source']] ?? GuidanceSource.sample,
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'cropTypeId': cropTypeId,
    'kind': kind.name,
    'emoji': emoji,
    'name': name.toJson(),
    'watchWindow': watchWindow.toJson(),
    'symptoms': symptoms.toJson(),
    'prevention': prevention.toJson(),
    'riskAfterRain': riskAfterRain,
    'source': source.name,
  };

  factory PestGuide.fromJson(Map<String, dynamic> j) => PestGuide(
    id: j['id'] as String,
    cropTypeId: j['cropTypeId'] as String,
    kind: PestKind.values.asNameMap()[j['kind']] ?? PestKind.pest,
    emoji: j['emoji'] as String? ?? '🐛',
    name: LocalizedText.fromJson(j['name'] as Map<String, dynamic>),
    watchWindow: LocalizedText.fromJson(j['watchWindow'] as Map<String, dynamic>),
    symptoms: LocalizedText.fromJson(j['symptoms'] as Map<String, dynamic>),
    prevention: LocalizedText.fromJson(j['prevention'] as Map<String, dynamic>),
    riskAfterRain: j['riskAfterRain'] as bool? ?? false,
    source: GuidanceSource.values.asNameMap()[j['source']] ?? GuidanceSource.sample,
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'cropTypeId': cropTypeId,
    'problem': problem.toJson(),
    'category': category.toJson(),
    'purpose': purpose.toJson(),
    'timing': timing.toJson(),
    'safety': LocalizedText.listToJson(safety),
    'warnings': LocalizedText.listToJson(warnings),
    'source': source.name,
  };

  factory PesticideGuide.fromJson(Map<String, dynamic> j) => PesticideGuide(
    id: j['id'] as String,
    cropTypeId: j['cropTypeId'] as String,
    problem: LocalizedText.fromJson(j['problem'] as Map<String, dynamic>),
    category: LocalizedText.fromJson(j['category'] as Map<String, dynamic>),
    purpose: LocalizedText.fromJson(j['purpose'] as Map<String, dynamic>),
    timing: LocalizedText.fromJson(j['timing'] as Map<String, dynamic>),
    safety: LocalizedText.listFromJson(j['safety']),
    warnings: LocalizedText.listFromJson(j['warnings']),
    source: GuidanceSource.values.asNameMap()[j['source']] ?? GuidanceSource.sample,
  );
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

  Map<String, dynamic> toJson() => {
    'cropTypeId': cropTypeId,
    'criticalStages': LocalizedText.listToJson(criticalStages),
    'tips': LocalizedText.listToJson(tips),
    'source': source.name,
  };

  factory IrrigationGuide.fromJson(Map<String, dynamic> j) => IrrigationGuide(
    cropTypeId: j['cropTypeId'] as String,
    criticalStages: LocalizedText.listFromJson(j['criticalStages']),
    tips: LocalizedText.listFromJson(j['tips']),
    source: GuidanceSource.values.asNameMap()[j['source']] ?? GuidanceSource.sample,
  );
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

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'headline': headline.toJson(),
    'explanation': explanation.toJson(),
    'nextDate': nextDate?.toIso8601String(),
    'rainDate': rainDate?.toIso8601String(),
  };

  factory IrrigationStatus.fromJson(Map<String, dynamic> j) => IrrigationStatus(
    kind: IrrigationStatusKind.values.asNameMap()[j['kind']] ?? IrrigationStatusKind.ok,
    headline: LocalizedText.fromJson(j['headline'] as Map<String, dynamic>),
    explanation: LocalizedText.fromJson(j['explanation'] as Map<String, dynamic>),
    nextDate: j['nextDate'] == null ? null : DateTime.tryParse(j['nextDate'] as String),
    rainDate: j['rainDate'] == null ? null : DateTime.tryParse(j['rainDate'] as String),
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'emoji': emoji,
    'title': title.toJson(),
    'body': body.toJson(),
    'cropId': cropId,
    'important': important,
    'source': source.name,
  };

  factory Advice.fromJson(Map<String, dynamic> j) => Advice(
    id: j['id'] as String,
    category: AdviceCategory.values.asNameMap()[j['category']] ?? AdviceCategory.today,
    emoji: j['emoji'] as String? ?? '💡',
    title: LocalizedText.fromJson(j['title'] as Map<String, dynamic>),
    body: LocalizedText.fromJson(j['body'] as Map<String, dynamic>),
    cropId: j['cropId'] as String?,
    important: j['important'] as bool? ?? false,
    source: GuidanceSource.values.asNameMap()[j['source']] ?? GuidanceSource.sample,
  );
}

/// Answer produced by "Ask Fasal". Phase 1 answers are rule-based samples.
class AssistantAnswer {
  const AssistantAnswer({required this.question, required this.answer, this.isSample = true});

  final String question;
  final LocalizedText answer;
  final bool isSample;

  Map<String, dynamic> toJson() => {'question': question, 'answer': answer.toJson(), 'isSample': isSample};

  factory AssistantAnswer.fromJson(Map<String, dynamic> j) => AssistantAnswer(
    question: j['question'] as String? ?? '',
    answer: LocalizedText.fromJson(j['answer'] as Map<String, dynamic>),
    isSample: j['isSample'] as bool? ?? true,
  );
}
