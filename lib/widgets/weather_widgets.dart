import 'package:material_ui/material_ui.dart';

import '../core/l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/date_utils.dart';
import '../core/widgets/basics.dart';
import '../data/models/weather.dart';

/// Horizontal 7-day strip ("This week" on the dashboard). Rainy days are highlighted.
class ForecastStrip extends StatelessWidget {
  const ForecastStrip({super.key, required this.days, this.onDayTap});

  final List<DailyForecast> days;
  final ValueChanged<DailyForecast>? onDayTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        for (final d in days.take(7))
          Expanded(
            child: InkWell(
              borderRadius: AppRadius.mdAll,
              onTap: onDayTap == null ? null : () => onDayTap!(d),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: d.condition.isRainy && d.rainChance >= 60 ? AppColors.rainContainer : null,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Column(
                  children: [
                    Text(
                      s.weekdayShort(d.date.weekday),
                      style: t.labelSmall?.copyWith(
                        color: d.condition.isRainy && d.rainChance >= 60 ? AppColors.info : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                    const SizedBox(height: 4),
                    EmojiIcon(d.condition.emoji, size: 20, semanticLabel: s.condition(d.condition)),
                    const SizedBox(height: 4),
                    Text('${d.maxTemp}°', style: t.titleSmall),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Small rounded weather chip shown in the dashboard header.
class WeatherChip extends StatelessWidget {
  const WeatherChip({super.key, required this.emoji, required this.temp, this.onTap});

  final String emoji;
  final String temp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmojiIcon(emoji, size: 22),
              Text(temp, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sheet content with full details of one forecast day.
class ForecastDayDetails extends StatelessWidget {
  const ForecastDayDetails({super.key, required this.day});
  final DailyForecast day;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final rel = AppDates.daysBetween(DateTime.now(), day.date);
    Widget row(String emoji, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          EmojiIcon(emoji, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: t.bodyLarge)),
          Text(value, style: t.titleMedium),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            EmojiIcon(day.condition.emoji, size: 44),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${s.weekdayLong(day.date.weekday)} · ${s.shortDate(day.date)}', style: t.titleMedium),
                  Text('${s.condition(day.condition)} · ${s.relativeDay(rel)}', style: t.bodyMedium),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FasalCard(
          shadow: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              row('🌡️', s.lowHigh, '${day.minTemp}° / ${day.maxTemp}°'),
              row('💧', s.rainChance, '${day.rainChance}%'),
              row('💨', s.wind, s.kmh(day.windKmh)),
              row('🌫️', s.humidity, '${day.humidity}%'),
            ],
          ),
        ),
      ],
    );
  }
}
