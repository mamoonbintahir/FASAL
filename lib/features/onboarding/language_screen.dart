import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/controls.dart';
import '../../providers/settings_provider.dart';
import 'fasal_logo.dart';

/// Welcome + language choice (first screen in the reference design).
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  late String _selected = ref.read(settingsProvider).languageCode ?? 'en';

  void _choose(String code) {
    setState(() => _selected = code);
    // Apply immediately so the farmer sees the app switch language.
    ref.read(settingsProvider.notifier).setLanguage(code);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          const FasalLogo(size: 92),
                          const SizedBox(height: 18),
                          Text(s.appName, style: t.displayMedium?.copyWith(color: AppColors.primary)),
                          const SizedBox(height: 6),
                          Text(
                            s.tagline,
                            textAlign: TextAlign.center,
                            style: t.bodyLarge?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 48),
                          Text(s.chooseLanguage, style: t.titleMedium),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceTile(
                                  key: const Key('lang_en'),
                                  label: s.english,
                                  subtitle: s.englishSub,
                                  selected: _selected == 'en',
                                  height: 88,
                                  labelStyle: t.titleLarge?.copyWith(
                                    fontFamily: AppTypography.latinFamily,
                                    height: 1.2,
                                  ),
                                  onTap: () => _choose('en'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChoiceTile(
                                  key: const Key('lang_ur'),
                                  label: s.urdu,
                                  subtitle: s.urduSub,
                                  selected: _selected == 'ur',
                                  height: 88,
                                  labelStyle: t.titleLarge?.copyWith(fontFamily: AppTypography.urduFamily, height: 1.6),
                                  onTap: () => _choose('ur'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  PrimaryButton(
                    key: const Key('lang_continue'),
                    label: s.continueLabel,
                    onPressed: () {
                      ref.read(settingsProvider.notifier).setLanguage(_selected);
                      context.go('/onboarding');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
