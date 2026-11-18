import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';
import '../../data/models/guidance.dart';
import '../../data/models/localized_text.dart';
import '../../providers/core_providers.dart';
import '../../providers/farm_providers.dart';
import '../../widgets/listen_button.dart';
import '../../widgets/weather_widgets.dart';
import '../care/crop_selector.dart';

/// Irrigation guidance for one crop, combining its schedule with the forecast.
class IrrigationScreen extends ConsumerStatefulWidget {
  const IrrigationScreen({super.key, this.cropId});
  final String? cropId;

  @override
  ConsumerState<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends ConsumerState<IrrigationScreen> {
  String? _targetKey;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;
    final views = ref.watch(cropViewsProvider).value ?? const <CropView>[];

    CropView? view;
    for (final v in views) {
      if (v.crop.id == (_targetKey ?? widget.cropId)) view = v;
    }
    view ??= views.isEmpty ? null : views.first;

    final status = view == null ? null : ref.watch(irrigationStatusProvider(view.crop.id));
    final guide = view == null ? null : ref.watch(irrigationGuideProvider(view.def.id)).value;
    final weather = ref.watch(weatherProvider);
    final today = ref.watch(clockProvider)();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: s.irrigationGuidance, showBack: true, backTooltip: s.back),
            if (views.length > 1)
              CropSelector(
                selectedKey: view?.crop.id,
                onChanged: (tgt) => setState(() => _targetKey = tgt.view?.crop.id),
              ),
            Expanded(
              child: view == null
                  ? EmptyState(
                      emoji: '💧',
                      title: s.noCropsTitle,
                      body: s.noCropsBody,
                      actionLabel: s.addCropPlus,
                      onAction: context.toAddCrop,
                    )
                  : PageBody(
                      children: [
                        // Status
                        if (status != null)
                          FasalCard(
                            color: switch (status.kind) {
                              IrrigationStatusKind.hold => AppColors.infoContainer,
                              IrrigationStatusKind.dueSoon => AppColors.warningContainer,
                              _ => AppColors.primaryContainer,
                            },
                            shadow: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    EmojiIcon(switch (status.kind) {
                                      IrrigationStatusKind.hold => '🌧️',
                                      IrrigationStatusKind.dueSoon => '💧',
                                      IrrigationStatusKind.notStarted => '🌱',
                                      IrrigationStatusKind.ok => '✅',
                                    }, size: 30),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${view.def.emoji} ${view.def.name.of(lang)} · ${view.stage.name.of(lang)}',
                                            style: t.labelMedium,
                                          ),
                                          Text(status.headline.of(lang), style: t.titleLarge),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(8),
                                Text(status.explanation.of(lang), style: t.bodyLarge),
                                const Gap(10),
                                ListenButton(
                                  id: 'irr_${view.crop.id}',
                                  text: LocalizedText.joinAll([status.headline, status.explanation]),
                                ),
                              ],
                            ),
                          ),
                        const Gap(16),
                        // Next irrigation
                        FasalCard(
                          child: Row(
                            children: [
                              const EmojiIcon('📅', size: 24, background: AppColors.tintBlue, boxSize: 52),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.nextSuggestedIrrigation, style: t.labelMedium),
                                    Text(
                                      status?.nextDate == null
                                          ? s.noUpcomingTasks
                                          : '${s.fullDate(status!.nextDate!)} · ${s.relativeDay(AppDates.daysBetween(today, status.nextDate!))}',
                                      style: t.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(16),
                        // Weather context
                        FasalCard(
                          padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.only(start: 4),
                                child: SectionTitle(s.rainForecast),
                              ),
                              weather.when(
                                skipLoadingOnRefresh: true,
                                loading: () => const LoadingView(height: 90),
                                error: (e, _) => Text(s.weatherUnavailable, style: t.bodyMedium),
                                data: (w) {
                                  final rain = w.nextRain();
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsetsDirectional.only(end: 8),
                                        child: ForecastStrip(days: w.daily),
                                      ),
                                      const Gap(8),
                                      Padding(
                                        padding: const EdgeInsetsDirectional.only(start: 4),
                                        child: Text(
                                          rain == null
                                              ? s.noRainExpected
                                              : s.rainExpectedOn(s.weekdayLong(rain.date.weekday), rain.rainChance),
                                          style: t.titleSmall?.copyWith(
                                            color: rain == null ? AppColors.primary : AppColors.info,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const Gap(16),
                        if (guide != null) ...[
                          FasalCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.irrigationReminders, style: t.titleLarge),
                                const Gap(8),
                                for (final tip in guide.tips)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const EmojiIcon('💡', size: 18),
                                        const SizedBox(width: 10),
                                        Expanded(child: Text(tip.of(lang), style: t.bodyLarge)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Gap(16),
                          FasalCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.criticalStages, style: t.titleLarge),
                                const Gap(8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final st in guide.criticalStages)
                                      StatusBadge('💧 ${st.of(lang)}', color: AppColors.info, filled: false),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Gap(16),
                          InfoNote(s.sampleGuidanceNote, emoji: '🧪'),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
