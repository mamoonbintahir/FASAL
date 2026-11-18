import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/app_exception.dart';
import '../core/utils/date_utils.dart';
import '../data/mock/engine/advisors.dart';
import '../data/models/app_notification.dart';
import '../data/models/crop.dart';
import '../data/models/crop_definition.dart';
import '../data/models/farm_record.dart';
import '../data/models/farm_task.dart';
import '../data/models/guidance.dart';
import '../data/models/user_profile.dart';
import '../data/models/weather.dart';
import 'core_providers.dart';
import 'repository_providers.dart';
import 'settings_provider.dart';

int _idSeq = 0;
String newId(String prefix) => '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}';

// ───────────────────────── Profile ─────────────────────────

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() => ref.watch(profileRepositoryProvider).getProfile();

  Future<void> save(UserProfile profile) async {
    await ref.read(profileRepositoryProvider).saveProfile(profile);
    state = AsyncData(profile);
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);

// ───────────────────────── Crops ─────────────────────────

class CropsNotifier extends AsyncNotifier<List<Crop>> {
  @override
  Future<List<Crop>> build() => ref.watch(cropRepositoryProvider).getCrops();

  List<Crop> get _current => state.value ?? const [];

  Future<Crop> add(Crop crop) async {
    final saved = await ref.read(cropRepositoryProvider).addCrop(crop);
    await _markPastTasksDone(saved);
    state = AsyncData([..._current, saved]);
    return saved;
  }

  Future<void> updateCrop(Crop crop) async {
    await ref.read(cropRepositoryProvider).updateCrop(crop);
    state = AsyncData([for (final c in _current) c.id == crop.id ? crop : c]);
  }

  Future<void> remove(String cropId) async {
    await ref.read(cropRepositoryProvider).deleteCrop(cropId);
    await ref.read(taskRepositoryProvider).clearForCrop(cropId);
    state = AsyncData(_current.where((c) => c.id != cropId).toList());
  }

  /// Product decision: when a crop is added with a past sowing date, tasks that
  /// were due more than 3 days before it was added are treated as already
  /// handled (the farmer did them before using Fasal) instead of flooding the
  /// "overdue" list. Recent ones stay visible as overdue.
  Future<void> _markPastTasksDone(Crop crop) async {
    final def = ref.read(cropCatalogProvider).byId(crop.cropTypeId);
    if (def == null) return;
    final cutoff = AppDates.dateOnly(crop.createdAt).subtract(const Duration(days: 3));
    final sown = AppDates.dateOnly(crop.sowingDate);
    final repo = ref.read(taskRepositoryProvider);
    for (final t in def.templates) {
      final due = sown.add(Duration(days: t.day));
      if (due.isBefore(cutoff)) await repo.setCompleted('${crop.id}_${t.id}', due);
    }
  }
}

final cropsProvider = AsyncNotifierProvider<CropsNotifier, List<Crop>>(CropsNotifier.new);

/// A crop joined with its definition and computed progress — what screens render.
class CropView {
  const CropView({required this.crop, required this.def, required this.progress});
  final Crop crop;
  final CropDefinition def;
  final CropProgress progress;

  CropStageDef get stage => def.stages[progress.stageIndex];
  CropStageDef? get nextStage =>
      progress.stageIndex + 1 < def.stages.length ? def.stages[progress.stageIndex + 1] : null;
}

final cropViewsProvider = Provider<AsyncValue<List<CropView>>>((ref) {
  final catalog = ref.watch(cropCatalogProvider);
  final today = ref.watch(clockProvider)();
  return ref
      .watch(cropsProvider)
      .whenData(
        (crops) => [
          for (final c in crops)
            if (catalog.byId(c.cropTypeId) case final def?)
              CropView(
                crop: c,
                def: def,
                progress: CropProgress.of(c, def, today: today),
              ),
        ],
      );
});

final cropViewProvider = Provider.family<CropView?, String>((ref, id) {
  final views = ref.watch(cropViewsProvider).value ?? const [];
  for (final v in views) {
    if (v.crop.id == id) return v;
  }
  return null;
});

// ───────────────────────── Tasks ─────────────────────────

class TasksNotifier extends AsyncNotifier<List<FarmTask>> {
  @override
  Future<List<FarmTask>> build() async {
    final crops = await ref.watch(cropsProvider.future);
    return ref.read(taskRepositoryProvider).getTasks(crops);
  }

  void _replace(FarmTask t) {
    final list = state.value;
    if (list == null) return;
    state = AsyncData([for (final x in list) x.id == t.id ? t : x]);
  }

