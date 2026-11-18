import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/districts.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/network/app_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';
import '../../data/models/farm_task.dart';
import '../../data/models/localized_text.dart';
import '../../data/models/weather.dart';
import '../../providers/core_providers.dart';
import '../../providers/farm_providers.dart';
import '../../widgets/crop_widgets.dart';
import '../../widgets/listen_button.dart';
import '../../widgets/task_widgets.dart';
import '../../widgets/weather_widgets.dart';
import '../weather/alerts_screen.dart' show severityColors;

/// The farmer's dashboard — answers "What should I do today?" first.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _cropPage = 0;

  Future<void> _refresh() async {
    ref.invalidate(weatherProvider);
    ref.invalidate(alertsProvider);
    ref.invalidate(cropsProvider);
    await Future.wait([
      ref.read(cropsProvider.future),
      ref.read(weatherProvider.future).then<Object?>((v) => v, onError: (Object _) => null),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final views = ref.watch(cropViewsProvider);

    return Scaffold(
      body: SafeArea(
        child: PageBody(
          onRefresh: _refresh,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const _Header(),
            const Gap(16),
            const _AlertBanner(),
            AsyncView(
              value: views,
              onRetry: () => ref.invalidate(cropsProvider),
              loading: const Column(children: [SkeletonCard(height: 150), SkeletonCard(height: 220)]),
              data: (list) {
                if (list.isEmpty) {
                  return FasalCard(
                    child: EmptyState(
                      emoji: '🌱',
                      title: s.noCropsTitle,
                      body: s.noCropsBody,
                      actionLabel: s.addCropPlus,
                      onAction: context.toAddCrop,
                      compact: true,
                    ),
                  );
                }
                final int page = _cropPage >= list.length ? list.length - 1 : _cropPage;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CropPager(views: list, page: page, onPage: (i) => setState(() => _cropPage = i)),
                    const Gap(16),
                    _TodayCard(calendarCropId: list[page].crop.id),
                  ],
                );
              },
            ),
            const Gap(16),
            const _QuickActions(),
            const Gap(16),
            _AskFasalCard(onTap: () => context.pushIn<void>('ask')),
            const Gap(16),
            const _WeekCard(),
            const Gap(16),
            FasalCard(
              color: AppColors.secondaryContainer,
              shadow: false,
              onTap: () => context.toCare(null),
              child: Row(
                children: [
                  const EmojiIcon('🧪', size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.cropCare, style: Theme.of(context).textTheme.titleMedium),
                        Text(s.cropCareSub, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: AppColors.textPrimary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileProvider).value;
    final weather = ref.watch(weatherProvider);
    final unread = ref.watch(unreadCountProvider);
    final name = (profile?.name.isNotEmpty ?? false) ? profile!.name : s.farmer;
    final d = profile == null ? null : findDistrict(profile.district);
    final place = d == null ? profile?.locationLabel : '${d.name.of(lang)}, ${d.province.of(lang)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.greeting, style: t.bodyMedium),
              Text('$name 👋', style: t.headlineMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (place != null && place.isNotEmpty)
                Row(
                  children: [
                    const Text('📍', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(place, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
            ],
          ),
        ),
        HeaderIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: s.notifications,
          badge: unread,
          onPressed: () => context.pushIn<void>('notifications'),
        ),
        const SizedBox(width: 8),
        WeatherChip(
          emoji: weather.value?.current.condition.emoji ?? '🌤️',
          temp: weather.value == null ? '--°' : '${weather.value!.current.temperature}°',
          onTap: () => context.go('/weather'),
        ),
      ],
    );
  }
}

/// Highest-priority unread weather alert, or location/weather problems.
class _AlertBanner extends ConsumerWidget {
  const _AlertBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;
    final weather = ref.watch(weatherProvider);
    final alerts = ref.watch(alertsProvider).value ?? const <WeatherAlert>[];
    final now = ref.watch(clockProvider)();

    if (weather.hasError && weather.error is MissingLocationException) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FasalCard(
          color: AppColors.infoContainer,
          shadow: false,
          onTap: () => context.pushIn<void>('profile'),
          child: Row(
            children: [
              const EmojiIcon('📍', size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.missingLocationTitle, style: t.titleMedium),
                    Text(s.missingLocationBody, style: t.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      );
    }

    final active = alerts.where((a) => a.isActive(now)).toList()
      ..sort((a, b) => b.severity.index.compareTo(a.severity.index));
    final alert = active.where((a) => !a.isRead).firstOrNull ?? active.firstOrNull;
    if (alert == null) return const SizedBox.shrink();
    final (fg, bg, border) = severityColors(alert.severity);
    final day = s.weekdayLong(alert.date.weekday);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FasalCard(
        color: bg,
        borderColor: border,
        shadow: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EmojiIcon(alert.type.emoji, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.weatherAlertLabel,
                    style: t.labelSmall?.copyWith(color: fg, letterSpacing: lang == 'ur' ? 0 : 0.6),
                  ),
                  Text('${alert.title.of(lang)} · $day', style: t.titleMedium),
                  const SizedBox(height: 4),
                  Text(alert.message.of(lang), style: t.bodyMedium?.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ListenButton(
                        id: 'alert_${alert.id}',
                        text: LocalizedText.joinAll([alert.title, alert.message, alert.action]),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(alertsProvider.notifier).markRead(alert.id);
                          context.pushIn<void>('alerts');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size(48, 44),
                        ),
                        child: Text(
                          s.viewDetails,
                          style: t.labelMedium?.copyWith(
                            color: AppColors.textPrimary,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropPager extends StatelessWidget {
  const _CropPager({required this.views, required this.page, required this.onPage});
  final List<CropView> views;
  final int page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final current = views[page];
    final hero = CropHeroCard(view: current, onTap: () => context.toCrop(current.crop.id));
    if (views.length == 1) return hero;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < views.length; i++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    key: Key('home_crop_$i'),
                    label: Text(
                      '${views[i].def.emoji} ${views[i].def.name.of(lang)}'
                      '${views[i].crop.fieldName.isEmpty ? '' : ' · ${views[i].crop.fieldName}'}',
                    ),
                    selected: i == page,
                    showCheckmark: false,
                    selectedColor: AppColors.primaryContainer,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: i == page ? AppColors.primary : AppColors.border),
                    onSelected: (_) => onPage(i),
                  ),
                ),
            ],
          ),
        ),
        const Gap(10),
        hero,
      ],
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.calendarCropId});
  final String calendarCropId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final today = ref.watch(clockProvider)();
    final tasksAsync = ref.watch(tasksProvider);

    return FasalCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(s.todaysTasks, actionLabel: s.cropCalendar, onAction: () => context.toCalendar(calendarCropId)),
          AsyncView(
            value: tasksAsync,
            onRetry: () => ref.invalidate(tasksProvider),
            loading: const LoadingView(height: 120),
            data: (tasks) {
              final todays = tasks.where((x) {
                final st = x.statusOn(today);
                return st == TaskStatus.today || (st == TaskStatus.done && _sameDay(x.dueDate, today));
              }).toList();
              final overdue = tasks.where((x) => x.statusOn(today) == TaskStatus.overdue).toList();
              final allDone = todays.isNotEmpty && todays.every((x) => x.isDone);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (todays.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const EmojiIcon('✅', size: 22),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.noTasksToday, style: t.bodyMedium)),
                        ],
                      ),
                    ),
                  for (final task in todays.take(4)) TaskTile(task: task, showCrop: true),
                  if (allDone)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('🎉 ${s.allTasksDone}', style: t.bodySmall?.copyWith(color: AppColors.primary)),
                    ),
                  if (overdue.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: StatusBadge(s.overdueCount(overdue.length), color: AppColors.error, filled: false),
                    ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      key: const Key('home_all_tasks'),
                      onPressed: () => context.pushIn<void>('tasks'),
                      style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                      child: Text(
                        s.seeAll,
                        style: t.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final actions = [
      ('💧', s.irrigation, AppColors.tintBlue, () => context.toIrrigation(null)),
      ('💡', s.advice, AppColors.tintYellow, () => context.pushIn<void>('advice')),
      ('⚠️', s.alerts, AppColors.tintOrange, () => context.pushIn<void>('alerts')),
      ('➕', s.addCrop, AppColors.tintGreen, context.toAddCrop),
    ];
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: FasalCard(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              onTap: actions[i].$4,
              child: Column(
                children: [
                  EmojiIcon(actions[i].$1, size: 22, background: actions[i].$3, boxSize: 44),
                  const SizedBox(height: 6),
                  Text(
                    actions[i].$2,
                    style: t.labelSmall?.copyWith(color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AskFasalCard extends StatelessWidget {
  const _AskFasalCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    return FasalCard(
      color: AppColors.dark,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const EmojiIcon('🎤', size: 26, background: AppColors.primary, boxSize: 58),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.askFasal, style: t.titleLarge?.copyWith(color: Colors.white)),
                Text(s.askFasalSub, style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends ConsumerWidget {
  const _WeekCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final weather = ref.watch(weatherProvider);
    return FasalCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: SectionTitle(s.thisWeek, actionLabel: s.sevenDayForecast, onAction: () => context.go('/weather')),
          ),
          weather.when(
            skipLoadingOnRefresh: true,
            data: (w) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ForecastStrip(
                days: w.daily,
                onDayTap: (d) => showFasalSheet<void>(
                  context,
                  builder: (_) => SheetBody(
                    title: s.dayDetails,
                    children: [ForecastDayDetails(day: d)],
                  ),
                ),
              ),
            ),
            loading: () => const LoadingView(height: 90),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const EmojiIcon('🌥️', size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.weatherUnavailable, style: Theme.of(context).textTheme.bodyMedium)),
                  TextButton(onPressed: () => ref.invalidate(weatherProvider), child: Text(s.retry)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
