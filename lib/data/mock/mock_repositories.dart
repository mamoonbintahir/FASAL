// Phase 1 mock implementations of every repository.
// They persist to SharedPreferences (via LocalStore) so the demo survives app
// restarts, and add a small artificial delay so loading states are visible.

import '../../core/config/env.dart';
import '../../core/network/app_exception.dart';
import '../../core/storage/local_store.dart';

import 'package:fasal_core/models.dart';

import '../repositories/repositories.dart';

import 'package:fasal_core/catalog.dart';
import 'package:fasal_core/engine.dart';

import 'mock_weather_data.dart';

Future<void> _latency() => Future<void>.delayed(Env.mockLatency);

/// Offline mode has no accounts: the farmer uses the app as a local guest.
class MockAuthRepository implements AuthRepository {
  @override
  bool get requiresSignIn => false;

  @override
  Future<bool> isSignedIn() async => true;

  @override
  Future<OtpRequestResult> requestOtp(String phone) async => OtpRequestResult(phone: phone, devCode: '123456');

  @override
  Future<AuthSession> verifyOtp(String phone, String code) async => AuthSession(userId: 'local', phone: phone);

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository(this._store);
  final LocalStore _store;
  static const _key = 'profile';

  @override
  Future<UserProfile?> getProfile() async {
    final json = _store.readMap(_key);
    return json == null ? null : UserProfile.fromJson(json);
  }

  @override
  Future<void> saveProfile(UserProfile profile) => _store.writeJson(_key, profile.toJson());

  @override
  Future<void> clear() => _store.remove(_key);
}

class MockCropCatalogRepository implements CropCatalogRepository {
  const MockCropCatalogRepository();

  @override
  List<CropDefinition> all() => kCropCatalog;

  @override
  CropDefinition? byId(String id) {
    for (final c in kCropCatalog) {
      if (c.id == id) return c;
    }
    return null;
  }
}

class MockCropRepository implements CropRepository {
  MockCropRepository(this._store);
  final LocalStore _store;
  static const _key = 'crops';

  List<Crop> _read() => (_store.readList(_key) ?? const []).map(Crop.fromJson).toList();
  Future<void> _write(List<Crop> crops) => _store.writeJson(_key, crops.map((c) => c.toJson()).toList());

  @override
  Future<List<Crop>> getCrops() async {
    await _latency();
    return _read();
  }

  @override
  Future<Crop> addCrop(Crop crop) async {
    final crops = _read()..add(crop);
    await _write(crops);
    return crop;
  }

  @override
  Future<void> updateCrop(Crop crop) async {
    final crops = _read();
    final i = crops.indexWhere((c) => c.id == crop.id);
    if (i < 0) throw const NotFoundException('Crop not found');
    crops[i] = crop;
    await _write(crops);
  }

  @override
  Future<void> deleteCrop(String cropId) async {
    await _write(_read()..removeWhere((c) => c.id == cropId));
  }
}

class MockTaskRepository implements TaskRepository {
  MockTaskRepository(this._store, this._catalog, this._records, {this.scheduler = const TaskScheduler()});
  final LocalStore _store;
  final CropCatalogRepository _catalog;
  final RecordsRepository _records;
  final TaskScheduler scheduler;
  static const _key = 'task_states';
  int _seq = 0;

  Map<String, TaskUserState> _states() {
    final raw = _store.readMap(_key) ?? const {};
    return {
      for (final e in raw.entries)
        if (e.value is Map<String, dynamic>) e.key: TaskUserState.fromJson(e.value as Map<String, dynamic>),
    };
  }

  Future<void> _save(Map<String, TaskUserState> s) =>
      _store.writeJson(_key, {for (final e in s.entries) e.key: e.value.toJson()});

  @override
  Future<List<FarmTask>> getTasks(List<Crop> crops) async {
    final states = _states();
    final out = <FarmTask>[];
    for (final crop in crops) {
      final def = _catalog.byId(crop.cropTypeId);
      if (def == null) continue;
      out.addAll(scheduler.generate(crop, def, states));
    }
    out.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return out;
  }

  @override
  Future<FarmTask> setCompleted(FarmTask task, bool done) async {
    final s = _states();
    final current = s[task.id] ?? TaskUserState(reminder: task.reminder);
    if (done) {
      final now = DateTime.now();
      s[task.id] = current.copyWith(completedAt: now);
      await _save(s);
      await _records.addActivity(
        ActivityRecord(
          id: 'act_${now.microsecondsSinceEpoch}_${_seq++}',
          cropId: task.cropId,
          type: activityTypeForTask(task.type),
          date: now,
          sourceTaskId: task.id,
          title: task.title,
        ),
      );
      return task.copyWith(completedAt: now);
    }
    s[task.id] = current.copyWith(clearCompleted: true);
    await _save(s);
    await _records.deleteActivityForTask(task.id);
    return task.copyWith(clearCompleted: true);
  }