  /// Completing a task also logs it in Records → Crop history.
  Future<void> toggle(FarmTask task) async {
    final repo = ref.read(taskRepositoryProvider);
    final records = ref.read(recordsRepositoryProvider);
    if (task.isDone) {
      _replace(task.copyWith(clearCompleted: true));
      await repo.setCompleted(task.id, null);
      await records.deleteActivityForTask(task.id);
    } else {
      final now = DateTime.now();
      _replace(task.copyWith(completedAt: now));
      await repo.setCompleted(task.id, now);
      await records.addActivity(
        ActivityRecord(
          id: newId('act'),
          cropId: task.cropId,
          type: activityTypeFor(task.type),
          date: now,
          sourceTaskId: task.id,
          title: task.title,
        ),
      );
    }
    ref.invalidate(activitiesProvider);
  }

  Future<void> setReminder(FarmTask task, ReminderOption r) async {
    _replace(task.copyWith(reminder: r));
    await ref.read(taskRepositoryProvider).setReminder(task.id, r);
  }
}

ActivityType activityTypeFor(TaskType t) => switch (t) {
  TaskType.sowing => ActivityType.sowing,
  TaskType.irrigation => ActivityType.irrigation,
  TaskType.fertilizer => ActivityType.fertilizer,
  TaskType.weeding => ActivityType.weeding,
  TaskType.inspection || TaskType.pestMonitoring => ActivityType.inspection,
  TaskType.harvest => ActivityType.harvest,
  TaskType.seedPrep || TaskType.harvestPrep => ActivityType.other,
};

final tasksProvider = AsyncNotifierProvider<TasksNotifier, List<FarmTask>>(TasksNotifier.new);

// ───────────────────────── Weather ─────────────────────────

final weatherProvider = FutureProvider<WeatherReport>((ref) async {
  ref.watch(settingsProvider.select((s) => s.simulateWeatherError));
  final profile = await ref.watch(profileProvider.future);
  if (profile == null || !profile.hasLocation) throw const MissingLocationException();
  return ref.watch(weatherRepositoryProvider).getForecast(profile.district);
});

class AlertsNotifier extends AsyncNotifier<List<WeatherAlert>> {
  @override
  Future<List<WeatherAlert>> build() async {
    ref.watch(settingsProvider.select((s) => s.simulateWeatherError));
    final profile = await ref.watch(profileProvider.future);
    if (profile == null || !profile.hasLocation) return const [];
    return ref.read(weatherRepositoryProvider).getAlerts(profile.district);
  }

  Future<void> markRead(String id) async {
    state = AsyncData([for (final a in state.value ?? <WeatherAlert>[]) a.id == id ? a.copyWith(isRead: true) : a]);
    await ref.read(weatherRepositoryProvider).markAlertRead(id);
  }

  Future<void> markAllRead() async {
    state = AsyncData([for (final a in state.value ?? <WeatherAlert>[]) a.copyWith(isRead: true)]);
    await ref.read(weatherRepositoryProvider).markAllAlertsRead();
  }
}

final alertsProvider = AsyncNotifierProvider<AlertsNotifier, List<WeatherAlert>>(AlertsNotifier.new);

