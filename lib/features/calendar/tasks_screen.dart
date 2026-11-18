import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';
import '../../data/models/farm_task.dart';
import '../../providers/core_providers.dart';
import '../../providers/farm_providers.dart';
import '../../widgets/task_widgets.dart';

/// Today's tasks: overdue, today, next 7 days and completed — across all crops.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String? _cropFilter;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;
    final tasksAsync = ref.watch(tasksProvider);
    final views = ref.watch(cropViewsProvider).value ?? const <CropView>[];
    final today = ref.watch(clockProvider)();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: s.todaysTasks, showBack: true, backTooltip: s.back),
            if (views.length > 1)
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  children: [
                    _FilterChip(
                      label: s.allCrops,
                      selected: _cropFilter == null,
                      onTap: () => setState(() => _cropFilter = null),
                    ),
                    for (final v in views)
                      _FilterChip(
                        label:
                            '${v.def.emoji} ${v.def.name.of(lang)}${v.crop.fieldName.isEmpty ? '' : ' · ${v.crop.fieldName}'}',
                        selected: _cropFilter == v.crop.id,
                        onTap: () => setState(() => _cropFilter = v.crop.id),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: AsyncView(
                value: tasksAsync,
                onRetry: () => ref.invalidate(tasksProvider),
                data: (all) {
                  if (views.isEmpty) {
                    return PageBody(
                      children: [
                        EmptyState(
                          emoji: '🗓️',
                          title: s.noCropsTitle,
                          body: s.tasksEmptyBody,
                          actionLabel: s.addCropPlus,
                          onAction: context.toAddCrop,
                        ),
                      ],
                    );
                  }
                  final tasks = all.where((x) => _cropFilter == null || x.cropId == _cropFilter).toList();
                  final overdue = tasks.where((x) => x.statusOn(today) == TaskStatus.overdue).toList();
                  final todays = tasks.where((x) => x.statusOn(today) == TaskStatus.today).toList();
                  final weekEnd = today.add(const Duration(days: 7));
                  final upcoming = tasks
                      .where((x) => x.statusOn(today) == TaskStatus.upcoming && x.dueDate.isBefore(weekEnd))
                      .toList();
                  final done = tasks.where((x) => x.isDone).toList()
                    ..sort((a, b) => (b.completedAt ?? b.dueDate).compareTo(a.completedAt ?? a.dueDate));

                  Widget section(String title, String emoji, List<FarmTask> list, {String? empty, Color? color}) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FasalCard(
                          padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text('$emoji  $title', style: t.titleLarge?.copyWith(color: color)),
                                  ),
                                  const SizedBox(width: 8),
                                  if (list.isNotEmpty) StatusBadge('${list.length}', color: color ?? AppColors.primary),
                                ],
                              ),
                              if (list.isEmpty && empty != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Text(empty, style: t.bodyMedium),
                                ),
                              for (final task in list)
                                TaskTile(task: task, showCrop: views.length > 1, showDate: true, showImportance: true),
                            ],
                          ),
                        ),
                      );

                  return PageBody(
                    onRefresh: () async {
                      ref.invalidate(tasksProvider);
                      await ref.read(tasksProvider.future);
                    },
                    children: [
                      if (overdue.isNotEmpty) section(s.overdue, '⏰', overdue, color: AppColors.error),
                      section(s.today, '📌', todays, empty: s.noTasksToday),
                      section(s.nextSevenDays, '🗓️', upcoming, empty: s.noUpcomingTasks),
                      if (done.isNotEmpty) section(s.completed, '✅', done.take(10).toList()),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primaryContainer,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
