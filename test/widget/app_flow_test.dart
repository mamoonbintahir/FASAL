import 'package:fasal/core/widgets/basics.dart';
import 'package:fasal/features/home/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

void main() {
  testWidgets('first run: language → onboarding → profile → add crop → dashboard', (tester) async {
    await pumpFasal(tester);

    // Language screen
    expect(find.text('Choose your language'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('lang_continue')));

    // Onboarding (skippable)
    expect(find.text('Know what to do, and when'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('onb_skip')));

    // Profile setup — district via picker, area typed
    expect(find.text('Tell us about you'), findsOneWidget);
    await tapVisible(tester, find.text('Choose your district'));
    await tapVisible(tester, find.text('Sahiwal'));
    await tester.enterText(
      find.descendant(of: find.byKey(const Key('profile_area')), matching: find.byType(EditableText)),
      '5',
    );
    await tapVisible(tester, find.byKey(const Key('profile_continue')));

    // Add crop
    expect(find.text('Add your crop'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('crop_wheat')));
    await tapVisible(tester, find.text('Select date'));
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tapVisible(tester, find.byKey(const Key('crop_save')));

    // Dashboard shows the new crop
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Germination'), findsWidgets);
    expect(find.textContaining('Wheat · Day 0'), findsOneWidget);
  });

  testWidgets('profile form shows validation errors', (tester) async {
    await pumpFasal(tester, prefs: {'fasal.settings': '{"languageCode":"en","onboardingDone":true,"setupDone":false}'});
    expect(find.text('Tell us about you'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('profile_continue')));
    expect(find.text('Please choose your district'), findsOneWidget);
    expect(find.text('Please enter farm area'), findsOneWidget);
  });

  testWidgets('completing a task updates the dashboard and records', (tester) async {
    await pumpFasal(tester, prefs: seededPrefs());
    expect(find.text('Tillering'), findsWidgets);
    expect(find.text('Check irrigation'), findsOneWidget);

    await tapVisible(tester, find.byType(CheckCircle).first);
    expect(find.text('Task done — added to your records'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_3')));
    await settle(tester);
    expect(find.text('Records'), findsWidgets);
    expect(find.textContaining('Check irrigation'), findsWidgets);
  });

  testWidgets('Urdu switches the app to right-to-left', (tester) async {
    await pumpFasal(tester, prefs: seededPrefs(language: 'ur'));
    final ctx = tester.element(find.byType(HomeScreen));
    expect(Directionality.of(ctx), TextDirection.rtl);
    expect(find.text('آج کے کام'), findsWidgets);
  });

  testWidgets('removing a crop asks for confirmation', (tester) async {
    await pumpFasal(tester, prefs: seededPrefs());
    await tester.tap(find.byKey(const Key('nav_1')));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await settle(tester);
    await tester.tap(find.textContaining('Remove crop'));
    await settle(tester);
    expect(find.textContaining('Its calendar and tasks will be deleted'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await settle(tester);
    expect(find.text('No crops yet'), findsWidgets);
  });

  testWidgets('weather unavailable shows a retry option', (tester) async {
    await pumpFasal(tester, prefs: seededPrefs(simulateWeatherError: true));
    await tester.tap(find.byKey(const Key('nav_2')));
    await settle(tester);
    expect(find.text('Weather is not available'), findsWidgets);
    expect(find.text('Try again'), findsWidgets);
  });

  testWidgets('add expense validates and updates the season total', (tester) async {
    await pumpFasal(tester, prefs: seededPrefs());
    await tester.tap(find.byKey(const Key('nav_3')));
    await settle(tester);
    await tapVisible(tester, find.text('Expenses'));
    await tapVisible(tester, find.byKey(const Key('add_expense')));
    await tapVisible(tester, find.byKey(const Key('save_expense')));
    expect(find.text('Please choose a type'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('exp_seeds')));
    await tester.enterText(
      find.descendant(of: find.byKey(const Key('expense_amount')), matching: find.byType(EditableText)),
      '9000',
    );
    await tapVisible(tester, find.byKey(const Key('save_expense')));
    expect(find.text('Rs 9,000'), findsWidgets);
  });

  testWidgets('listen button speaks the card text', (tester) async {
    final tts = await pumpFasal(tester, prefs: seededPrefs());
    await tapVisible(tester, find.text('Listen').first);
    expect(tts.spoken, isNotEmpty);
    expect(find.text('Pause'), findsOneWidget);
  });
}
