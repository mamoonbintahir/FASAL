import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';
import '../../data/models/farm_task.dart';
import '../../data/models/weather.dart';
import '../../providers/core_providers.dart';
import '../../providers/farm_providers.dart';
import '../../widgets/task_widgets.dart';

/// Crop-specific farming calendar built from the sowing date.
class CropCalendarScreen extends ConsumerStatefulWidget {
  const CropCalendarScreen({super.key, required this.cropId});
  final String cropId;

  @override
  ConsumerState<CropCalendarScreen> createState() => _CropCalendarScreenState();
}

class _CropCalendarScreenState extends ConsumerState<CropCalendarScreen> {
  late DateTime _selected = AppDates.dateOnly(ref.read(clockProvider)());
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;
    final view = ref.watch(cropViewProvider(widget.cropId));
    final tasksAsync = ref.watch(tasksProvider);
    final weather = ref.watch(optionalWeatherProvider);
    final today = AppDates.dateOnly(ref.watch(clockProvider)());

    if (view == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: s.cropCalendar, showBack: true, backTooltip: s.back),
              Expanded(
                child: EmptyState(emoji: '🔍', title: s.cropNotFound),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: s.cropCalendar,
              subtitle: '${view.def.emoji} ${view.def.name.of(lang)} · ${s.stageWithName(view.stage.name.of(lang))}',
              showBack: true,
              backTooltip: s.back,
            ),
            Expanded(
              child: AsyncView(
                value: tasksAsync,
                onRetry: () => ref.invalidate(tasksProvider),
                data: (all) {
                  final tasks = all.where((x) => x.cropId == widget.cropId).toList();
                  final dayTasks = tasks.where((x) => AppDates.isSameDay(x.dueDate, _selected)).toList();
                  final comingNext = tasks.where((x) => !x.isDone && x.dueDate.isAfter(_selected)).take(3).toList();
                  return PageBody(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
                    children: [
                      _DateStrip(
                        today: today,
                        selected: _selected,
                        tasks: tasks,
                        weather: weather,
                        onSelect: (d) => setState(() => _selected = d),
                      ),
                      const Gap(16),
                      Padding(
                        padding: AppSpacing.page,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FasalCard(
                              padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppDates.isSameDay(_selected, today)
                                        ? s.todaysTasks
                                        : '${s.weekdayLong(_selected.weekday)}, ${s.shortDate(_selected)}',
                                    style: t.titleLarge,
                                  ),
                                  const Gap(4),
                                  if (dayTasks.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Text(s.noTasksForDay, style: t.bodyMedium),
                                    ),
                                  for (final task in dayTasks) TaskTile(task: task, showImportance: true),
                                ],
                              ),
                            ),
                            const Gap(16),
                            if (comingNext.isNotEmpty)
                              FasalCard(
                                padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.comingNext, style: t.titleLarge),
                                    const Gap(4),
                                    for (final task in comingNext) TaskTile(task: task, showDate: true),
                                  ],
                                ),
                              ),
                            const Gap(20),
                            SegmentedTabs(
                              labels: [s.upcoming, s.completed, s.overdue, s.fullTimeline],
                              selected: _tab,
                              onChanged: (i) => setState(() => _tab = i),
                            ),
                            const Gap(12),
                            _TabContent(tab: _tab, tasks: tasks, today: today, view: view),
                          ],
                        ),
                      ),
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

class _DateStrip extends StatefulWidget {
  const _DateStrip({
    required this.today,
    required this.selected,
    required this.tasks,
    required this.weather,
    required this.onSelect,
  });

  final DateTime today;
  final DateTime selected;
  final List<FarmTask> tasks;
  final WeatherReport? weather;
  final ValueChanged<DateTime> onSelect;

  @override
  State<_DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<_DateStrip> {
  static const _past = 7;
  static const _future = 30;
  static const _itemWidth = 62.0;
  late final ScrollController _controller = ScrollController(initialScrollOffset: (_past - 1) * (_itemWidth + 8));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final days = [for (var i = -_past; i <= _future; i++) widget.today.add(Duration(days: i))];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = days[i];
          final sel = AppDates.isSameDay(d, widget.selected);
          final isToday = AppDates.isSameDay(d, widget.today);
          final has = widget.tasks.any((x) => AppDates.isSameDay(x.dueDate, d));
          DailyForecast? wx;
          for (final f in widget.weather?.daily ?? const <DailyForecast>[]) {
            if (AppDates.isSameDay(f.date, d)) wx = f;
          }
          final fg = sel ? Colors.white : AppColors.textPrimary;
          return Semantics(
            selected: sel,
            button: true,
            label: '${s.weekdayLong(d.weekday)} ${s.shortDate(d)}',
            excludeSemantics: true,
            child: Material(
              color: sel ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => widget.onSelect(d),
                child: Container(
                  width: _itemWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: isToday && !sel ? Border.all(color: AppColors.primary, width: 1.4) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.weekdayShort(d.weekday),
                        style: t.labelSmall?.copyWith(color: sel ? Colors.white70 : AppColors.textSecondary),
                        maxLines: 1,
                      ),
                      Text(
                        '${d.day}',
                        style: t.titleLarge?.copyWith(color: fg, fontFamily: 'Manrope', height: 1.2),
                      ),
                      SizedBox(
                        height: 18,
                        child: wx != null && wx.rainChance >= 40
                            ? Text(wx.condition.emoji, style: const TextStyle(fontSize: 13))
                            : has
                            ? Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: sel ? Colors.white : AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({required this.tab, required this.tasks, required this.today, required this.view});

  final int tab;
  final List<FarmTask> tasks;
  final DateTime today;
  final CropView view;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;

    if (tab == 3) {
      // Full lifecycle grouped by stage.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < view.def.stages.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FasalCard(
                color: i == view.progress.stageIndex ? AppColors.primaryContainer : Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('${i + 1}. ${view.def.stages[i].name.of(lang)}', style: t.titleMedium)),
                        if (i == view.progress.stageIndex) StatusBadge(s.nowBadge),
                        const SizedBox(width: 8),
                      ],
                    ),
                    Text(s.daysRange(view.def.stages[i].startDay, view.def.stages[i].endDay), style: t.labelSmall),
                    for (final task in tasks.where((x) => x.stageIndex == i)) TaskTile(task: task, showDate: true),
                  ],
                ),
              ),
            ),
          // Seed preparation (before sowing) falls into stage 0 above.
        ],
      );
    }

    final status = [TaskStatus.upcoming, TaskStatus.done, TaskStatus.overdue][tab];
    final list = tasks.where((x) {
      final st = x.statusOn(today);
      return status == TaskStatus.upcoming ? (st == TaskStatus.upcoming || st == TaskStatus.today) : st == status;
    }).toList();
    if (status == TaskStatus.done) list.sort((a, b) => b.dueDate.compareTo(a.dueDate));

    if (list.isEmpty) {
      return FasalCard(
        child: EmptyState(
          emoji: status == TaskStatus.overdue ? '👍' : '🗓️',
          title: status == TaskStatus.overdue ? s.noOverdue : s.nothingHere,
          compact: true,
        ),
      );
    }
    return FasalCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(children: [for (final task in list) TaskTile(task: task, showDate: true, showImportance: true)]),
    );
  }
}