  @override
  Future<FarmTask> setReminder(FarmTask task, ReminderOption reminder) async {
    final s = _states();
    s[task.id] = (s[task.id] ?? TaskUserState(completedAt: task.completedAt)).copyWith(reminder: reminder);
    await _save(s);
    return task.copyWith(reminder: reminder);
  }

  @override
  Future<void> onCropAdded(Crop crop) async {
    final def = _catalog.byId(crop.cropTypeId);
    if (def == null) return;
    final s = _states();
    for (final e in scheduler.tasksDoneBeforeAdding(crop, def).entries) {
      s[e.key] = TaskUserState(completedAt: e.value);
    }
    await _save(s);
  }

  @override
  Future<void> clearForCrop(String cropId) async {
    final s = _states()..removeWhere((k, _) => k.startsWith('${cropId}_'));
    await _save(s);
  }
}

/// Activity type logged when a task of this type is completed.
ActivityType activityTypeForTask(TaskType t) => switch (t) {
  TaskType.sowing => ActivityType.sowing,
  TaskType.irrigation => ActivityType.irrigation,
  TaskType.fertilizer => ActivityType.fertilizer,
  TaskType.weeding => ActivityType.weeding,
  TaskType.inspection || TaskType.pestMonitoring => ActivityType.inspection,
  TaskType.harvest => ActivityType.harvest,
  TaskType.seedPrep || TaskType.harvestPrep => ActivityType.other,
};

class MockWeatherRepository implements WeatherRepository {
  MockWeatherRepository(this._store, {required this.simulateFailure});
  final LocalStore _store;

  /// Lets "Demo options" simulate the weather-unavailable flow.
  final bool Function() simulateFailure;
  static const _readKey = 'alerts_read';

  Set<String> _readIds() => ((_store.readMap(_readKey)?['ids'] as List?) ?? const []).whereType<String>().toSet();

  @override
  Future<WeatherReport> getForecast(String district) async {
    await _latency();
    if (simulateFailure()) throw const NetworkException();
    return MockWeatherData.report(district);
  }

  @override
  Future<List<WeatherAlert>> getAlerts(String district) async {
    if (simulateFailure()) return const [];
    final read = _readIds();
    return MockWeatherData.alerts().map((a) => read.contains(a.id) ? a.copyWith(isRead: true) : a).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> markAlertRead(String alertId) =>
      _store.writeJson(_readKey, {'ids': (_readIds()..add(alertId)).toList()});

  @override
  Future<void> markAllAlertsRead() =>
      _store.writeJson(_readKey, {'ids': MockWeatherData.alerts().map((a) => a.id).toList()});
}

class MockRecommendationRepository implements RecommendationRepository {
  MockRecommendationRepository(this._catalog);
  final CropCatalogRepository _catalog;
  final AdviceEngine _advice = const AdviceEngine();
  final AssistantEngine _assistant = const AssistantEngine();

  @override
  Future<List<FertilizerGuide>> fertilizerGuides(String cropTypeId) async =>
      kFertilizerGuides.where((g) => g.cropTypeId == cropTypeId).toList()
        ..sort((a, b) => a.stageIndex.compareTo(b.stageIndex));

  @override
  Future<List<PestGuide>> pestGuides(String cropTypeId) async =>
      kPestGuides.where((g) => g.cropTypeId == cropTypeId).toList();

  @override
  Future<List<PesticideGuide>> pesticideGuides(String cropTypeId) async =>
      kPesticideGuides.where((g) => g.cropTypeId == cropTypeId).toList();

  @override
  Future<IrrigationGuide?> irrigationGuide(String cropTypeId) async {
    for (final g in kIrrigationGuides) {
      if (g.cropTypeId == cropTypeId) return g;
    }
    return null;
  }

  @override
  Future<List<Advice>> advice({
    required List<Crop> crops,
    required List<FarmTask> tasks,
    WeatherReport? weather,
  }) async {
    await _latency();
    return _advice.build(crops: crops, defById: _catalog.byId, tasks: tasks, weather: weather);
  }

  @override
  Future<AssistantAnswer> ask({
    required String question,
    required List<Crop> crops,
    required List<FarmTask> tasks,
    WeatherReport? weather,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final a = _assistant.answer(
      question: question,
      crops: crops,
      defById: _catalog.byId,
      tasks: tasks,
      weather: weather,
    );
    return AssistantAnswer(question: question, answer: a, isSample: true);
  }
}

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository(this._store);
  final LocalStore _store;
  static const _key = 'notification_state';

  Map<String, dynamic> _state() => _store.readMap(_key) ?? <String, dynamic>{};
  Set<String> _set(String name) => ((_state()[name] as List?) ?? const []).whereType<String>().toSet();

  Future<void> _put(String name, Set<String> values) {
    final s = _state();
    s[name] = values.toList();
    return _store.writeJson(_key, s);
  }

