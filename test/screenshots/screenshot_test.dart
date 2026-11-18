// Renders key screens to PNGs for visual review (not a regression test).
// Runs only when FASAL_SCREENSHOTS is set (see .github/workflows/flutter-ci.yml):
//   FASAL_SCREENSHOTS=1 EMOJI_FONT=/path/NotoColorEmoji.ttf flutter test --update-goldens test/screenshots
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers.dart';

final bool _enabled = Platform.environment.containsKey('FASAL_SCREENSHOTS');

Future<void> _loadFonts() async {
  Future<void> load(String family, List<Future<ByteData>> data) async {
    final loader = FontLoader(family);
    for (final d in data) {
      loader.addFont(d);
    }
    await loader.load();
  }

  await load('Manrope', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      rootBundle.load('assets/fonts/Manrope-$w.ttf'),
  ]);
  await load('NotoNastaliqUrdu', [
    rootBundle.load('assets/fonts/NotoNastaliqUrdu-Regular.ttf'),
    rootBundle.load('assets/fonts/NotoNastaliqUrdu-Bold.ttf'),
  ]);
  final emoji = Platform.environment['EMOJI_FONT'];
  if (emoji != null && File(emoji).existsSync()) {
    await load('NotoColorEmoji', [File(emoji).readAsBytes().then((b) => ByteData.sublistView(b))]);
  }
  try {
    await load('MaterialIcons', [rootBundle.load('fonts/MaterialIcons-Regular.otf')]);
  } catch (_) {}
}

void main() {
  const shots = <(String, String, String?)>[
    // (file, language, route pushed inside Home tab or null for a tab key)
    ('01_home', 'en', null),
    ('02_crop_details', 'en', 'crop/c1'),
    ('03_calendar', 'en', 'calendar/c1'),
    ('04_care_fertilizer', 'en', 'care?tab=0&crop=c1'),
    ('05_care_pests', 'en', 'care?tab=1&crop=c1'),
    ('06_irrigation', 'en', 'irrigation?crop=c1'),
    ('07_tasks', 'en', 'tasks'),
    ('08_ask', 'en', 'ask'),
    ('09_alerts', 'en', 'alerts'),
    ('10_advice', 'en', 'advice'),
    ('11_add_crop', 'en', 'add-crop'),
    ('12_weather', 'en', 'tab:2'),
    ('13_records', 'en', 'tab:3'),
    ('14_my_crops', 'en', 'tab:1'),
    ('15_settings', 'en', 'tab:4'),
    ('16_home_ur', 'ur', null),
    ('17_crop_details_ur', 'ur', 'crop/c1'),
    ('18_settings_ur', 'ur', 'tab:4'),
    ('19_weather_ur', 'ur', 'tab:2'),
  ];

  for (final (file, lang, route) in shots) {
    testWidgets('screenshot $file', skip: !_enabled, (tester) async {
      await tester.runAsync(_loadFonts);
      await pumpFasal(tester, prefs: seededPrefs(language: lang));
      if (route != null && route.startsWith('tab:')) {
        await tester.tap(find.byKey(Key('nav_${route.substring(4)}')));
        await settle(tester);
      } else if (route != null) {
        GoRouter.of(tester.element(find.byKey(const Key('nav_0')))).push<void>('/home/$route');
        await settle(tester);
      }
      await expectLater(find.byKey(const Key('screen')), matchesGoldenFile('goldens/$file.png'));
    });
  }

  for (final (file, step) in const [('20_language', 0), ('21_onboarding', 1), ('22_profile_setup', 2)]) {
    testWidgets('screenshot $file', skip: !_enabled, (tester) async {
      await tester.runAsync(_loadFonts);
      await pumpFasal(tester);
      if (step >= 1) await tapVisible(tester, find.byKey(const Key('lang_continue')));
      if (step >= 2) await tapVisible(tester, find.byKey(const Key('onb_skip')));
      await expectLater(find.byKey(const Key('screen')), matchesGoldenFile('goldens/$file.png'));
    });
  }
}
