// API implementations of every repository, talking to the FASAL Dart server
// (`server/`). Wire format = the `toJson`/`fromJson` of the shared
// `fasal_core` models, so the app and server cannot drift apart.

import 'package:fasal_core/models.dart';

import '../../core/network/api_client.dart';
import '../../core/network/app_exception.dart';
import '../../core/storage/secure_storage.dart';
import '../repositories/repositories.dart';

List<Map<String, dynamic>> _list(Object? data) =>
    data is List ? data.whereType<Map<String, dynamic>>().toList() : throw const ServerException('Unexpected response');

Map<String, dynamic> _map(Object? data) =>
    data is Map<String, dynamic> ? data : throw const ServerException('Unexpected response');

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, this._secure);
  final ApiClient _api;
  final SecureStorage _secure;

  @override
  bool get requiresSignIn => true;

  @override
  Future<bool> isSignedIn() async => (await _secure.readToken()) != null;

  @override
  Future<OtpRequestResult> requestOtp(String phone) async {
    final d = _map(await _api.post('/v1/auth/otp/request', body: {'phone': phone}));
    return OtpRequestResult(phone: d['phone'] as String, devCode: d['devCode'] as String?);
  }

  @override
  Future<AuthSession> verifyOtp(String phone, String code) async {
    final d = _map(await _api.post('/v1/auth/otp/verify', body: {'phone': phone, 'code': code}));
    await _secure.writeToken(d['token'] as String);
    final user = _map(d['user']);
    final profile = d['profile'];
    return AuthSession(
      userId: user['id'] as String,
      phone: user['phone'] as String,
      profile: profile is Map<String, dynamic> ? UserProfile.fromJson(profile) : null,
    );
  }

  @override
  Future<void> signOut() => _secure.clear();

  @override
  Future<void> deleteAccount() async {
    await _api.delete('/v1/me');
    await _secure.clear();
  }
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._api);
  final ApiClient _api;

  @override
  Future<UserProfile?> getProfile() async {
    final p = _map(await _api.get('/v1/me'))['profile'];
    return p is Map<String, dynamic> ? UserProfile.fromJson(p) : null;
  }

  @override
  Future<void> saveProfile(UserProfile profile) => _api.put('/v1/me/profile', body: profile.toJson());

  @override
  Future<void> clear() async {}
}

class ApiCropRepository implements CropRepository {
  ApiCropRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<Crop>> getCrops() async => _list(await _api.get('/v1/crops')).map(Crop.fromJson).toList();

  @override
  Future<Crop> addCrop(Crop crop) async => Crop.fromJson(_map(await _api.post('/v1/crops', body: crop.toJson())));

  @override
  Future<void> updateCrop(Crop crop) => _api.put('/v1/crops/${crop.id}', body: crop.toJson());

  @override
  Future<void> deleteCrop(String cropId) => _api.delete('/v1/crops/$cropId');
}

class ApiTaskRepository implements TaskRepository {
  ApiTaskRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<FarmTask>> getTasks(List<Crop> crops) async =>
      _list(await _api.get('/v1/tasks')).map(FarmTask.fromJson).toList();

  @override
  Future<FarmTask> setCompleted(FarmTask task, bool done) async =>
      FarmTask.fromJson(_map(await _api.patch('/v1/tasks/${task.id}', body: {'done': done})));

  @override
  Future<FarmTask> setReminder(FarmTask task, ReminderOption reminder) async =>
      FarmTask.fromJson(_map(await _api.patch('/v1/tasks/${task.id}', body: {'reminder': reminder.name})));

  @override
  Future<void> onCropAdded(Crop crop) async {} // the server applies the rule on create

  @override
  Future<void> clearForCrop(String cropId) async {} // the server cleans up on delete
}

class ApiWeatherRepository implements WeatherRepository {
  ApiWeatherRepository(this._api);
  final ApiClient _api;

  @override
  Future<WeatherReport> getForecast(String district) async =>
      WeatherReport.fromJson(_map(await _api.get('/v1/weather', query: {'district': district})));

  @override
  Future<List<WeatherAlert>> getAlerts(String district) async =>
      _list(await _api.get('/v1/weather/alerts')).map(WeatherAlert.fromJson).toList();

  @override
  Future<void> markAlertRead(String alertId) => _api.post('/v1/weather/alerts/$alertId/read');

  @override
  Future<void> markAllAlertsRead() => _api.post('/v1/weather/alerts/read-all');
}

class ApiRecommendationRepository implements RecommendationRepository {
  ApiRecommendationRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<FertilizerGuide>> fertilizerGuides(String cropTypeId) async =>
      _list(await _api.get('/v1/guidance/$cropTypeId/fertilizer')).map(FertilizerGuide.fromJson).toList();

  @override
  Future<List<PestGuide>> pestGuides(String cropTypeId) async =>
      _list(await _api.get('/v1/guidance/$cropTypeId/pests')).map(PestGuide.fromJson).toList();

  @override
  Future<List<PesticideGuide>> pesticideGuides(String cropTypeId) async =>
      _list(await _api.get('/v1/guidance/$cropTypeId/sprays')).map(PesticideGuide.fromJson).toList();

  @override
  Future<IrrigationGuide?> irrigationGuide(String cropTypeId) async {
    final d = await _api.get('/v1/guidance/$cropTypeId/irrigation');
    return d is Map<String, dynamic> ? IrrigationGuide.fromJson(d) : null;
  }

  @override
  Future<List<Advice>> advice({
    required List<Crop> crops,
    required List<FarmTask> tasks,
    WeatherReport? weather,
  }) async => _list(await _api.get('/v1/advice')).map(Advice.fromJson).toList();

  @override
  Future<AssistantAnswer> ask({
    required String question,
    required List<Crop> crops,
    required List<FarmTask> tasks,
    WeatherReport? weather,
  }) async => AssistantAnswer.fromJson(_map(await _api.post('/v1/ask', body: {'question': question})));
}

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<AppNotification>> getNotifications() async =>
      _list(await _api.get('/v1/notifications')).map(AppNotification.fromJson).toList();

  @override
  Future<void> markRead(String id) => _api.post('/v1/notifications/$id/read');

  @override
  Future<void> markAllRead() => _api.post('/v1/notifications/read-all');

  @override
  Future<void> delete(String id) => _api.delete('/v1/notifications/$id');

  @override
  Future<void> restore(AppNotification notification) => _api.post('/v1/notifications/${notification.id}/restore');
}

class ApiRecordsRepository implements RecordsRepository {
  ApiRecordsRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<ActivityRecord>> getActivities() async =>
      _list(await _api.get('/v1/records/activities')).map(ActivityRecord.fromJson).toList();

  @override
  Future<List<ExpenseRecord>> getExpenses() async =>
      _list(await _api.get('/v1/records/expenses')).map(ExpenseRecord.fromJson).toList();

  @override
  Future<void> addActivity(ActivityRecord record) => _api.post('/v1/records/activities', body: record.toJson());

  @override
  Future<void> deleteActivity(String id) => _api.delete('/v1/records/activities/$id');

  @override
  Future<void> deleteActivityForTask(String taskId) async {} // the server does this when a task is un-done

  @override
  Future<void> addExpense(ExpenseRecord record) => _api.post('/v1/records/expenses', body: record.toJson());

  @override
  Future<void> deleteExpense(String id) => _api.delete('/v1/records/expenses/$id');
}