  List<AppNotification> _seed() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n_rain',
        type: NotificationType.weather,
        target: 'alerts',
        createdAt: now.subtract(const Duration(hours: 1)),
        title: const LocalizedText('Rain expected in 3 days', '3 دن میں بارش متوقع'),
        body: const LocalizedText(
          'Hold your planned irrigation and check drainage.',
          'طے شدہ آبپاشی روکیں اور نکاس چیک کریں۔',
        ),
      ),
      AppNotification(
        id: 'n_tasks',
        type: NotificationType.task,
        target: 'tasks',
        createdAt: now.subtract(const Duration(hours: 3)),
        title: const LocalizedText('You have tasks today', 'آج آپ کے کام ہیں'),
        body: const LocalizedText(
          'Open Today’s tasks to see what to do on your farm.',
          'کھیت کے کام دیکھنے کے لیے آج کے کام کھولیں۔',
        ),
      ),
      AppNotification(
        id: 'n_irr',
        type: NotificationType.irrigation,
        target: 'irrigation',
        createdAt: now.subtract(const Duration(hours: 20)),
        title: const LocalizedText('Check soil moisture', 'زمین کی نمی چیک کریں'),
        body: const LocalizedText('Check soil before your next irrigation.', 'اگلے پانی سے پہلے مٹی چیک کریں۔'),
      ),
      AppNotification(
        id: 'n_stage',
        type: NotificationType.stage,
        target: 'crops',
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
        title: const LocalizedText('New crop stage', 'فصل کا نیا مرحلہ'),
        body: const LocalizedText(
          'Your crop has moved to a new growth stage. See what to do now.',
          'آپ کی فصل نئے مرحلے میں داخل ہو گئی ہے۔ دیکھیں ابھی کیا کرنا ہے۔',
        ),
      ),
      AppNotification(
        id: 'n_fert',
        type: NotificationType.fertilizer,
        target: 'care',
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
        title: const LocalizedText('Fertilizer coming up', 'کھاد کا وقت قریب'),
        body: const LocalizedText('A fertilizer activity is due within a week.', 'ایک ہفتے میں کھاد ڈالنی ہے۔'),
      ),
      AppNotification(
        id: 'n_welcome',
        type: NotificationType.general,
        createdAt: now.subtract(const Duration(days: 5)),
        isRead: true,
        title: const LocalizedText('Welcome to Fasal', 'فصل میں خوش آمدید'),
        body: const LocalizedText(
          'Tap Listen on any card to hear advice in Urdu or English.',
          'اردو یا انگریزی میں مشورہ سننے کے لیے کسی بھی کارڈ پر سنیں دبائیں۔',
        ),
      ),
    ];
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    await _latency();
    final read = _set('read');
    final deleted = _set('deleted');
    return _seed()
        .where((n) => !deleted.contains(n.id))
        .map((n) => read.contains(n.id) ? n.copyWith(isRead: true) : n)
        .toList();
  }

  @override
  Future<void> markRead(String id) => _put('read', _set('read')..add(id));

  @override
  Future<void> markAllRead() => _put('read', _seed().map((n) => n.id).toSet());

  @override
  Future<void> delete(String id) => _put('deleted', _set('deleted')..add(id));

  @override
  Future<void> restore(AppNotification notification) => _put('deleted', _set('deleted')..remove(notification.id));
}

class MockRecordsRepository implements RecordsRepository {
  MockRecordsRepository(this._store);
  final LocalStore _store;
  static const _aKey = 'activities';
  static const _eKey = 'expenses';

  List<ActivityRecord> _a() => (_store.readList(_aKey) ?? const []).map(ActivityRecord.fromJson).toList();
  List<ExpenseRecord> _e() => (_store.readList(_eKey) ?? const []).map(ExpenseRecord.fromJson).toList();
  Future<void> _wa(List<ActivityRecord> l) => _store.writeJson(_aKey, l.map((r) => r.toJson()).toList());
  Future<void> _we(List<ExpenseRecord> l) => _store.writeJson(_eKey, l.map((r) => r.toJson()).toList());

  @override
  Future<List<ActivityRecord>> getActivities() async {
    await _latency();
    return _a()..sort((x, y) => y.date.compareTo(x.date));
  }

  @override
  Future<List<ExpenseRecord>> getExpenses() async => _e()..sort((x, y) => y.date.compareTo(x.date));

  @override
  Future<void> addActivity(ActivityRecord record) => _wa(_a()..add(record));

  @override
  Future<void> deleteActivity(String id) => _wa(_a()..removeWhere((r) => r.id == id));

  @override
  Future<void> deleteActivityForTask(String taskId) => _wa(_a()..removeWhere((r) => r.sourceTaskId == taskId));

  @override
  Future<void> addExpense(ExpenseRecord record) => _we(_e()..add(record));

  @override
  Future<void> deleteExpense(String id) => _we(_e()..removeWhere((r) => r.id == id));
}

/// Phase 1 location: returns a demo district. Phase 2 uses GPS
/// (geolocator + permission_handler) and reverse geocoding.
class MockLocationService implements LocationService {
  @override
  Future<LocationResult> detectDistrict() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const LocationResult(LocationOutcome.found, districtEn: 'Sahiwal', provinceEn: 'Punjab');
  }
}
