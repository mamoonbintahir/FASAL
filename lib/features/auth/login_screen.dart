import 'dart:async';

import 'package:fasal_core/models.dart' show normalizePkPhone;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/network/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';
import '../../providers/farm_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import '../onboarding/fasal_logo.dart';

/// User-facing text for an error from the API.
String errorText(AppStrings s, Object e) => switch (e) {
  NetworkException() => s.networkError,
  AppException(:final message) => message,
  _ => s.genericErrorTitle,
};

/// Step 1 of sign-in: mobile number.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sending = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = context.s;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      final r = await ref.read(authRepositoryProvider).requestOtp(_phone.text.trim());
      if (!mounted) return;
      context.push('/login/otp', extra: (r.phone, r.devCode));
    } catch (e) {
      if (mounted) showSnack(context, errorText(s, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: PageBody(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            children: [
              const Center(child: FasalLogo(size: 80)),
              const Gap(24),
              Text(s.signInTitle, style: t.headlineMedium, textAlign: TextAlign.center),
              const Gap(8),
              Text(s.signInBody, style: t.bodyMedium, textAlign: TextAlign.center),
              const Gap(32),
              FasalTextField(
                fieldKey: const Key('login_phone'),
                label: s.mobileNumber,
                hint: s.phoneHint,
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]'))],
                maxLength: 16,
                validator: (v) => normalizePkPhone(v ?? '') == null ? s.errPhone : null,
                textInputAction: TextInputAction.done,
              ),
              const Gap(24),
              PrimaryButton(key: const Key('login_send'), label: s.sendCode, loading: _sending, onPressed: _send),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 2 of sign-in: the 6-digit code.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone, this.devCode});

  final String phone;
  final String? devCode;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _verifying = false;
  String? _devCode;
  int _wait = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _devCode = widget.devCode;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _wait = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _wait = _wait > 0 ? _wait - 1 : 0);
      if (_wait == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final s = context.s;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _verifying = true);
    try {
      final session = await ref.read(authRepositoryProvider).verifyOtp(widget.phone, _code.text.trim());
      // Fresh data for the signed-in account.
      for (final p in [
        profileProvider,
        cropsProvider,
        activitiesProvider,
        expensesProvider,
        notificationsProvider,
        alertsProvider,
      ]) {
        ref.invalidate(p);
      }
      ref.invalidate(weatherProvider);
      if (!mounted) return;
      if (session.profile != null) {
        ref.read(settingsProvider.notifier).completeSetup();
        context.go('/home');
      } else {
        context.go('/setup');
      }
    } catch (e) {
      if (mounted) showSnack(context, errorText(s, e));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    final s = context.s;
    try {
      final r = await ref.read(authRepositoryProvider).requestOtp(widget.phone);
      if (!mounted) return;
      setState(() => _devCode = r.devCode);
      _startTimer();
    } catch (e) {
      if (mounted) showSnack(context, errorText(s, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ScreenHeader(title: s.enterCode, showBack: true, backTooltip: s.back),
              Expanded(
                child: PageBody(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  children: [
                    Text(s.codeSentTo(widget.phone), style: t.bodyLarge),
                    if (_devCode != null) ...[
                      const Gap(12),
                      InfoNote(s.devCode(_devCode!), emoji: '🧪', color: AppColors.infoContainer),
                    ],
                    const Gap(24),
                    FasalTextField(
                      fieldKey: const Key('otp_code'),
                      label: s.enterCode,
                      hint: '••••••',
                      controller: _code,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => (v ?? '').trim().length == 6 ? null : s.errCode,
                      autofocus: true,
                    ),
                    const Gap(24),
                    PrimaryButton(
                      key: const Key('otp_verify'),
                      label: s.verify,
                      loading: _verifying,
                      onPressed: _verify,
                    ),
                    const Gap(12),
                    Center(
                      child: TextButton(
                        onPressed: _wait == 0 ? _resend : null,
                        style: TextButton.styleFrom(minimumSize: const Size(48, AppSpacing.minTouch)),
                        child: Text(_wait == 0 ? s.resendCode : s.resendIn(_wait)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
