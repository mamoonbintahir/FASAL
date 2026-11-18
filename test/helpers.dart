import 'dart:convert';

import 'package:fasal/app.dart';
import 'package:fasal/data/models/crop.dart';
import 'package:fasal/data/models/user_profile.dart';
import 'package:fasal/providers/core_providers.dart';
import 'package:fasal/providers/settings_provider.dart';
import 'package:fasal/providers/tts_provider.dart';
import 'package:fasal/services/tts_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Silent TTS engine for tests (no platform channel).
class FakeTts implements TtsEngine {
  final List<String> spoken = [];
  bool urduAvailable = true;

  @override
  Future<bool> isLanguageAvailable(String locale) async => locale != 'ur-PK' || urduAvailable;
  @override
  Future<void> configure({required String locale, required double rate}) async {}
  @override
  Future<void> speak(String text) async => spoken.add(text);
  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {}
  @override
  set onDone(VoidCallback? cb) {}
  @override
  set onError(ValueChanged<String>? cb) {}
}

/// Pre-filled local data so a test can start on the dashboard.
Map<String, Object> seededPrefs({
  String language = 'en',
  bool withCrop = true,
  int cropDay = 38,
  bool simulateWeatherError = false,
}) {
  final now = DateTime.now();
  final sown = DateTime(now.year, now.month, now.day).subtract(Duration(days: cropDay));
  return {
    'fasal.settings': jsonEncode(
      AppSettings(
        languageCode: language,
        onboardingDone: true,
        setupDone: true,
        simulateWeatherError: simulateWeatherError,
      ).toJson(),
    ),
    'fasal.profile': jsonEncode(
      const UserProfile(name: 'Ahmed', district: 'Sahiwal', province: 'Punjab', farmArea: 5).toJson(),
    ),
    if (withCrop)
      'fasal.crops': jsonEncode([
        Crop(id: 'c1', cropTypeId: 'wheat', sowingDate: sown, area: 5, seedKg: 50, createdAt: sown).toJson(),
      ]),
  };
}

/// Pumps the full app with test overrides. Uses a typical Android phone size.
Future<FakeTts> pumpFasal(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  Size size = const Size(392, 850),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final tts = FakeTts();
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [sharedPreferencesProvider.overrideWithValue(sp), ttsEngineProvider.overrideWithValue(tts)],
      child: const FasalApp(),
    ),
  );
  // Splash waits 1.4 s; mock repositories add ~350 ms latency.
  await settle(tester);
  return tts;
}

/// Advances fake time past splash/mock delays and lets animations finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
  await tester.pumpAndSettle();
}

/// Taps a widget after scrolling it into view.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await settle(tester);
}
