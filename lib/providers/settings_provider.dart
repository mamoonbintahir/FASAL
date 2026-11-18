import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fasal_core/models.dart';

import 'core_providers.dart';

/// App-level preferences (non-sensitive), persisted locally.
@immutable
class AppSettings {
  const AppSettings({
    this.languageCode,
    this.onboardingDone = false,
    this.setupDone = false,
    this.speechRate = 0.45,
    this.areaUnit = AreaUnit.acre,
    this.notificationPrefs = const {},
    this.simulateWeatherError = false,
  });

  /// Null until the farmer chooses a language on first launch.
  final String? languageCode;
  final bool onboardingDone;
  final bool setupDone;

  /// flutter_tts rate: 0.0–1.0 (0.5 ≈ normal on Android).
  final double speechRate;
  final AreaUnit areaUnit;
  final Map<NotificationType, bool> notificationPrefs;
  final bool simulateWeatherError;

  Locale get locale => Locale(languageCode ?? 'en');
  bool get isUrdu => languageCode == 'ur';

  bool notificationEnabled(NotificationType t) => notificationPrefs[t] ?? true;

  AppSettings copyWith({
    String? languageCode,
    bool? onboardingDone,
    bool? setupDone,
    double? speechRate,
    AreaUnit? areaUnit,
    Map<NotificationType, bool>? notificationPrefs,
    bool? simulateWeatherError,
  }) => AppSettings(
    languageCode: languageCode ?? this.languageCode,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    setupDone: setupDone ?? this.setupDone,
    speechRate: speechRate ?? this.speechRate,
    areaUnit: areaUnit ?? this.areaUnit,
    notificationPrefs: notificationPrefs ?? this.notificationPrefs,
    simulateWeatherError: simulateWeatherError ?? this.simulateWeatherError,
  );

  Map<String, dynamic> toJson() => {
    'languageCode': languageCode,
    'onboardingDone': onboardingDone,
    'setupDone': setupDone,
    'speechRate': speechRate,
    'areaUnit': areaUnit.name,
    'notificationPrefs': {for (final e in notificationPrefs.entries) e.key.name: e.value},
    'simulateWeatherError': simulateWeatherError,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    final prefs = <NotificationType, bool>{};
    final raw = j['notificationPrefs'];
    if (raw is Map) {
      for (final e in raw.entries) {
        final t = NotificationType.values.asNameMap()[e.key];
        if (t != null && e.value is bool) prefs[t] = e.value as bool;
      }
    }
    return AppSettings(
      languageCode: j['languageCode'] as String?,
      onboardingDone: j['onboardingDone'] as bool? ?? false,
      setupDone: j['setupDone'] as bool? ?? false,
      speechRate: (j['speechRate'] as num?)?.toDouble() ?? 0.45,
      areaUnit: AreaUnit.values.asNameMap()[j['areaUnit']] ?? AreaUnit.acre,
      notificationPrefs: prefs,
      simulateWeatherError: j['simulateWeatherError'] as bool? ?? false,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _key = 'settings';

  @override
  AppSettings build() {
    final json = ref.watch(localStoreProvider).readMap(_key);
    return json == null ? const AppSettings() : AppSettings.fromJson(json);
  }

  void _set(AppSettings s) {
    state = s;
    ref.read(localStoreProvider).writeJson(_key, s.toJson());
  }

  void setLanguage(String code) => _set(state.copyWith(languageCode: code));
  void completeOnboarding() => _set(state.copyWith(onboardingDone: true));
  void completeSetup() => _set(state.copyWith(setupDone: true));
  void setSpeechRate(double r) => _set(state.copyWith(speechRate: r));
  void setAreaUnit(AreaUnit u) => _set(state.copyWith(areaUnit: u));
  void setSimulateWeatherError(bool v) => _set(state.copyWith(simulateWeatherError: v));

  void setNotification(NotificationType t, bool enabled) =>
      _set(state.copyWith(notificationPrefs: {...state.notificationPrefs, t: enabled}));
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
