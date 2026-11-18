import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';
import '../../data/models/app_notification.dart';
import '../../providers/core_providers.dart';
import '../../providers/farm_providers.dart';

/// Notification centre: reminders, stage updates, weather alerts.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final async = ref.watch(notificationsProvider);
    final today = AppDates.dateOnly(ref.watch(clockProvider)());
    final hasUnread = (async.value ?? const []).any((n) => !n.isRead);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: s.notifications,
              showBack: true,
              backTooltip: s.back,
              actions: [
                if (hasUnread)
                  HeaderIconButton(
                    icon: Icons.done_all_rounded,
                    tooltip: s.markAllRead,
                    onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
                  ),
              ],
            ),
            Expanded(
              child: AsyncView(
                value: async,
                onRetry: () => ref.invalidate(notificationsProvider),
                data: (list) {
                  if (list.isEmpty) {
                    return PageBody(
                      children: [EmptyState(emoji: '🔔', title: s.noNotifications, body: s.noNotificationsBody)],
                    );
                  }
                  final todays = list.where((n) => !n.createdAt.isBefore(today)).toList();
                  final earlier = list.where((n) => n.createdAt.isBefore(today)).toList();
                  return PageBody(
                    onRefresh: () async {
                      ref.invalidate(notificationsProvider);
                      await ref.read(notificationsProvider.future);
                    },
                    children: [
                      if (todays.isNotEmpty) ...[
                        Text(s.today, style: t.titleMedium),
                        const Gap(8),
                        for (final n in todays) _NotificationTile(n: n),
                        const Gap(12),
                      ],
                      if (earlier.isNotEmpty) ...[
                        Text(s.earlier, style: t.titleMedium),
                        const Gap(8),
                        for (final n in earlier) _NotificationTile(n: n),
                      ],
                      const Gap(12),
                      InfoNote(s.notificationsDemoNote, emoji: '🧪'),
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

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.n});
  final AppNotification n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;
    final now = ref.watch(clockProvider)();
    final days = AppDates.daysBetween(n.createdAt, now);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(n.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: AlignmentDirectional.centerEnd,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: AppRadius.lgAll),
          child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
        ),
        onDismissed: (_) {
          final notifier = ref.read(notificationsProvider.notifier);
          notifier.delete(n);
          showSnack(context, s.notificationDeleted, actionLabel: s.undo, onAction: () => notifier.restore(n));
        },
        child: FasalCard(
          color: n.isRead ? Colors.white : AppColors.primaryContainer.withValues(alpha: 0.6),
          padding: const EdgeInsets.all(14),
          onTap: () {
            ref.read(notificationsProvider.notifier).markRead(n.id);
            final target = n.target;
            if (target == 'crops') {
              context.go('/crops');
            } else if (target != null) {
              context.pushIn<void>(target);
            }
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmojiIcon(n.type.emoji, size: 20, background: Colors.white, boxSize: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title.of(lang),
                            style: t.titleSmall?.copyWith(fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(n.body.of(lang), style: t.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      '${s.notificationType(n.type)} · ${days <= 0 ? s.time(n.createdAt) : s.daysAgo(days)}',
                      style: t.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
