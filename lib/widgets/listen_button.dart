import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

import 'package:fasal_core/models.dart';

import '../providers/tts_provider.dart';

/// Builds the same sentence in English and Urdu so voice can fall back to
/// English when no Urdu voice is installed.
LocalizedText speakable(String Function(AppStrings s, String lang) build) =>
    LocalizedText(build(const AppStrings(isUrdu: false), 'en'), build(const AppStrings(isUrdu: true), 'ur'));

/// "🔊 Listen" pill. While speaking it turns into Pause/Resume + Stop.
class ListenButton extends ConsumerWidget {
  const ListenButton({super.key, required this.id, required this.text, this.onDark = false});

  final String id;
  final LocalizedText text;
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final tts = ref.watch(ttsProvider);
    final ctrl = ref.read(ttsProvider.notifier);
    final active = tts.isActive(id);

    if (!active) {
      return _Pill(emoji: '🔊', label: s.listen, onDark: onDark, onTap: () => ctrl.speak(id, text));
    }
    final paused = tts.status == TtsStatus.paused;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Pill(
          emoji: paused ? '▶️' : '⏸️',
          label: paused ? s.resume : s.pause,
          onDark: onDark,
          highlighted: true,
          onTap: paused ? ctrl.resume : ctrl.pause,
        ),
        const SizedBox(width: 6),
        _Pill(emoji: '⏹️', label: s.stop, onDark: onDark, iconOnly: true, onTap: ctrl.stop),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.emoji,
    required this.label,
    required this.onTap,
    this.onDark = false,
    this.highlighted = false,
    this.iconOnly = false,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;
  final bool onDark;
  final bool highlighted;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final fg = highlighted ? Colors.white : AppColors.primary;
    final bg = highlighted ? AppColors.primary : Colors.white;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: AppRadius.pillAll,
        elevation: onDark ? 0 : 0.5,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: AppRadius.pillAll,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 44),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: iconOnly ? 10 : 14, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 15)),
                  if (!iconOnly) ...[
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
