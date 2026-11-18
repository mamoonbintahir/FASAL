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

/// "Ask Fasal". Phase 1: suggested/typed questions answered by rule-based
/// SAMPLE logic from the crop calendar + weather. Voice input arrives in
/// Phase 2 — the mic explains this honestly instead of pretending.
class AskFasalScreen extends ConsumerStatefulWidget {
  const AskFasalScreen({super.key});

  @override
  ConsumerState<AskFasalScreen> createState() => _AskFasalScreenState();
}

class _AskFasalScreenState extends ConsumerState<AskFasalScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<AssistantAnswer> _answers = [];
  bool _thinking = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _ask(String question) async {
    final q = question.trim();
    if (q.isEmpty || _thinking) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    setState(() => _thinking = true);
    try {
      final crops = await ref.read(cropsProvider.future);
      final tasks = await ref.read(tasksProvider.future);
      final weather = ref.read(optionalWeatherProvider);
      final a = await ref
          .read(recommendationRepositoryProvider)
          .ask(question: q, crops: crops, tasks: tasks, weather: weather);
      if (!mounted) return;
      setState(() => _answers.add(a));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      if (mounted) showSnack(context, context.s.genericErrorTitle);
    } finally {
      if (mounted) setState(() => _thinking = false);
    }
  }

  void _micTapped() {
    final s = context.s;
    showFasalSheet<void>(
      context,
      builder: (ctx) => SheetBody(
        title: s.voiceInputSoonTitle,
        footer: PrimaryButton(label: s.close, onPressed: () => Navigator.of(ctx).pop()),
        children: [EmptyState(emoji: '🎤', title: s.comingSoon, body: s.voiceInputSoonBody, compact: true)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;
    final suggestions = [s.askQ1, s.askQ2, s.askQ3, s.askQ4];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: s.askFasal, showBack: true, backTooltip: s.back),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      if (_answers.isEmpty) ...[
                        const Gap(16),
                        Center(
                          child: Semantics(
                            button: true,
                            label: s.tapAndSpeak,
                            child: GestureDetector(
                              onTap: _micTapped,
                              child: Container(
                                width: 128,
                                height: 128,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 30,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: const Text('🎤', style: TextStyle(fontSize: 54)),
                              ),
                            ),
                          ),
                        ),
                        const Gap(18),
                        Text(s.tapAndSpeak, style: t.titleLarge, textAlign: TextAlign.center),
                        const Gap(28),
                      ],
                      for (final a in _answers) ...[
                        _Bubble(text: a.question, mine: true, label: s.you),
                        const Gap(8),
                        _Bubble(
                          text: a.answer.of(lang),
                          mine: false,
                          label: s.appName,
                          footer: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Gap(8),
                              ListenButton(id: 'ask_${_answers.indexOf(a)}', text: a.answer),
                              if (a.isSample) ...[const Gap(8), Text('🧪 ${s.sampleAnswerNote}', style: t.labelSmall)],
                            ],
                          ),
                        ),
                        const Gap(16),
                      ],
                      if (_thinking)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      Text(s.tryAsking, style: t.labelMedium),
                      const Gap(8),
                      for (final q in suggestions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FasalCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            radius: AppRadius.md,
                            onTap: () => _ask(q),
                            child: Row(
                              children: [
                                const Text('💬', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(q, style: t.titleSmall)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Input bar
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _ask,
                      style: t.bodyLarge,
                      decoration: InputDecoration(
                        hintText: s.typeYourQuestion,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.pillAll,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.pillAll,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: s.tapAndSpeak,
                    onPressed: _micTapped,
                    style: IconButton.styleFrom(backgroundColor: AppColors.dark, minimumSize: const Size(52, 52)),
                    icon: const Icon(Icons.mic_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: s.next,
                    onPressed: () => _ask(_input.text),
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(52, 52)),
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.mine, required this.label, this.footer});
  final String text;
  final bool mine;
  final String label;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: mine ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: t.labelSmall?.copyWith(color: mine ? Colors.white70 : AppColors.primary)),
              const SizedBox(height: 2),
              Text(text, style: t.bodyLarge?.copyWith(color: mine ? Colors.white : AppColors.textPrimary)),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}
