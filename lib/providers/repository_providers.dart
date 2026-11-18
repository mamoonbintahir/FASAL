import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import '../data/api/api_repositories.dart';
import '../data/mock/mock_repositories.dart';
import '../data/repositories/repositories.dart';
import 'core_providers.dart';
import 'settings_provider.dart';

// ─── The ONE place where mock vs. real implementations are chosen. ───

final authRepositoryProvider = Provider<AuthRepository>((ref) => MockAuthRepository());

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => MockProfileRepository(ref.watch(localStoreProvider)),
);

final cropCatalogProvider = Provider<CropCatalogRepository>((ref) => const MockCropCatalogRepository());

final cropRepositoryProvider = Provider<CropRepository>((ref) {
  if (!Env.useMockData) return ApiCropRepository(ref.watch(apiClientProvider));
  return MockCropRepository(ref.watch(localStoreProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => MockTaskRepository(ref.watch(localStoreProvider), ref.watch(cropCatalogProvider)),
);

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  if (!Env.useMockData) return ApiWeatherRepository(ref.watch(apiClientProvider));
  return MockWeatherRepository(
    ref.watch(localStoreProvider),
    simulateFailure: () => ref.read(settingsProvider).simulateWeatherError,
  );
});

final recommendationRepositoryProvider = Provider<RecommendationRepository>(
  (ref) => MockRecommendationRepository(ref.watch(cropCatalogProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => MockNotificationRepository(ref.watch(localStoreProvider)),
);

final recordsRepositoryProvider = Provider<RecordsRepository>(
  (ref) => MockRecordsRepository(ref.watch(localStoreProvider)),
);

final locationServiceProvider = Provider<LocationService>((ref) => MockLocationService());
