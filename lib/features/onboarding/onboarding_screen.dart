import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';

/// Four short, skippable intro pages.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  void _finish() {
    ref.read(settingsProvider.notifier).completeOnboarding();
    context.go(ref.read(authRepositoryProvider).requiresSignIn ? '/login' : '/setup');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final pages = [
      ('🌾', AppColors.primaryContainer, s.onb1Title, s.onb1Body),
      ('📅', AppColors.tintYellow, s.onb2Title, s.onb2Body),
      ('🌧️', AppColors.tintBlue, s.onb3Title, s.onb3Body),
      ('💧', AppColors.tintPurple, s.onb4Title, s.onb4Body),
    ];
    final last = _page == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextButton(
                      key: const Key('onb_skip'),
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(64, 48),
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: Text(s.skip, style: t.titleSmall?.copyWith(color: AppColors.textSecondary)),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) {
                      final p = pages[i];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            EmojiIcon(p.$1, size: 96, background: p.$2, boxSize: 200),
                            const SizedBox(height: 36),
                            Text(p.$3, textAlign: TextAlign.center, style: t.headlineMedium),
                            const SizedBox(height: 12),
                            Text(
                              p.$4,
                              textAlign: TextAlign.center,
                              style: t.bodyLarge?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page ? AppColors.primary : AppColors.border,
                          borderRadius: AppRadius.pillAll,
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: PrimaryButton(
                    key: const Key('onb_next'),
                    label: last ? s.getStarted : s.next,
                    onPressed: last
                        ? _finish
                        : () =>
                              _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
