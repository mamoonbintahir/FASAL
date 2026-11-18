import '../models/crop.dart';
import '../models/crop_definition.dart';
import '../models/farm_task.dart';

/// Turns a crop + its definition into dated tasks.
/// Phase 2: the backend generates tasks (and can adjust them for weather).
class TaskScheduler {
  const TaskScheduler();

  List<FarmTask> generate(Crop crop, CropDefinition def, Map<String, TaskUserState> states) {
    final sown = DateTime(crop.sowingDate.year, crop.sowingDate.month, crop.sowingDate.day);
    return [
      for (final t in def.templates)
        () {
          final id = '${crop.id}_${t.id}';
          final state = states[id];
          return FarmTask(
            id: id,
            cropId: crop.id,
            cropTypeId: def.id,
            type: t.type,
            title: t.title,
            description: t.description,
            dueDate: sown.add(Duration(days: t.day)),
            importance: t.importance,
            stageIndex: _stageFor(def, t.day),
            completedAt: state?.completedAt,
            reminder: state?.reminder ?? ReminderOption.sameDay,
          );
        }(),
    ]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  /// Product rule shared by app and server: when a crop is added with a past
  /// sowing date, tasks due more than 3 days before it was added count as
  /// already done (the farmer did them before using Fasal).
  Map<String, DateTime> tasksDoneBeforeAdding(Crop crop, CropDefinition def) {
    final cutoff = DateTime(
      crop.createdAt.year,
      crop.createdAt.month,
      crop.createdAt.day,
    ).subtract(const Duration(days: 3));
    final sown = DateTime(crop.sowingDate.year, crop.sowingDate.month, crop.sowingDate.day);
    return {
      for (final t in def.templates)
        if (sown.add(Duration(days: t.day)).isBefore(cutoff)) '${crop.id}_${t.id}': sown.add(Duration(days: t.day)),
    };
  }

  int _stageFor(CropDefinition def, int day) {
    var idx = 0;
    for (var i = 0; i < def.stages.length; i++) {
      if (day >= def.stages[i].startDay) idx = i;
    }
    return idx;
  }
}
