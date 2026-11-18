import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';

import 'package:fasal_core/models.dart';

import '../../providers/farm_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/listen_button.dart';
import 'crop_selector.dart';

/// Crop care: Fertilizer · Pests & diseases · Sprays (pesticide safety).
class CropCareScreen extends ConsumerStatefulWidget {
  const CropCareScreen({super.key, this.cropId, this.initialTab = 0});

  final String? cropId;
  final int initialTab;

  @override
  ConsumerState<CropCareScreen> createState() => _CropCareScreenState();
}

class _CropCareScreenState extends ConsumerState<CropCareScreen> {
  late int _tab = widget.initialTab.clamp(0, 2).toInt();
  String? _targetKey;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final targets = CropSelector.targets(ref);
    CropTarget? target;
    for (final tgt in targets) {
      if (tgt.key == _targetKey) target = tgt;
    }
    target ??= initialTarget(ref, widget.cropId);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: s.cropCare, showBack: true, backTooltip: s.back),
            CropSelector(selectedKey: target?.key, onChanged: (tgt) => setState(() => _targetKey = tgt.key)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: SegmentedTabs(
                labels: [s.fertilizer, s.pests, s.sprays],
                emojis: const ['🧪', '🐛', '🧴'],
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: target == null
                  ? EmptyState(emoji: '🌱', title: s.noGuidance)
                  : switch (_tab) {
                      0 => _FertilizerTab(target: target),
                      1 => _PestsTab(target: target),
                      _ => _SpraysTab(target: target),
                    },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _sourceNote(BuildContext context, GuidanceSource source) => InfoNote(
  source == GuidanceSource.verified ? context.s.verifiedGuidanceNote : context.s.sampleGuidanceNote,
  emoji: source == GuidanceSource.verified ? '✅' : '🧪',
);

class _FertilizerTab extends ConsumerWidget {
  const _FertilizerTab({required this.target});
  final CropTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = context.lang;
    final def = ref.watch(cropCatalogProvider).byId(target.cropTypeId);
    final currentStage = target.view?.progress.stageIndex;
    return AsyncView(
      value: ref.watch(fertilizerGuidesProvider(target.cropTypeId)),
      onRetry: () => ref.invalidate(fertilizerGuidesProvider(target.cropTypeId)),
      data: (guides) {
        if (guides.isEmpty) return EmptyState(emoji: '🧪', title: s.noGuidance);
        // Current stage first, then upcoming, then earlier.
        final sorted = [...guides]
          ..sort((a, b) {
            int rank(FertilizerGuide g) {
              if (currentStage == null) return g.stageIndex;
              if (g.stageIndex == currentStage) return -100;
              return g.stageIndex > currentStage ? g.stageIndex : 100 + g.stageIndex;
            }

            return rank(a).compareTo(rank(b));
          });
        return PageBody(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            for (final g in sorted) ...[
              _GuideCard(
                id: 'fert_${g.id}',
                title: g.name.of(lang),
                tag: def == null
                    ? null
                    : (g.stageIndex == currentStage
                          ? s.stageNow(def.stages[g.stageIndex].name.of(lang))
                          : s.stageLater(def.stages[g.stageIndex].name.of(lang))),
                highlight: g.stageIndex == currentStage,
                summary: g.howTo.of(lang),
                speak: LocalizedText.joinAll([g.name, g.purpose, g.howTo]),
                sections: [
                  (s.purpose, [g.purpose.of(lang)]),
                  (s.timing, [g.timing.of(lang)]),
                  (s.precautions, g.precautions.map((p) => p.of(lang)).toList()),
                ],
                initiallyExpanded: g.stageIndex == currentStage,
              ),
              const Gap(12),
            ],
            _sourceNote(context, guides.first.source),
          ],
        );
      },
    );
  }
}

