import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/advice/advice_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/ask/ask_fasal_screen.dart';
import '../../features/calendar/crop_calendar_screen.dart';
import '../../features/calendar/tasks_screen.dart';
import '../../features/care/crop_care_screen.dart';
import '../../features/crops/crop_details_screen.dart';
import '../../features/crops/crop_form_screen.dart';
import '../../features/crops/crop_history_screen.dart';
import '../../features/crops/my_crops_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/irrigation/irrigation_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/language_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/records/records_screen.dart';
import '../../features/settings/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/weather/alerts_screen.dart';
import '../../features/weather/weather_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Bottom-nav branch roots, in order.
const kBranchRoots = ['home', 'crops', 'weather', 'records', 'settings'];

/// Detail routes available inside EVERY tab, so the bottom navigation stays
/// visible (as in the reference) and Back returns to where the farmer came from.
List<RouteBase> _detailRoutes() => [
  GoRoute(
    path: 'crop/:cropId',
    builder: (c, s) => CropDetailsScreen(cropId: s.pathParameters['cropId']!),
  ),
  GoRoute(
    path: 'edit-crop/:cropId',
    builder: (c, s) => CropFormScreen.edit(cropId: s.pathParameters['cropId']!),
  ),
  GoRoute(path: 'add-crop', builder: (c, s) => const CropFormScreen.add()),
  GoRoute(
    path: 'calendar/:cropId',
    builder: (c, s) => CropCalendarScreen(cropId: s.pathParameters['cropId']!),
  ),
  GoRoute(
    path: 'history/:cropId',
    builder: (c, s) => CropHistoryScreen(cropId: s.pathParameters['cropId']!),
  ),
  GoRoute(
    path: 'care',
    builder: (c, s) => CropCareScreen(
      cropId: s.uri.queryParameters['crop'],
      initialTab: int.tryParse(s.uri.queryParameters['tab'] ?? '') ?? 0,
    ),
  ),
  GoRoute(
    path: 'irrigation',
    builder: (c, s) => IrrigationScreen(cropId: s.uri.queryParameters['crop']),
  ),
  GoRoute(path: 'tasks', builder: (c, s) => const TasksScreen()),
  GoRoute(path: 'alerts', builder: (c, s) => const AlertsScreen()),
  GoRoute(path: 'notifications', builder: (c, s) => const NotificationsScreen()),
  GoRoute(path: 'ask', builder: (c, s) => const AskFasalScreen()),
  GoRoute(path: 'advice', builder: (c, s) => const AdviceScreen()),
  GoRoute(path: 'profile', builder: (c, s) => const ProfileScreen()),
];

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/language', builder: (c, s) => const LanguageScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(
        path: '/login/otp',
        builder: (c, s) {
          final extra = s.extra;
          if (extra is (String, String?)) return OtpScreen(phone: extra.$1, devCode: extra.$2);
          return const LoginScreen();
        },
      ),
      GoRoute(path: '/setup', builder: (c, s) => const ProfileScreen(isSetup: true)),
      GoRoute(path: '/setup/crop', builder: (c, s) => const CropFormScreen.setup()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (c, s) => const HomeScreen(), routes: _detailRoutes())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/crops', builder: (c, s) => const MyCropsScreen(), routes: _detailRoutes())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/weather', builder: (c, s) => const WeatherScreen(), routes: _detailRoutes())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/records', builder: (c, s) => const RecordsScreen(), routes: _detailRoutes())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen(), routes: _detailRoutes())],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const SplashScreen(),
  );
});

/// Navigation helpers that keep the farmer inside the current tab.
extension AppNav on BuildContext {
  String get _branch {
    final segments = GoRouter.of(this).routerDelegate.currentConfiguration.uri.pathSegments;
    if (segments.isNotEmpty && kBranchRoots.contains(segments.first)) return segments.first;
    return 'home';
  }

  /// Push a detail route (e.g. `crop/123`, `tasks`) within the current tab.
  Future<T?> pushIn<T>(String subPath) => push<T>('/$_branch/$subPath');

  void toCrop(String id) => pushIn<void>('crop/$id');
  void toCalendar(String cropId) => pushIn<void>('calendar/$cropId');
  void toCare(String? cropId, {int tab = 0}) => pushIn<void>('care?tab=$tab${cropId == null ? '' : '&crop=$cropId'}');
  void toIrrigation(String? cropId) => pushIn<void>('irrigation${cropId == null ? '' : '?crop=$cropId'}');
  void toAddCrop() => pushIn<void>('add-crop');
}
