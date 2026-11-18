import 'package:material_ui/material_ui.dart';

import '../core/l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/basics.dart';

import 'package:fasal_core/models.dart';

import '../providers/farm_providers.dart';

/// Green hero card: "Wheat · Day 38 / Tillering / expected harvest".
class CropHeroCard extends StatelessWidget {
  const CropHeroCard({super.key, required this.view, this.onTap});

  final CropView view;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final lang = context.lang;
    final p = view.progress;
    final subtitle = p.notSownYet ? s.sowingInDays(-p.day) : s.cropDay(view.def.name.of(lang), p.day);
    final stageTitle = p.notSownYet ? s.notSownYet : view.stage.name.of(lang);

    return FasalCard(
      color: AppColors.primary,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subtitle, style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.88))),
                    const SizedBox(height: 2),
                    Text(stageTitle, style: t.headlineMedium?.copyWith(color: Colors.white)),
                  ],
                ),
              ),
              EmojiIcon(view.def.emoji, size: 46),
            ],
          ),
          const SizedBox(height: 14),
          StageSegments(count: view.def.stages.length, current: p.notSownYet ? -1 : p.stageIndex),
          const SizedBox(height: 12),
          Text(
            p.readyForHarvest
                ? s.readyForHarvest
                : s.expectedHarvestLine(s.harvestRange(s.shortDate(p.harvestStart), s.shortDate(p.harvestEnd))),
            style: t.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Crop card for the "My Crops" list.
class CropListCard extends StatelessWidget {
  const CropListCard({super.key, required this.view, required this.nextTask, required this.onTap, required this.menu});

  final CropView view;
  final FarmTask? nextTask;
  final VoidCallback onTap;
  final Widget menu;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final lang = context.lang;
    final p = view.progress;
    final c = view.crop;

    return FasalCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EmojiIcon(view.def.emoji, size: 30, background: AppColors.primaryContainer, boxSize: 58),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [view.def.name.of(lang), if (c.variety.isNotEmpty) c.variety].join(' · '),
                      style: t.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [s.areaWithUnit(c.area, c.areaUnit), if (c.fieldName.isNotEmpty) c.fieldName].join(' · '),
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              menu,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    StatusBadge(p.notSownYet ? s.notSownYet : view.stage.name.of(lang), color: AppColors.primary),
                    StatusBadge(
                      p.notSownYet ? s.sowingInDays(-p.day) : s.dayN(p.day),
                      color: AppColors.primary,
                      filled: false,
                    ),
                    StatusBadge(s.sownOn(s.shortDate(c.sowingDate)), color: AppColors.textSecondary, filled: false),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: AppRadius.pillAll,
                  child: LinearProgressIndicator(
                    value: p.fraction,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceMuted,
                    color: AppColors.primary,
                    semanticsLabel: s.progress,
                    semanticsValue: '${(p.fraction * 100).round()}',
                  ),
                ),
                const SizedBox(height: 4),
                Text(s.percentComplete((p.fraction * 100).round()), style: t.labelSmall),
                const Divider(height: 20),
                Row(
                  children: [
                    Text('${s.nextTask}: ', style: t.labelMedium),
                    Expanded(
                      child: Text(
                        nextTask?.title.of(lang) ?? s.noUpcomingTasks,
                        style: t.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical stage timeline (reference "Stage" card).
class StageTimeline extends StatelessWidget {
  const StageTimeline({super.key, required this.view});
  final CropView view;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final lang = context.lang;
    final current = view.progress.notSownYet ? -1 : view.progress.stageIndex;
    return Column(
      children: [
        for (var i = 0; i < view.def.stages.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: i == current ? AppColors.primaryContainer : Colors.transparent,
              borderRadius: AppRadius.mdAll,
            ),
            child: Row(
              children: [
                _StageDot(index: i, done: i < current, now: i == current),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        view.def.stages[i].name.of(lang),
                        style: t.titleSmall?.copyWith(
                          color: i > current ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                      Text(s.daysRange(view.def.stages[i].startDay, view.def.stages[i].endDay), style: t.labelSmall),
                    ],
                  ),
                ),
                if (i == current) StatusBadge(s.nowBadge),
              ],
            ),
          ),
      ],
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({required this.index, required this.done, required this.now});
  final int index;
  final bool done;
  final bool now;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.primary : (now ? Colors.white : AppColors.surfaceMuted),
        border: now ? Border.all(color: AppColors.primary, width: 1.6) : null,
      ),
      child: done
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: now ? AppColors.primary : AppColors.textSecondary,
                fontFamily: 'Manrope',
              ),
            ),
    );
  }
}
