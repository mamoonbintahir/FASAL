import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';

import 'package:fasal_core/models.dart';

import '../../providers/farm_providers.dart';
import '../../widgets/listen_button.dart';

/// Personalised advice grouped into simple categories.
class AdviceScreen extends ConsumerStatefulWidget {
  const AdviceScreen({super.key});

  @override
  ConsumerState<AdviceScreen> createState() => _AdviceScreenState();
}

class _AdviceScreenState extends ConsumerState<AdviceScreen> {
  AdviceCategory _category = AdviceCategory.today;

  static const _emoji = {
    AdviceCategory.today: '📌',
    AdviceCategory.cropCare: '🌱',
    AdviceCategory.irrigation: '💧',
    AdviceCategory.fertilizer: '🧪',
    AdviceCategory.pests: '🐛',
    AdviceCategory.weather: '🌦️',
  };

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;
    final advice = ref.watch(adviceProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: s.farmingAdvice, showBack: true, backTooltip: s.back),
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                children: [
                  for (final c in AdviceCategory.values)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text('${_emoji[c]} ${s.adviceCategory(c)}'),
                        selected: _category == c,
                        showCheckmark: false,
                        selectedColor: AppColors.primaryContainer,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: _category == c ? AppColors.primary : AppColors.border),
                        labelStyle: t.labelMedium?.copyWith(color: AppColors.textPrimary),
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: AsyncView(
                value: advice,
                onRetry: () => ref.invalidate(adviceProvider),
                data: (all) {
                  final list = all.where((a) => a.category == _category).toList()
                    ..sort((a, b) => (b.important ? 1 : 0).compareTo(a.important ? 1 : 0));
                  return PageBody(
                    onRefresh: () async {
                      ref.invalidate(adviceProvider);
                      await ref.read(adviceProvider.future);
                    },
                    children: [
                      if (list.isEmpty) EmptyState(emoji: _emoji[_category]!, title: s.noAdvice, compact: true),
                      for (final a in list) ...[
                        FasalCard(
                          borderColor: a.important ? AppColors.warningBorder : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  EmojiIcon(a.emoji, size: 22, background: AppColors.tintGreen, boxSize: 44),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(a.title.of(lang), style: t.titleMedium)),
                                ],
                              ),
                              const Gap(8),
                              Text(a.body.of(lang), style: t.bodyLarge),
                              const Gap(10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ListenButton(id: 'advice_${a.id}', text: LocalizedText.joinAll([a.title, a.body])),
                                  if (a.important)
                                    StatusBadge(s.importance(Importance.high), color: AppColors.warning, filled: false),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Gap(12),
                      ],
                      InfoNote(s.sampleGuidanceNote, emoji: '🧪'),
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
