import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import 'fasal_logo.dart';

/// Branded splash; decides where to go based on first-run progress.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), _next);
  }

  Future<void> _next() async {
    if (!mounted) return;
    final s = ref.read(settingsProvider);
    final auth = ref.read(authRepositoryProvider);
    final signedIn = !auth.requiresSignIn || await auth.isSignedIn();
    if (!mounted) return;
    if (s.languageCode == null) {
      context.go('/language');
    } else if (!s.onboardingDone) {
      context.go('/onboarding');
    } else if (!signedIn) {
      context.go('/login');
    } else if (!s.setupDone) {
      context.go('/setup');
    } else {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FasalLogo(size: 104, inverted: true),
              const SizedBox(height: 20),
              Text(s.appName, style: t.displayMedium?.copyWith(color: Colors.white)),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  s.tagline,
                  textAlign: TextAlign.center,
                  style: t.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
