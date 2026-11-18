import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers.dart';

/// Visits every screen on a small phone in both languages. Any layout
/// overflow or exception fails the test automatically.
void main() {
  for (final lang in ['en', 'ur']) {
    for (final size in const [Size(320, 640), Size(412, 915)]) {
      testWidgets('all screens render ($lang, ${size.width.toInt()}x${size.height.toInt()})', (tester) async {
        await pumpFasal(
          tester,
          prefs: seededPrefs(language: lang),
          size: size,
        );

        // Bottom tabs
        for (final tab in [1, 2, 3, 4, 0]) {
          await tester.tap(find.byKey(Key('nav_$tab')));
          await settle(tester);
        }

        // Detail screens within the Home tab
        final router = GoRouter.of(tester.element(find.byKey(const Key('nav_0'))));
        for (final path in [
          'crop/c1',
          'calendar/c1',
          'history/c1',
          'care?tab=0&crop=c1',
          'care?tab=1&crop=c1',
          'care?tab=2&crop=c1',
          'irrigation?crop=c1',
          'tasks',
          'alerts',
          'notifications',
          'ask',
          'advice',
          'profile',
          'add-crop',
          'edit-crop/c1',
        ]) {
          router.push<void>('/home/$path');
          await settle(tester);
          expect(tester.takeException(), isNull, reason: path);
          router.pop();
          await settle(tester);
        }
      });
    }
  }
}
