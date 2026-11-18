import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';

import 'package:fasal_core/catalog.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';

import 'package:fasal_core/models.dart';

import '../../providers/core_providers.dart';
import '../../providers/farm_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/listen_button.dart';
import 'district_picker.dart';
import 'profile_screen.dart' show pickAreaUnit;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = context.lang;
    final t = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final profile = ref.watch(profileProvider).value;
    final district = profile == null ? null : findDistrict(profile.district);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: s.settings),
            Expanded(
              child: PageBody(
                children: [
                  // Language
                  FasalCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.language, style: t.titleMedium),
                        const Gap(12),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceTile(
                                key: const Key('settings_lang_en'),
                                label: s.english,
                                selected: !settings.isUrdu,
                                height: 56,
                                labelStyle: t.titleMedium?.copyWith(fontFamily: AppTypography.latinFamily, height: 1.2),
                                onTap: () => notifier.setLanguage('en'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ChoiceTile(
                                key: const Key('settings_lang_ur'),
                                label: s.urdu,
                                selected: settings.isUrdu,
                                height: 56,
                                labelStyle: t.titleMedium?.copyWith(fontFamily: AppTypography.urduFamily, height: 1.6),
                                onTap: () => notifier.setLanguage('ur'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  // Profile & location & units
                  _Group(
                    children: [
                      _Row(
                        emoji: '👤',
                        title: s.profile,
                        value: (profile?.name.isNotEmpty ?? false) ? profile!.name : s.tellUsAboutYou,
                        onTap: () => context.pushIn<void>('profile'),
                      ),
                      _Row(
                        emoji: '📍',
                        title: s.location,
                        value: district?.name.of(lang) ?? profile?.district ?? s.chooseDistrict,
                        onTap: () async {
                          final d = await pickDistrict(context);
                          if (d == null) return;
                          final p = ref.read(profileProvider).value;
                          if (p == null) {
                            if (context.mounted) context.pushIn<void>('profile');
                            return;
                          }
                          await ref
                              .read(profileProvider.notifier)
                              .save(p.copyWith(district: d.name.en, province: d.province.en));
                          ref.invalidate(alertsProvider);
                        },
                      ),
                      _Row(
                        emoji: '📐',
                        title: s.defaultAreaUnit,
                        value: s.areaUnitLabel(settings.areaUnit),
                        onTap: () async {
                          final u = await pickAreaUnit(context, settings.areaUnit);
                          if (u != null) notifier.setAreaUnit(u);
                        },
                      ),
                    ],
                  ),
                  const Gap(16),
                  // Notifications
                  _Group(
                    title: s.notificationPrefs,
                    children: [
                      for (final type in NotificationType.values)
                        SwitchListTile(
                          value: settings.notificationEnabled(type),
                          onChanged: (v) => notifier.setNotification(type, v),
                          secondary: EmojiIcon(type.emoji, size: 20),
                          title: Text(s.notificationType(type), style: t.titleSmall),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                    ],
                  ),
                  const Gap(16),
                  // Voice
                  _Group(
                    title: s.voice,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.speechSpeed, style: t.titleSmall),
                            Slider(
                              value: settings.speechRate.clamp(0.2, 0.8).toDouble(),
                              min: 0.2,
                              max: 0.8,
                              divisions: 6,
                              label: settings.speechRate < 0.4
                                  ? s.slow
                                  : settings.speechRate > 0.55
                                  ? s.fast
                                  : s.normal,
                              onChanged: notifier.setSpeechRate,
                            ),
                            Row(
                              children: [
                                Text(s.slow, style: t.labelSmall),
                                const Spacer(),
                                Text(s.fast, style: t.labelSmall),
                              ],
                            ),
                            const Gap(10),
                            Row(
                              children: [
                                Expanded(child: Text(s.speechVoiceLanguage, style: t.bodySmall)),
                                ListenButton(id: 'voice_test', text: speakable((s, _) => s.voiceSample)),
                              ],
                            ),
                            const Gap(12),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  // App info
                  _Group(
                    children: [
                      _Row(
                        emoji: 'ℹ️',
                        title: s.about,
                        value: Env.appVersion,
                        onTap: () => _info(context, s.about, [s.aboutBody, '${s.version}: ${Env.appVersion}']),
                      ),
                      _Row(emoji: '🔒', title: s.privacy, onTap: () => _info(context, s.privacy, [s.privacyBody])),
                      _Row(
                        emoji: '❓',
                        title: s.help,
                        onTap: () => _info(context, s.help, [
                          '${s.helpQ1}\n${s.helpA1}',
                          '${s.helpQ2}\n${s.helpA2}',
                          '${s.helpQ3}\n${s.helpA3}',
                          s.contactSupport,
                        ]),
                      ),
                    ],
                  ),
                  const Gap(16),
                  // Account (when connected to the FASAL server)
                  if (!Env.useMockData)
                    _Group(
                      title: s.account,
                      children: [
                        _Row(
                          emoji: '🚪',
                          title: s.signOut,
                          onTap: () async {
                            final ok = await showConfirmDialog(
                              context,
                              title: s.signOut,
                              body: s.signOutBody,
                              confirmLabel: s.signOut,
                            );
                            if (!ok) return;
                            await ref.read(authRepositoryProvider).signOut();
                            await clearLocalSession(ref);
                            if (context.mounted) context.go('/login');
                          },
                        ),
                        _Row(
                          emoji: '🗑️',
                          title: s.deleteAccount,
                          danger: true,
                          onTap: () async {
                            final ok = await showConfirmDialog(
                              context,
                              title: s.deleteAccount,
                              body: s.deleteAccountBody,
                              confirmLabel: s.delete,
                              destructive: true,
                            );
                            if (!ok) return;
                            try {
                              await ref.read(authRepositoryProvider).deleteAccount();
                            } catch (e) {
                              if (context.mounted) showSnack(context, s.genericErrorTitle);
                              return;
                            }
                            await clearLocalSession(ref);
                            if (context.mounted) context.go('/login');
                          },
                        ),
                      ],
                    ),
                  // Demo options (offline mode only)
                  if (Env.useMockData)
                    _Group(
                      title: s.demoOptions,
                      children: [
                        _Row(
                          emoji: '🌾',
                          title: s.loadSampleFarm,
                          onTap: () async {
                            await loadSampleFarm(ref);
                            if (context.mounted) showSnack(context, s.sampleFarmLoaded);
                          },
                        ),
                        SwitchListTile(
                          value: settings.simulateWeatherError,
                          onChanged: notifier.setSimulateWeatherError,
                          secondary: const EmojiIcon('📡', size: 20),
                          title: Text(s.simulateWeatherError, style: t.titleSmall),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        _Row(
                          emoji: '🔄',
                          title: s.restartDemo,
                          danger: true,
                          onTap: () async {
                            final ok = await showConfirmDialog(
                              context,
                              title: s.restartDemo,
                              body: s.restartDemoBody,
                              confirmLabel: s.restartDemo,
                              destructive: true,
                            );
                            if (!ok) return;
                            await restartDemo(ref);
                            if (context.mounted) context.go('/splash');
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _info(BuildContext context, String title, List<String> paragraphs) {
    showFasalSheet<void>(
      context,
      builder: (ctx) => SheetBody(
        title: title,
        footer: PrimaryButton(label: context.s.close, onPressed: () => Navigator.of(ctx).pop()),
        children: [
          for (final p in paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(p, style: Theme.of(ctx).textTheme.bodyLarge),
            ),
        ],
      ),
    );
  }
}

/// After sign-out: forget this device's setup flag and cached account data.
Future<void> clearLocalSession(WidgetRef ref) async {
  final store = ref.read(localStoreProvider);
  final settings = ref.read(settingsProvider);
  await store.writeJson('settings', settings.copyWith(setupDone: false).toJson());
  ref
    ..invalidate(settingsProvider)
    ..invalidate(profileProvider)
    ..invalidate(cropsProvider)
    ..invalidate(tasksProvider)
    ..invalidate(activitiesProvider)
    ..invalidate(expensesProvider)
    ..invalidate(notificationsProvider)
    ..invalidate(alertsProvider)
    ..invalidate(weatherProvider);
}

/// Clears all local data and resets every provider ("Restart demo").
Future<void> restartDemo(WidgetRef ref) async {
  await ref.read(localStoreProvider).clearAll();
  ref.invalidate(settingsProvider);
  ref.invalidate(profileProvider);
  ref.invalidate(cropsProvider);
  ref.invalidate(tasksProvider);
  ref.invalidate(activitiesProvider);
  ref.invalidate(expensesProvider);
  ref.invalidate(notificationsProvider);
  ref.invalidate(alertsProvider);
  ref.invalidate(weatherProvider);
}

class _Group extends StatelessWidget {
  const _Group({required this.children, this.title});
  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 6, bottom: 8),
            child: Text(title!, style: Theme.of(context).textTheme.titleMedium),
          ),
        FasalCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.emoji, required this.title, required this.onTap, this.value, this.danger = false});
  final String emoji;
  final String title;
  final String? value;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouch + 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              EmojiIcon(emoji, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.titleSmall?.copyWith(color: danger ? AppColors.error : AppColors.textPrimary)),
                    if (value != null) Text(value!, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
