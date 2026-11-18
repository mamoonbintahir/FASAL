import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';
import '../core/storage/local_store.dart';
import '../core/storage/secure_storage.dart';

/// Overridden in `main.dart` with the real instance (and in tests with a fake).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden in main()'),
);

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore(ref.watch(sharedPreferencesProvider)));

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    secureStorage: ref.watch(secureStorageProvider),
    onUnauthorized: () => ref.read(sessionEventsProvider.notifier).expired(),
  ),
);

/// Increments whenever the server rejects the session; the app listens and
/// returns the farmer to the sign-in screen.
class SessionEvents extends Notifier<int> {
  @override
  int build() => 0;

  void expired() => state = state + 1;
}

final sessionEventsProvider = NotifierProvider<SessionEvents, int>(SessionEvents.new);

/// "Today" as a provider so tests can pin the date.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
