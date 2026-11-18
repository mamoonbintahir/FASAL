// Repository contracts. The UI and providers depend ONLY on these interfaces.
//
// Phase 1: `data/mock/*` implements them with local sample data.
// Phase 2: `data/api/*` implements them against the Node.js/Express REST API.
// Swapping is done in one place: `providers/repository_providers.dart`.

import 'package:fasal_core/models.dart';

/// Result of asking the server to send a sign-in code.
class OtpRequestResult {
  const OtpRequestResult({required this.phone, this.devCode});

  /// Normalised phone number (+923XXXXXXXXX).
  final String phone;

  /// Only returned by a development server (no SMS provider configured).
  final String? devCode;
}

/// A signed-in session. [profile] is null for a new farmer.
class AuthSession {
  const AuthSession({required this.userId, required this.phone, this.profile});
  final String userId;
  final String phone;
  final UserProfile? profile;
}

abstract interface class AuthRepository {
  /// Whether this build requires sign-in (true when talking to the backend).
  bool get requiresSignIn;
  Future<bool> isSignedIn();
  Future<OtpRequestResult> requestOtp(String phone);
  Future<AuthSession> verifyOtp(String phone, String code);
  Future<void> signOut();
  Future<void> deleteAccount();
}

abstract interface class ProfileRepository {
  Future<UserProfile?> getProfile();
  Future<void> saveProfile(UserProfile profile);
  Future<void> clear();
}

/// Crop reference data (stages, activity templates). Synchronous because it is
/// bundled with the app and later cached locally from the backend.
abstract interface class CropCatalogRepository {
  List<CropDefinition> all();
  CropDefinition? byId(String id);
}

abstract interface class CropRepository {
  Future<List<Crop>> getCrops();
  Future<Crop> addCrop(Crop crop);
  Future<void> updateCrop(Crop crop);
  Future<void> deleteCrop(String cropId);
}

abstract interface class TaskRepository {
  /// Tasks for the given crops, merged with the farmer's completion/reminder state.
  Future<List<FarmTask>> getTasks(List<Crop> crops);

  /// Marks a task done/not done. Completing a task also logs an activity in
  /// the farm records (done by the server in API mode).
  Future<FarmTask> setCompleted(FarmTask task, bool done);
  Future<FarmTask> setReminder(FarmTask task, ReminderOption reminder);

  /// Called after a crop is created (applies the "done before Fasal" rule offline).
  Future<void> onCropAdded(Crop crop);
  Future<void> clearForCrop(String cropId);
}

abstract interface class WeatherRepository {
  Future<WeatherReport> getForecast(String district);
  Future<List<WeatherAlert>> getAlerts(String district);
  Future<void> markAlertRead(String alertId);
  Future<void> markAllAlertsRead();
}

abstract interface class RecommendationRepository {
  Future<List<FertilizerGuide>> fertilizerGuides(String cropTypeId);
  Future<List<PestGuide>> pestGuides(String cropTypeId);
  Future<List<PesticideGuide>> pesticideGuides(String cropTypeId);
  Future<IrrigationGuide?> irrigationGuide(String cropTypeId);

  /// Personalised advice from crops + weather + tasks.
  Future<List<Advice>> advice({required List<Crop> crops, required List<FarmTask> tasks, WeatherReport? weather});

  /// "Ask Fasal". Phase 1: rule-based sample answers.
  Future<AssistantAnswer> ask({
    required String question,
    required List<Crop> crops,
    required List<FarmTask> tasks,
    WeatherReport? weather,
  });
}

abstract interface class NotificationRepository {
  Future<List<AppNotification>> getNotifications();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> delete(String id);
  Future<void> restore(AppNotification notification);
}

abstract interface class RecordsRepository {
  Future<List<ActivityRecord>> getActivities();
  Future<List<ExpenseRecord>> getExpenses();
  Future<void> addActivity(ActivityRecord record);
  Future<void> deleteActivity(String id);
  Future<void> deleteActivityForTask(String taskId);
  Future<void> addExpense(ExpenseRecord record);
  Future<void> deleteExpense(String id);
}

enum LocationOutcome { found, denied, unavailable }

class LocationResult {
  const LocationResult(this.outcome, {this.districtEn, this.provinceEn});
  final LocationOutcome outcome;
  final String? districtEn;
  final String? provinceEn;
}

abstract interface class LocationService {
  Future<LocationResult> detectDistrict();
}
