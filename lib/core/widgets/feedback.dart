import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'basics.dart';
import 'controls.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String emoji;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 16 : 40, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmojiIcon(emoji, size: compact ? 34 : 48, background: AppColors.primaryContainer, boxSize: compact ? 68 : 96),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: t.titleMedium, textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(body!, style: t.bodyMedium, textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: actionLabel!, onPressed: onAction, expand: false),
          ],
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.title, this.body, this.onRetry, this.emoji = '⚠️'});

  final String? title;
  final String? body;
  final VoidCallback? onRetry;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmojiIcon(emoji, size: 40, background: AppColors.warningContainer, boxSize: 84),
          const SizedBox(height: AppSpacing.md),
          Text(title ?? s.genericErrorTitle, style: t.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(body ?? s.genericErrorBody, style: t.bodyMedium, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 220,
              child: SecondaryButton(label: s.retry, onPressed: onRetry, emoji: '🔄'),
            ),
          ],
        ],
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.height = 160});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Center(child: CircularProgressIndicator(semanticsLabel: context.s.loading)),
  );
}

/// Placeholder card shown while content loads.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 120});
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    decoration: BoxDecoration(color: AppColors.surfaceMuted.withValues(alpha: 0.7), borderRadius: AppRadius.lgAll),
  );
}

/// Standard loading / error / data switch for [AsyncValue].
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.data, this.onRetry, this.loading, this.error});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;
  final Widget Function(Object error)? error;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: data,
      loading: () => loading ?? const LoadingView(),
      error: (e, _) => error?.call(e) ?? ErrorState(onRetry: onRetry),
    );
  }
}

// ───────────────────────── Dialogs, sheets, snackbars ─────────────────────────

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final s = context.s;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      title: Text(title, style: Theme.of(ctx).textTheme.titleLarge),
      content: Text(body, style: Theme.of(ctx).textTheme.bodyLarge),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          style: TextButton.styleFrom(minimumSize: const Size(88, 48), foregroundColor: AppColors.textSecondary),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            minimumSize: const Size(100, 48),
            backgroundColor: destructive ? AppColors.error : AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<T?> showFasalSheet<T>(BuildContext context, {required Widget Function(BuildContext) builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.9),
        child: builder(ctx),
      ),
    ),
  );
}

void showSnack(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      action: actionLabel == null
          ? null
          : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}, textColor: AppColors.accent),
    ),
  );
}

/// Simple titled sheet body with padding and scroll.
class SheetBody extends StatelessWidget {
  const SheetBody({super.key, required this.title, required this.children, this.footer});

  final String title;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
        if (footer != null) Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 20), child: footer),
      ],
    );
  }
}
