import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

import 'package:fasal_core/models.dart';

import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';
import '../../providers/core_providers.dart';
import '../../providers/farm_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/listen_button.dart';

/// (foreground, background, border) colours for an alert severity.
(Color, Color, Color) severityColors(AlertSeverity s) => switch (s) {
  AlertSeverity.info => (AppColors.info, AppColors.infoContainer, AppColors.info.withValues(alpha: 0.35)),
  AlertSeverity.warning => (AppColors.warning, AppColors.warningContainer, AppColors.warningBorder),
  AlertSeverity.severe => (AppColors.error, AppColors.errorContainer, AppColors.error),
};

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final alerts = ref.watch(alertsProvider);
    final now = ref.watch(clockProvider)();
    final hasUnread = (alerts.value ?? const []).any((a) => !a.isRead);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: s.weatherAlerts,
              showBack: true,
              backTooltip: s.back,
              actions: [
                if (hasUnread)
                  HeaderIconButton(
                    icon: Icons.done_all_rounded,
                    tooltip: s.markAllRead,
                    onPressed: () => ref.read(alertsProvider.notifier).markAllRead(),
                  ),
              ],
            ),
            Padding(
              padding: AppSpacing.page,
              child: SegmentedTabs(
                labels: [s.active, s.past],
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: AsyncView(
                value: alerts,
                onRetry: () => ref.invalidate(alertsProvider),
                data: (list) {
                  final shown = list.where((a) => _tab == 0 ? a.isActive(now) : !a.isActive(now)).toList()
                    ..sort((a, b) => _tab == 0 ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
                  if (shown.isEmpty) {
                    return PageBody(
                      children: [EmptyState(emoji: '🌤️', title: s.noAlerts, body: s.noAlertsBody)],
                    );
                  }
                  return PageBody(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      for (final a in shown) ...[AlertCard(alert: a), const Gap(12)],
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

class AlertCard extends ConsumerWidget {
  const AlertCard({super.key, required this.alert});
  final WeatherAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;
    final (fg, bg, border) = severityColors(alert.severity);
    final catalog = ref.watch(cropCatalogProvider);
    final cropNames = [
      for (final id in alert.affectedCropTypeIds)
        if (catalog.byId(id) case final d?) '${d.emoji} ${d.name.of(lang)}',
    ];
    final today = ref.watch(clockProvider)();
    final rel = AppDates.daysBetween(today, alert.date);

    return FasalCard(
      color: alert.isRead ? Colors.white : bg,
      borderColor: alert.isRead ? null : border,
      onTap: alert.isRead ? null : () => ref.read(alertsProvider.notifier).markRead(alert.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EmojiIcon(alert.type.emoji, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.title.of(lang), style: t.titleMedium),
                    Text(
                      '${s.weekdayLong(alert.date.weekday)}, ${s.shortDate(alert.date)} · ${s.relativeDay(rel)}',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!alert.isRead) StatusBadge(s.newLabel, color: AppColors.error),
            ],
          ),
          const Gap(10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusBadge(s.severity(alert.severity), color: fg, filled: false),
              if (cropNames.isNotEmpty)
                StatusBadge(
                  '${s.affectedCrops}: ${cropNames.join(', ')}',
                  color: AppColors.textSecondary,
                  filled: false,
                ),
            ],
          ),
          const Gap(10),
          Text(alert.message.of(lang), style: t.bodyLarge),
          const Gap(10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: AppRadius.mdAll),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ ${s.recommendedAction}', style: t.titleSmall),
                const SizedBox(height: 2),
                Text(alert.action.of(lang), style: t.bodyMedium?.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Gap(10),
          ListenButton(
            id: 'alertcard_${alert.id}',
            text: LocalizedText.joinAll([alert.title, alert.message, alert.action]),
          ),
        ],
      ),
    );
  }
}
