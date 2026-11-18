import '../../core/utils/date_utils.dart';
import 'localized_text.dart';

enum TaskType { seedPrep, sowing, irrigation, fertilizer, inspection, weeding, pestMonitoring, harvestPrep, harvest }

enum Importance { high, medium, low }

enum ReminderOption { off, sameDay, dayBefore }

enum TaskStatus { done, overdue, today, upcoming }

/// Persisted per-task user state (completion + reminder choice).
class TaskUserState {
  const TaskUserState({this.completedAt, this.reminder = ReminderOption.sameDay});

  final DateTime? completedAt;
  final ReminderOption reminder;

  TaskUserState copyWith({DateTime? completedAt, bool clearCompleted = false, ReminderOption? reminder}) =>
      TaskUserState(
        completedAt: clearCompleted ? null : (completedAt ?? this.completedAt),
        reminder: reminder ?? this.reminder,
      );

  Map<String, dynamic> toJson() => {'completedAt': completedAt?.toIso8601String(), 'reminder': reminder.name};

  factory TaskUserState.fromJson(Map<String, dynamic> json) => TaskUserState(
    completedAt: json['completedAt'] == null ? null : DateTime.tryParse(json['completedAt'] as String),
    reminder: ReminderOption.values.asNameMap()[json['reminder']] ?? ReminderOption.sameDay,
  );
}

/// A concrete farming task for one of the farmer's crops.
class FarmTask {
  const FarmTask({
    required this.id,
    required this.cropId,
    required this.cropTypeId,
    required this.type,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.importance,
    required this.stageIndex,
    this.completedAt,
    this.reminder = ReminderOption.sameDay,
  });

  final String id;
  final String cropId;
  final String cropTypeId;
  final TaskType type;
  final LocalizedText title;
  final LocalizedText description;
  final DateTime dueDate;
  final Importance importance;
  final int stageIndex;
  final DateTime? completedAt;
  final ReminderOption reminder;

  bool get isDone => completedAt != null;

  TaskStatus statusOn(DateTime today) {
    if (isDone) return TaskStatus.done;
    final d = AppDates.dateOnly(dueDate);
    final t = AppDates.dateOnly(today);
    if (d.isBefore(t)) return TaskStatus.overdue;
    if (d.isAtSameMomentAs(t)) return TaskStatus.today;
    return TaskStatus.upcoming;
  }

  FarmTask copyWith({DateTime? completedAt, bool clearCompleted = false, ReminderOption? reminder}) => FarmTask(
    id: id,
    cropId: cropId,
    cropTypeId: cropTypeId,
    type: type,
    title: title,
    description: description,
    dueDate: dueDate,
    importance: importance,
    stageIndex: stageIndex,
    completedAt: clearCompleted ? null : (completedAt ?? this.completedAt),
    reminder: reminder ?? this.reminder,
  );
}
