import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/l10n/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/tts_provider.dart';

final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

class FasalApp extends ConsumerWidget {
  const FasalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsProvider.select((s) => s.locale));
    final router = ref.watch(routerProvider);
    final urdu = locale.languageCode == 'ur';

    // Show voice notices (e.g. Urdu voice not installed) as snackbars.
    ref.listen<TtsState>(ttsProvider, (prev, next) {
      if (next.noticeSeq == prev?.noticeSeq || next.notice == TtsNotice.none) return;
      final s = AppStrings(isUrdu: urdu);
      rootMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(next.notice == TtsNotice.urduMissing ? s.urduVoiceMissing : s.ttsUnavailable)),
        );
    });

    return MaterialApp.router(
      title: 'Fasal',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      routerConfig: router,
      locale: locale,
      supportedLocales: kSupportedLocales,
      // App strings + Material/Cupertino/Widgets localizations (incl. RTL for Urdu).
      localizationsDelegates: const [AppLocalizationsDelegate(), ...GlobalMaterialLocalizations.delegates],
      theme: AppTheme.light(urdu: urdu),
      builder: (context, child) {
        // Respect the phone's text size, but cap it so layouts don't break.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
