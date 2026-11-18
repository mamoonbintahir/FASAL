import 'localized_text.dart';
import 'farm_task.dart';

/// A growth stage of a crop, measured in days after sowing.
class CropStageDef {
  const CropStageDef({required this.name, required this.startDay, required this.endDay, required this.summary});

  final LocalizedText name;
  final int startDay;
  final int endDay;

  /// One-line "what is happening / what to focus on" for this stage.
  final LocalizedText summary;
}

/// A recommended farming activity relative to the sowing date.
class TaskTemplate {
  const TaskTemplate({
    required this.id,
    required this.day,
    required this.type,
    required this.title,
    required this.description,
    this.importance = Importance.medium,
  });

  final String id;

  /// Days after sowing (negative = before sowing, e.g. seed preparation).
  final int day;
  final TaskType type;
  final LocalizedText title;
  final LocalizedText description;
  final Importance importance;
}

/// Reference data describing a crop type (wheat, rice, ...).
///
/// Phase 1: bundled SAMPLE data in `data/mock/crop_catalog.dart`.
/// Phase 2: served by the backend and validated by agricultural experts.
class CropDefinition {
  const CropDefinition({
    required this.id,
    required this.emoji,
    required this.name,
    required this.durationDays,
    required this.stages,
    required this.templates,
    this.varieties = const [],
    required this.avoidNow,
  });

  final String id;
  final String emoji;
  final LocalizedText name;
  final int durationDays;
  final List<CropStageDef> stages;
  final List<TaskTemplate> templates;
  final List<String> varieties;

  /// "What should I avoid?" — one entry per stage (same length as [stages]).
  final List<LocalizedText> avoidNow;
}