class _PestsTab extends ConsumerWidget {
  const _PestsTab({required this.target});
  final CropTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;
    return AsyncView(
      value: ref.watch(pestGuidesProvider(target.cropTypeId)),
      onRetry: () => ref.invalidate(pestGuidesProvider(target.cropTypeId)),
      data: (guides) => PageBody(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (guides.isEmpty) EmptyState(emoji: '🐛', title: s.noGuidance, compact: true),
          for (final g in guides) ...[
            _GuideCard(
              id: 'pest_${g.id}',
              emoji: g.emoji,
              title: g.name.of(lang),
              tag: g.watchWindow.of(lang),
              badge: g.kind == PestKind.disease ? s.diseaseLabel : s.pestLabel,
              summary: g.symptoms.of(lang),
              speak: LocalizedText.joinAll([g.name, g.watchWindow, g.symptoms, g.prevention]),
              sections: [
                (s.symptoms, [g.symptoms.of(lang)]),
                (s.prevention, [g.prevention.of(lang)]),
                if (g.riskAfterRain) ('🌧️', [s.riskAfterRain]),
              ],
            ),
            const Gap(12),
          ],
          // Honest entry point for a future feature.
          FasalCard(
            onTap: () => showFasalSheet<void>(
              context,
              builder: (_) => SheetBody(
                title: s.photoDiagnosis,
                children: [EmptyState(emoji: '📷', title: s.comingSoon, body: s.photoDiagnosisBody, compact: true)],
              ),
            ),
            child: Row(
              children: [
                const EmojiIcon('📷', size: 24, background: AppColors.tintGrey, boxSize: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.photoDiagnosis, style: t.titleSmall),
                      Text(s.comingSoon, style: t.bodySmall),
                    ],
                  ),
                ),
                StatusBadge(s.comingSoon, color: AppColors.textSecondary, filled: false),
              ],
            ),
          ),
          const Gap(12),
          if (guides.isNotEmpty) _sourceNote(context, guides.first.source),
        ],
      ),
    );
  }
}

class _SpraysTab extends ConsumerWidget {
  const _SpraysTab({required this.target});
  final CropTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = context.lang;
    return AsyncView(
      value: ref.watch(pesticideGuidesProvider(target.cropTypeId)),
      onRetry: () => ref.invalidate(pesticideGuidesProvider(target.cropTypeId)),
      data: (guides) => PageBody(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          InfoNote(s.noDoseNote, emoji: '⚠️', color: AppColors.warningContainer, textColor: AppColors.textPrimary),
          const Gap(12),
          if (guides.isEmpty) EmptyState(emoji: '🧴', title: s.noGuidance, compact: true),
          for (final g in guides) ...[
            _GuideCard(
              id: 'spray_${g.id}',
              emoji: '🧴',
              title: g.problem.of(lang),
              tag: '${s.productCategory}: ${g.category.of(lang)}',
              summary: g.purpose.of(lang),
              speak: LocalizedText.joinAll([g.problem, g.category, g.purpose, g.timing, ...g.safety]),
              sections: [
                (s.purpose, [g.purpose.of(lang)]),
                (s.timing, [g.timing.of(lang)]),
                (s.safety, g.safety.map((x) => x.of(lang)).toList()),
                (s.warnings, g.warnings.map((x) => x.of(lang)).toList()),
              ],
            ),
            const Gap(12),
          ],
          if (guides.isNotEmpty) _sourceNote(context, guides.first.source),
        ],
      ),
    );
  }
}

/// Expandable guidance card: title, tag, summary, Listen, and detail sections.
class _GuideCard extends StatefulWidget {
  const _GuideCard({
    required this.id,
    required this.title,
    required this.summary,
    required this.speak,
    required this.sections,
    this.tag,
    this.badge,
    this.emoji,
    this.highlight = false,
    this.initiallyExpanded = false,
  });

  final String id;
  final String title;
  final String? tag;
  final String? badge;
  final String? emoji;
  final String summary;
  final LocalizedText speak;
  final List<(String, List<String>)> sections;
  final bool highlight;
  final bool initiallyExpanded;

  @override
  State<_GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<_GuideCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return FasalCard(
      borderColor: widget.highlight ? AppColors.primary : null,
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.emoji != null) ...[EmojiIcon(widget.emoji!, size: 24), const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: t.titleMedium),
                    if (widget.tag != null)
                      Text(
                        widget.tag!,
                        style: t.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
              ListenButton(id: widget.id, text: widget.speak),
            ],
          ),
          if (widget.badge != null) ...[
            const Gap(6),
            StatusBadge(widget.badge!, color: AppColors.secondary, filled: false),
          ],
          const Gap(8),
          Text(widget.summary, style: t.bodyLarge),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 24),
                for (final (title, lines) in widget.sections) ...[
                  Text(title, style: t.titleSmall),
                  const SizedBox(height: 4),
                  for (final line in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('•  ', style: t.bodyMedium),
                          Expanded(
                            child: Text(line, style: t.bodyMedium?.copyWith(color: AppColors.textPrimary)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
