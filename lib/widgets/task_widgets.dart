import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/date_utils.dart';
import '../core/widgets/basics.dart';
import '../core/widgets/controls.dart';
import '../core/widgets/feedback.dart';
import '../data/models/farm_task.dart';
import '../data/models/localized_text.dart';
import '../providers/core_providers.dart';
import '../providers/farm_providers.dart';
import '../providers/repository_providers.dart';
import 'listen_button.dart';

extension TaskTypeVisual on TaskType {
  String get emoji => switch (this) {
    TaskType.seedPrep => '🌰',
    TaskType.sowing => '🌱',
    TaskType.irrigation => '💧',
    TaskType.fertilizer => '🧪',
    TaskType.inspection => '🔍',
    TaskType.weeding => '🌿',
    TaskType.pestMonitoring => '🔎',
    TaskType.harvestPrep => '🧺',
    TaskType.harvest => '🌾',
  };

  Color get tint => switch (this) {
    TaskType.irrigation => AppColors.tintBlue,
    TaskType.fertilizer => AppColors.tintPurple,
    TaskType.weeding || TaskType.sowing => AppColors.tintOrange,
    TaskType.inspection || TaskType.pestMonitoring => AppColors.tintGreen,
    TaskType.harvest || TaskType.harvestPrep => AppColors.tintYellow,
    TaskType.seedPrep => AppColors.tintGrey,
  };
}

/// One task row: icon, title (struck through when done), description, check.
class TaskTile extends ConsumerWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.showCrop = false,
    this.showDate = false,
    this.showImportance = false,
  });

  final FarmTask task;
  final bool showCrop;
  final bool showDate;
  final bool showImportance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final today = ref.watch(clockProvider)();
    final status = task.statusOn(today);
    final def = ref.watch(cropCatalogProvider).byId(task.cropTypeId);
    final meta = <String>[
      if (showCrop && def != null) def.name.of(context.lang),
      if (showDate) s.relativeDay(AppDates.daysBetween(today, task.dueDate)),
    ];

    return InkWell(
      borderRadius: AppRadius.mdAll,
      onTap: () => showTaskDetails(context, task),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            EmojiIcon(task.type.emoji, size: 22, background: task.type.tint, boxSize: 50),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title.of(context.lang),
                    style: t.titleMedium?.copyWith(
                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                      color: task.isDone ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    task.description.of(context.lang),
                    style: t.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (meta.isNotEmpty || showImportance || status == TaskStatus.overdue)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (status == TaskStatus.overdue)
                            StatusBadge(s.overdue, color: AppColors.error, filled: false),
                          if (showImportance && task.importance == Importance.high && !task.isDone)
                            StatusBadge(s.importance(Importance.high), color: AppColors.warning, filled: false),
                          if (meta.isNotEmpty) Text(meta.join(' · '), style: t.labelSmall),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            CheckCircle(
              checked: task.isDone,
              semanticLabel: task.isDone ? s.markNotDone : s.markDone,
              onTap: () => toggleTask(context, ref, task),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> toggleTask(BuildContext context, WidgetRef ref, FarmTask task) async {
  final s = context.s;
  final wasDone = task.isDone;
  await ref.read(tasksProvider.notifier).toggle(task);
  if (!context.mounted) return;
  showSnack(context, wasDone ? s.taskReopened : s.taskCompleted);
}

/// Bottom sheet with full activity details, listen, mark done and reminder.
Future<void> showTaskDetails(BuildContext context, FarmTask initial) {
  return showFasalSheet<void>(
    context,
    builder: (_) => _TaskDetailsSheet(taskId: initial.id, fallback: initial),
  );
}

class _TaskDetailsSheet extends ConsumerWidget {
  const _TaskDetailsSheet({required this.taskId, required this.fallback});
  final String taskId;
  final FarmTask fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final tasks = ref.watch(tasksProvider).value ?? const [];
    final task = tasks.where((x) => x.id == taskId).firstOrNull ?? fallback;
    final view = ref.watch(cropViewProvider(task.cropId));
    final today = ref.watch(clockProvider)();
    final status = task.statusOn(today);
    final stageName = view?.def.stages[task.stageIndex].name.of(context.lang);

    return SheetBody(
      title: task.title.of(context.lang),
      footer: PrimaryButton(
        label: task.isDone ? s.markNotDone : s.markDone,
        color: task.isDone ? AppColors.textSecondary : AppColors.primary,
        onPressed: () async {
          await toggleTask(context, ref, task);
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
      children: [
        Row(
          children: [
            EmojiIcon(task.type.emoji, size: 26, background: task.type.tint, boxSize: 56),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.taskType(task.type), style: t.titleSmall),
                  Text(
                    '${s.dueOn(s.fullDate(task.dueDate))} · ${s.relativeDay(AppDates.daysBetween(today, task.dueDate))}',
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusBadge(
              s.taskStatus(status),
              color: switch (status) {
                TaskStatus.done => AppColors.success,
                TaskStatus.overdue => AppColors.error,
                TaskStatus.today => AppColors.warning,
                TaskStatus.upcoming => AppColors.info,
              },
              filled: false,
            ),
            StatusBadge(s.importance(task.importance), color: AppColors.textSecondary, filled: false),
            if (view != null)
              StatusBadge(
                '${view.def.emoji} ${view.def.name.of(context.lang)}',
                color: AppColors.primary,
                filled: false,
              ),
            if (stageName != null) StatusBadge(s.stageWithName(stageName), color: AppColors.secondary, filled: false),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FasalCard(
          shadow: false,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.description.of(context.lang), style: t.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              ListenButton(id: 'task_${task.id}', text: LocalizedText.joinAll([task.title, task.description])),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(s.reminder, style: t.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in ReminderOption.values)
              ChoiceChip(
                label: Text(switch (r) {
                  ReminderOption.off => s.reminderOff,
                  ReminderOption.sameDay => s.reminderSameDay,
                  ReminderOption.dayBefore => s.reminderDayBefore,
                }),
                selected: task.reminder == r,
                showCheckmark: false,
                selectedColor: AppColors.primaryContainer,
                backgroundColor: Colors.white,
                side: BorderSide(color: task.reminder == r ? AppColors.primary : AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
                labelStyle: t.labelMedium?.copyWith(color: AppColors.textPrimary),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                onSelected: (_) async {
                  await ref.read(tasksProvider.notifier).setReminder(task, r);
                  if (context.mounted) showSnack(context, s.reminderSaved);
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(s.reminderNote, style: t.bodySmall),
      ],
    );
  }
}
