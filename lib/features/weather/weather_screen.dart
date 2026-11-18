import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fasal_core/catalog.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/network/app_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

import 'package:fasal_core/models.dart';

import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';
import '../../providers/farm_providers.dart';
import '../../widgets/listen_button.dart';
import '../../widgets/weather_widgets.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = context.lang;
    final weather = ref.watch(weatherProvider);
    final profile = ref.watch(profileProvider).value;
    final d = profile == null ? null : findDistrict(profile.district);
    final unreadAlerts = (ref.watch(alertsProvider).value ?? const []).where((a) => !a.isRead).length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: s.weather,
              subtitle: d == null ? profile?.district : '📍 ${d.name.of(lang)}',
              actions: [
                HeaderIconButton(
                  icon: Icons.warning_amber_rounded,
                  tooltip: s.weatherAlerts,
                  badge: unreadAlerts,
                  onPressed: () => context.pushIn<void>('alerts'),
                ),
              ],
            ),
            Expanded(
              child: weather.when(
                skipLoadingOnRefresh: true,
                loading: () => const PageBody(
                  children: [SkeletonCard(height: 230), SkeletonCard(height: 120), SkeletonCard(height: 300)],
                ),
                error: (e, _) => PageBody(
                  children: [
                    if (e is MissingLocationException)
                      EmptyState(
                        emoji: '📍',
                        title: s.missingLocationTitle,
                        body: s.missingLocationBody,
                        actionLabel: s.chooseDistrict,
                        onAction: () => context.pushIn<void>('profile'),
                      )
                    else
                      ErrorState(
                        emoji: '🌥️',
                        title: s.weatherUnavailable,
                        body: s.weatherUnavailableBody,
                        onRetry: () => ref.invalidate(weatherProvider),
                      ),
                  ],
                ),
                data: (w) => PageBody(
                  onRefresh: () async {
                    ref.invalidate(weatherProvider);
                    await ref.read(weatherProvider.future).catchError((Object _) => w);
                  },
                  children: [
                    _CurrentCard(report: w),
                    const Gap(16),
                    const _CropInsight(),
                    const Gap(16),
                    _ForecastList(days: w.daily),
                    const Gap(12),
                    InfoNote(s.sampleWeatherNote, emoji: '🧪'),
                    const Gap(6),
                    Center(
                      child: Text(s.updatedAt(s.time(w.updatedAt)), style: Theme.of(context).textTheme.labelSmall),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentCard extends StatelessWidget {
  const _CurrentCard({required this.report});
  final WeatherReport report;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final c = report.current;
    Widget stat(String emoji, String label, String value) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: AppRadius.mdAll),
        child: Column(
          children: [
            Text(
              '$emoji $label',
              style: t.labelSmall?.copyWith(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(value, style: t.titleSmall?.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );

    return FasalCard(
      color: AppColors.weatherCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.condition(c.condition),
                      style: t.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                    Text(
                      '${c.temperature}°',
                      style: t.displayLarge?.copyWith(color: Colors.white, fontFamily: 'Manrope'),
                    ),
                    Text(
                      '${c.minTemp}° / ${c.maxTemp}° · ${s.feelsLike(c.feelsLike)}',
                      style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              EmojiIcon(c.condition.emoji, size: 72),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              stat('💧', s.rain, '${c.rainChance}%'),
              const SizedBox(width: 8),
              stat('💨', s.wind, s.kmh(c.windKmh)),
              const SizedBox(width: 8),
              stat('🌫️', s.humidity, '${c.humidity}%'),
            ],
          ),
        ],
      ),
    );
  }
}

/// "What this means for your wheat" — agricultural interpretation of the forecast.
class _CropInsight extends ConsumerWidget {
  const _CropInsight();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;
    final views = ref.watch(cropViewsProvider).value ?? const [];
    final weather = ref.watch(weatherProvider).value;
    if (weather == null) return const SizedBox.shrink();
    final rain = weather.nextRain();
    final windy = weather.daily.take(5).where((d) => d.windKmh >= 20).firstOrNull;
    final crop = views.isEmpty ? null : views.first;

    final parts = <LocalizedText>[];
    if (rain != null) {
      final dayEn = const AppStrings(isUrdu: false).weekdayLong(rain.date.weekday);
      final dayUr = const AppStrings(isUrdu: true).weekdayLong(rain.date.weekday);
      parts.add(
        LocalizedText(
          'Heavy rain is expected $dayEn. Skip irrigation this week.',
          '$dayUr کو تیز بارش متوقع ہے۔ اس ہفتے پانی نہ دیں۔',
        ),
      );
      if (crop?.def.id == 'wheat') {
        parts.add(
          const LocalizedText('After the rain, check leaves for yellow rust.', 'بارش کے بعد پتوں پر پیلی کنگی دیکھیں۔'),
        );
      } else {
        parts.add(
          const LocalizedText(
            'After the rain, walk the field and check for disease.',
            'بارش کے بعد کھیت میں چل کر بیماری دیکھیں۔',
          ),
        );
      }
    } else {
      parts.add(
        const LocalizedText(
          'No heavy rain expected. Follow your irrigation schedule and check soil moisture.',
          'تیز بارش متوقع نہیں۔ آبپاشی کا شیڈول جاری رکھیں اور زمین کی نمی چیک کریں۔',
        ),
      );
    }
    if (windy != null) {
      parts.add(const LocalizedText('Avoid spraying on windy days.', 'تیز ہوا والے دن اسپرے نہ کریں۔'));
    }
    final text = LocalizedText.joinAll(parts);
    final title = crop == null ? s.whatThisMeansGeneric : s.whatThisMeans(crop.def.name.of(lang));

    return FasalCard(
      color: AppColors.primaryContainer,
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EmojiIcon(crop?.def.emoji ?? '🌱', size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: t.titleSmall?.copyWith(color: AppColors.primaryDark)),
              ),
              ListenButton(id: 'weather_insight', text: text),
            ],
          ),
          const Gap(8),
          Text(text.of(lang), style: t.bodyLarge),
        ],
      ),
    );
  }
}

class _ForecastList extends StatelessWidget {
  const _ForecastList({required this.days});
  final List<DailyForecast> days;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final today = AppDates.today();
    return FasalCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: SectionTitle(s.sevenDayForecast)),
          for (final d in days)
            Material(
              color: d.rainChance >= 60 ? AppColors.rainContainer : Colors.transparent,
              borderRadius: AppRadius.mdAll,
              child: InkWell(
                borderRadius: AppRadius.mdAll,
                onTap: () => showFasalSheet<void>(
                  context,
                  builder: (_) => SheetBody(
                    title: s.dayDetails,
                    children: [ForecastDayDetails(day: d)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(
                          AppDates.isSameDay(d.date, today) ? s.today : s.weekdayShort(d.date.weekday),
                          style: t.titleSmall,
                        ),
                      ),
                      EmojiIcon(d.condition.emoji, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.condition(d.condition),
                          style: t.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text(
                          '💧${d.rainChance}%',
                          style: t.labelMedium?.copyWith(color: AppColors.info),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 72,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '${d.maxTemp}° ', style: t.titleSmall),
                              TextSpan(text: '${d.minTemp}°', style: t.bodySmall),
                            ],
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
