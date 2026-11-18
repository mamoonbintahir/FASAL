import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import '../data/api/api_repositories.dart';
import '../data/mock/mock_repositories.dart';
import '../data/repositories/repositories.dart';
import 'core_providers.dart';
import 'settings_provider.dart';

// ─── The ONE place where mock (offline) vs. API (Dart server) is chosen. ───
// Env.useMockData is true when the app is built without --dart-define=API_BASE_URL.

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Env.useMockData) return MockAuthRepository();
  return ApiAuthRepository(ref.watch(apiClientProvider), ref.watch(secureStorageProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (Env.useMockData) return MockProfileRepository(ref.watch(localStoreProvider));
  return ApiProfileRepository(ref.watch(apiClientProvider));
});

/// Crop reference data ships with the app (shared `fasal_core` package).
final cropCatalogProvider = Provider<CropCatalogRepository>((ref) => const MockCropCatalogRepository());

final cropRepositoryProvider = Provider<CropRepository>((ref) {
  if (Env.useMockData) return MockCropRepository(ref.watch(localStoreProvider));
  return ApiCropRepository(ref.watch(apiClientProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  if (Env.useMockData) {
    return MockTaskRepository(
      ref.watch(localStoreProvider),
      ref.watch(cropCatalogProvider),
      ref.watch(recordsRepositoryProvider),
    );
  }
  return ApiTaskRepository(ref.watch(apiClientProvider));
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  if (!Env.useMockData) return ApiWeatherRepository(ref.watch(apiClientProvider));
  return MockWeatherRepository(
    ref.watch(localStoreProvider),
    simulateFailure: () => ref.read(settingsProvider).simulateWeatherError,
  );
});

final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  if (Env.useMockData) return MockRecommendationRepository(ref.watch(cropCatalogProvider));
  return ApiRecommendationRepository(ref.watch(apiClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (Env.useMockData) return MockNotificationRepository(ref.watch(localStoreProvider));
  return ApiNotificationRepository(ref.watch(apiClientProvider));
});

final recordsRepositoryProvider = Provider<RecordsRepository>((ref) {
  if (Env.useMockData) return MockRecordsRepository(ref.watch(localStoreProvider));
  return ApiRecordsRepository(ref.watch(apiClientProvider));
});

final locationServiceProvider = Provider<LocationService>((ref) => MockLocationService());
