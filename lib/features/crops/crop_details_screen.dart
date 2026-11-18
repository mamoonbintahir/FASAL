import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/districts.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';
import '../../data/models/farm_task.dart';
import '../../data/models/guidance.dart';
import '../../data/models/localized_text.dart';
import '../../providers/core_providers.dart';
import '../../providers/farm_providers.dart';
import '../../widgets/crop_widgets.dart';
import '../../widgets/listen_button.dart';
import '../../widgets/task_widgets.dart';
import 'my_crops_screen.dart';

/// Everything about one crop: what to do now, stage, harvest, guidance.
class CropDetailsScreen extends ConsumerWidget {
  const CropDetailsScreen({super.key, required this.cropId});
  final String cropId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;
    final cropsLoading = ref.watch(cropsProvider).isLoading;
    final view = ref.watch(cropViewProvider(cropId));

    if (view == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: s.myCrops, showBack: true, backTooltip: s.back),
              Expanded(
                child: cropsLoading ? const LoadingView() : EmptyState(emoji: '🔍', title: s.cropNotFound),
              ),
            ],
          ),
        ),
      );
    }

    final p = view.progress;
    final c = view.crop;
    final today = ref.watch(clockProvider)();
    final tasks = (ref.watch(tasksProvider).value ?? const <FarmTask>[]).where((x) => x.cropId == cropId).toList();
    final doNow = tasks.where((x) {
      final st = x.statusOn(today);
      return st == TaskStatus.today || st == TaskStatus.overdue;
    }).toList();
    final upcoming = tasks.where((x) => x.statusOn(today) == TaskStatus.upcoming).take(3).toList();
    final irrigation = ref.watch(irrigationStatusProvider(cropId));
    final stageText = p.notSownYet ? speakable((s, _) => s.notSownYet) : view.stage.summary;
    final avoid =
        view.def.avoidNow[p.stageIndex < view.def.avoidNow.length ? p.stageIndex : view.def.avoidNow.length - 1];
    final next = view.nextStage;
    final district = c.location.isEmpty ? null : findDistrict(c.location);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: view.def.name.of(lang),
              leadingEmoji: view.def.emoji,
              subtitle:
                  '${s.areaWithUnit(c.area, c.areaUnit)} · ${p.notSownYet ? s.sowingInDays(-p.day) : s.dayN(p.day)}',
              showBack: true,
              backTooltip: s.back,
              actions: [CropMenu(view: view, afterRemove: GoRouter.of(context).pop)],
            ),
            Expanded(
              child: PageBody(
                children: [
                  // What to do now
                  FasalCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(s.whatToDoNow, style: t.titleLarge)),
                            ListenButton(
                              id: 'crop_now_$cropId',
                              text: LocalizedText.joinAll([
                                speakable((s, l) => s.stageWithName(view.stage.name.of(l))),
                                stageText,
                                ...doNow.map((x) => x.title),
                              ]),
                            ),
                          ],
                        ),
                        const Gap(6),
                        Text(stageText.of(lang), style: t.bodyLarge),
                        if (doNow.isNotEmpty) const Divider(height: 24),
                        for (final task in doNow) TaskTile(task: task, showDate: true),
                        if (doNow.isEmpty) ...[const Gap(8), Text('✅ ${s.noTasksToday}', style: t.bodyMedium)],
                      ],
                    ),
                  ),
                  const Gap(16),
                  // Stage timeline
                  FasalCard(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(s.stage, style: t.titleLarge)),
                              Text(s.percentComplete((p.fraction * 100).round()), style: t.labelMedium),
                            ],
                          ),
                        ),
                        const Gap(10),
                        StageTimeline(view: view),
                      ],
                    ),
                  ),
                  const Gap(16),
                  // Expected harvest
                  FasalCard(
                    color: AppColors.secondaryContainer,
                    shadow: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.expectedHarvest, style: t.bodyMedium?.copyWith(color: AppColors.secondary)),
                        Text(
                          s.harvestRange(s.dayMonth(p.harvestStart), s.dayMonth(p.harvestEnd)),
                          style: t.headlineSmall,
                        ),
                        Text(s.harvestEstimateNote, style: t.bodySmall),
                      ],
                    ),
                  ),
                  const Gap(16),
                  // Guidance tiles
                  TileGrid(
                    minTileWidth: 140,
                    children: [
                      _Tile(emoji: '📅', label: s.cropCalendar, onTap: () => context.toCalendar(cropId)),
                      _Tile(emoji: '🧪', label: s.cropCare, onTap: () => context.toCare(cropId)),
                      _Tile(emoji: '💧', label: s.irrigation, onTap: () => context.toIrrigation(cropId)),
                      _Tile(emoji: '📒', label: s.cropHistory, onTap: () => context.pushIn<void>('history/$cropId')),
                    ],
                  ),
                  const Gap(16),
                  // Weather for this crop
                  if (irrigation != null)
                    FasalCard(
                      onTap: () => context.toIrrigation(cropId),
                      child: Row(
                        children: [
                          EmojiIcon(
                            irrigation.kind == IrrigationStatusKind.hold ? '🌧️' : '💧',
                            size: 24,
                            background: AppColors.tintBlue,
                            boxSize: 50,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.weatherForCrop, style: t.labelMedium),
                                Text(irrigation.headline.of(lang), style: t.titleMedium),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  const Gap(16),
                  // Coming next + avoid
                  FasalCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.whatsNext, style: t.titleLarge),
                        if (next != null) ...[
                          const Gap(6),
                          Text(
                            '${next.name.of(lang)} · ${s.relativeDay(AppDates.daysBetween(today, AppDates.dateOnly(c.sowingDate).add(Duration(days: next.startDay))))}',
                            style: t.titleSmall?.copyWith(color: AppColors.primary),
                          ),
                          Text(next.summary.of(lang), style: t.bodyMedium),
                        ],
                        if (upcoming.isNotEmpty) const Divider(height: 24),
                        for (final task in upcoming) TaskTile(task: task, showDate: true),
                        if (upcoming.isEmpty && next == null) Text(s.noUpcomingTasks, style: t.bodyMedium),
                      ],
                    ),
                  ),
                  const Gap(16),
                  FasalCard(
                    color: AppColors.warningContainer,
                    shadow: false,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const EmojiIcon('⚠️', size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.whatToAvoid, style: t.titleMedium),
                              Text(avoid.of(lang), style: t.bodyMedium?.copyWith(color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  // Overview
                  FasalCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.overview, style: t.titleLarge),
                        const Gap(8),
                        _InfoRow(s.sowingDate, s.fullDate(c.sowingDate)),
                        _InfoRow(s.daysSinceSowing, p.notSownYet ? '—' : '${p.day}'),
                        if (c.variety.isNotEmpty) _InfoRow(s.variety, c.variety),
                        _InfoRow(s.farmArea, s.areaWithUnit(c.area, c.areaUnit)),
                        if (c.seedKg != null) _InfoRow(s.seedUsedKg, Fmt.area(c.seedKg!)),
                        if (c.fieldName.isNotEmpty) _InfoRow(s.fieldName, c.fieldName),
                        if (c.location.isNotEmpty) _InfoRow(s.location, district?.name.of(lang) ?? c.location),
                      ],
                    ),
                  ),
                  const Gap(16),
                  AddCropDashed(onTap: context.toAddCrop),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.emoji, required this.label, required this.onTap});
  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FasalCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmojiIcon(emoji, size: 28),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.titleSmall, maxLines: 2),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: t.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value, style: t.titleSmall, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