// ───────────────────────── Notifications ─────────────────────────

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    final prefs = ref.watch(settingsProvider.select((s) => s.notificationPrefs));
    final all = await ref.read(notificationRepositoryProvider).getNotifications();
    return all.where((n) => prefs[n.type] ?? true).toList();
  }

  List<AppNotification> get _list => state.value ?? const [];

  Future<void> markRead(String id) async {
    state = AsyncData([for (final n in _list) n.id == id ? n.copyWith(isRead: true) : n]);
    await ref.read(notificationRepositoryProvider).markRead(id);
  }

  Future<void> markAllRead() async {
    state = AsyncData([for (final n in _list) n.copyWith(isRead: true)]);
    await ref.read(notificationRepositoryProvider).markAllRead();
  }

  Future<void> delete(AppNotification n) async {
    state = AsyncData(_list.where((x) => x.id != n.id).toList());
    await ref.read(notificationRepositoryProvider).delete(n.id);
  }

  Future<void> restore(AppNotification n) async {
    await ref.read(notificationRepositoryProvider).restore(n);
    ref.invalidateSelf();
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

final unreadCountProvider = Provider<int>((ref) {
  final n = ref.watch(notificationsProvider).value ?? const [];
  final a = ref.watch(alertsProvider).value ?? const [];
  return n.where((x) => !x.isRead).length + a.where((x) => !x.isRead).length;
});

// ───────────────────────── Records ─────────────────────────

class ActivitiesNotifier extends AsyncNotifier<List<ActivityRecord>> {
  @override
  Future<List<ActivityRecord>> build() => ref.read(recordsRepositoryProvider).getActivities();

  Future<void> add(ActivityRecord r) async {
    final repo = ref.read(recordsRepositoryProvider);
    await repo.addActivity(r);
    state = AsyncData(await repo.getActivities());
  }

  Future<void> delete(ActivityRecord r) async {
    state = AsyncData((state.value ?? const []).where((x) => x.id != r.id).toList());
    await ref.read(recordsRepositoryProvider).deleteActivity(r.id);
  }
}

final activitiesProvider = AsyncNotifierProvider<ActivitiesNotifier, List<ActivityRecord>>(ActivitiesNotifier.new);

class ExpensesNotifier extends AsyncNotifier<List<ExpenseRecord>> {
  @override
  Future<List<ExpenseRecord>> build() => ref.read(recordsRepositoryProvider).getExpenses();

  Future<void> add(ExpenseRecord r) async {
    final repo = ref.read(recordsRepositoryProvider);
    await repo.addExpense(r);
    state = AsyncData(await repo.getExpenses());
  }

  Future<void> delete(ExpenseRecord r) async {
    state = AsyncData((state.value ?? const []).where((x) => x.id != r.id).toList());
    await ref.read(recordsRepositoryProvider).deleteExpense(r.id);
  }
}

final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<ExpenseRecord>>(ExpensesNotifier.new);

// ───────────────────────── Guidance & advice ─────────────────────────

final fertilizerGuidesProvider = FutureProvider.family<List<FertilizerGuide>, String>(
  (ref, cropTypeId) => ref.watch(recommendationRepositoryProvider).fertilizerGuides(cropTypeId),
);

final pestGuidesProvider = FutureProvider.family<List<PestGuide>, String>(
  (ref, cropTypeId) => ref.watch(recommendationRepositoryProvider).pestGuides(cropTypeId),
);

final pesticideGuidesProvider = FutureProvider.family<List<PesticideGuide>, String>(
  (ref, cropTypeId) => ref.watch(recommendationRepositoryProvider).pesticideGuides(cropTypeId),
);

final irrigationGuideProvider = FutureProvider.family<IrrigationGuide?, String>(
  (ref, cropTypeId) => ref.watch(recommendationRepositoryProvider).irrigationGuide(cropTypeId),
);

/// Weather if available, otherwise null (guidance still works without it).
final optionalWeatherProvider = Provider<WeatherReport?>((ref) => ref.watch(weatherProvider).value);

final irrigationStatusProvider = Provider.family<IrrigationStatus?, String>((ref, cropId) {
  final view = ref.watch(cropViewProvider(cropId));
  final tasks = ref.watch(tasksProvider).value;
  if (view == null || tasks == null) return null;
  return const IrrigationAdvisor().statusFor(
    crop: view.crop,
    def: view.def,
    tasks: tasks,
    weather: ref.watch(optionalWeatherProvider),
    now: ref.watch(clockProvider)(),
  );
});

final adviceProvider = FutureProvider<List<Advice>>((ref) async {
  final crops = await ref.watch(cropsProvider.future);
  final tasks = await ref.watch(tasksProvider.future);
  final weather = ref.watch(optionalWeatherProvider);
  return ref.watch(recommendationRepositoryProvider).advice(crops: crops, tasks: tasks, weather: weather);
});

// ───────────────────────── Demo helpers ─────────────────────────

/// Loads a sample farm matching the reference design (wheat, day 38, 5 acres)
/// plus sample records. Used from Settings → Demo options.
Future<void> loadSampleFarm(WidgetRef ref) async {
  final now = DateTime.now();
  final sown = AppDates.dateOnly(now).subtract(const Duration(days: 38));
  final crop = await ref
      .read(cropsProvider.notifier)
      .add(
        Crop(
          id: newId('crop'),
          cropTypeId: 'wheat',
          variety: 'Akbar-2019',
          sowingDate: sown,
          area: 5,
          seedKg: 50,
          fieldName: 'Canal side',
          createdAt: now,
        ),
      );
  final activities = ref.read(activitiesProvider.notifier);
  final expenses = ref.read(expensesProvider.notifier);
  await activities.add(ActivityRecord(id: newId('act'), cropId: crop.id, type: ActivityType.sowing, date: sown));
  await activities.add(
    ActivityRecord(
      id: newId('act'),
      cropId: crop.id,
      type: ActivityType.irrigation,
      date: sown.add(const Duration(days: 21)),
    ),
  );
  await expenses.add(
    ExpenseRecord(
      id: newId('exp'),
      cropId: crop.id,
      category: ExpenseCategory.seeds,
      amount: 9000,
      date: sown.subtract(const Duration(days: 1)),
    ),
  );
  await expenses.add(
    ExpenseRecord(
      id: newId('exp'),
      cropId: crop.id,
      category: ExpenseCategory.fertilizer,
      amount: 14500,
      date: sown.add(const Duration(days: 21)),
    ),
  );
}
