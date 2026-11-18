import 'package:fasal_core/fasal_core.dart';
import 'package:logging/logging.dart';

import '../http/api.dart';
import '../store/database.dart';
import '../weather/weather_service.dart';

final _log = Logger('farm');

/// Delivers push notifications to registered devices. Plug in Firebase Cloud
/// Messaging (HTTP v1) by implementing this; the default only logs.
abstract interface class PushSender {
  Future<void> send({required List<String> tokens, required AppNotification notification});
}

class LoggingPushSender implements PushSender {
  @override
  Future<void> send({required List<String> tokens, required AppNotification notification}) async {
    if (tokens.isNotEmpty) _log.fine('push → ${tokens.length} device(s): ${notification.title.en}');
  }
}

/// All farm data operations for a signed-in user. Agricultural rules come from
/// `fasal_core`, the same code the app uses offline.
class FarmService {
  FarmService({
    required this.db,
    required this.weather,
    required this.push,
    DateTime Function()? now,
    this.scheduler = const TaskScheduler(),
  }) : _now = now ?? DateTime.now;

  final Database db;
  final WeatherService weather;
  final PushSender push;
  final TaskScheduler scheduler;
  final DateTime Function() _now;

  DocCollection get _users => db.collection('users');
  DocCollection get _crops => db.collection('crops');
  DocCollection get _states => db.collection('task_states');
  DocCollection get _activities => db.collection('activities');
  DocCollection get _expenses => db.collection('expenses');
  DocCollection get _alerts => db.collection('alerts');
  DocCollection get _notifications => db.collection('notifications');
  DocCollection get _devices => db.collection('devices');

  int _seq = 0;
  String _id(String prefix) => '${prefix}_${_now().microsecondsSinceEpoch}_${_seq++}';

  // ───────────────────────── Profile ─────────────────────────

  Future<Map<String, dynamic>> me(String userId) async {
    final u = await _users.findOne({'id': userId});
    if (u == null) throw ApiError.unauthorized('Account not found');
    return {
      'user': {'id': u['id'], 'phone': u['phone']},
      'profile': u['profile'],
    };
  }

  Future<UserProfile> saveProfile(String userId, Map<String, dynamic> body) async {
    final district = body.reqString('district', max: 60);
    if (findDistrict(district) == null) throw ApiError.badRequest('Unknown district', code: 'validation');
    final profile = UserProfile(
      name: body.optString('name', max: 40),
      district: district,
      province: body.optString('province', max: 40),
      farmName: body.optString('farmName', max: 40),
      farmArea: body.reqNumber('farmArea', max: 10000),
      areaUnit: AreaUnit.values.asNameMap()[body['areaUnit']] ?? AreaUnit.acre,
    );
    final u = await _users.findOne({'id': userId});
    if (u == null) throw ApiError.unauthorized('Account not found');
    await _users.put({...u, 'profile': profile.toJson()});
    return profile;
  }

  Future<UserProfile?> _profile(String userId) async {
    final u = await _users.findOne({'id': userId});
    final p = u?['profile'];
    return p is Map<String, dynamic> ? UserProfile.fromJson(p) : null;
  }

  /// Deletes the account and all its data (privacy / right to erasure).
  Future<void> deleteAccount(String userId) async {
    for (final c in [_crops, _states, _activities, _expenses, _alerts, _notifications, _devices]) {
      await c.delete({'userId': userId});
    }
    await _users.delete({'id': userId});
  }

  // ───────────────────────── Crops ─────────────────────────

  Crop _cropFromDoc(Map<String, dynamic> d) => Crop.fromJson(d);

  Future<List<Crop>> crops(String userId) async {
    final list = (await _crops.find({'userId': userId})).map(_cropFromDoc).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Crop _validateCrop(Map<String, dynamic> body, {required String id, required DateTime createdAt}) {
    final type = body.reqString('cropTypeId', max: 30);
    if (kCropCatalog.every((c) => c.id != type)) throw ApiError.badRequest('Unknown crop type', code: 'validation');
    final sowing = AppDates.dateOnly(body.reqDate('sowingDate'));
    final diff = sowing.difference(AppDates.dateOnly(_now())).inDays;
    if (diff > 60 || diff < -365) {
      throw ApiError.badRequest('Sowing date must be within the last year and the next 60 days', code: 'validation');
    }
    final seed = body['seedKg'];
    return Crop(
      id: id,
      cropTypeId: type,
      variety: body.optString('variety', max: 40),
      sowingDate: sowing,
      area: body.reqNumber('area', max: 10000),
      areaUnit: AreaUnit.values.asNameMap()[body['areaUnit']] ?? AreaUnit.acre,
      fieldName: body.optString('fieldName', max: 40),
      seedKg: seed is num && seed > 0 ? seed.toDouble() : null,
      location: body.optString('location', max: 60),
      createdAt: createdAt,
    );
  }

  Future<Crop> addCrop(String userId, Map<String, dynamic> body) async {
    final crop = _validateCrop(body, id: _id('crop'), createdAt: _now());
    if ((await _crops.find({'userId': userId})).length >= 50) {
      throw ApiError.badRequest('Crop limit reached', code: 'limit');
    }
    await _crops.put({...crop.toJson(), 'userId': userId});
    final def = kCropCatalog.firstWhere((c) => c.id == crop.cropTypeId);
    for (final e in scheduler.tasksDoneBeforeAdding(crop, def).entries) {
      await _putState(userId, crop.id, e.key, TaskUserState(completedAt: e.value));
    }
    return crop;
  }

  Future<Crop> updateCrop(String userId, String cropId, Map<String, dynamic> body) async {
    final existing = await _crops.findOne({'id': cropId, 'userId': userId});
    if (existing == null) throw ApiError.notFound('Crop not found');
    final crop = _validateCrop(body, id: cropId, createdAt: DateTime.parse(existing['createdAt'] as String));
    await _crops.put({...crop.toJson(), 'userId': userId});
    return crop;
  }

  Future<void> deleteCrop(String userId, String cropId) async {
    final n = await _crops.delete({'id': cropId, 'userId': userId});
    if (n == 0) throw ApiError.notFound('Crop not found');
    await _states.delete({'userId': userId, 'cropId': cropId});
    await _notifications.delete({'userId': userId, 'cropId': cropId});
  }

  // ───────────────────────── Tasks ─────────────────────────

  Future<void> _putState(String userId, String cropId, String taskId, TaskUserState s) =>
      _states.put({...s.toJson(), 'id': '$userId:$taskId', 'userId': userId, 'cropId': cropId, 'taskId': taskId});

  Future<List<FarmTask>> tasks(String userId, {List<Crop>? crops}) async {
    final list = crops ?? await this.crops(userId);
    final states = {
      for (final d in await _states.find({'userId': userId})) d['taskId'] as String: TaskUserState.fromJson(d),
    };
    final out = <FarmTask>[];
    for (final c in list) {
      final def = kCropCatalog.where((d) => d.id == c.cropTypeId).firstOrNull;
      if (def != null) out.addAll(scheduler.generate(c, def, states));
    }
    return out..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  /// Marks a task done / not done (and logs it in records), or sets its reminder.
  Future<FarmTask> updateTask(String userId, String taskId, Map<String, dynamic> body) async {
    final all = await tasks(userId);
    final task = all.where((t) => t.id == taskId).firstOrNull;
    if (task == null) throw ApiError.notFound('Task not found');
    var state = TaskUserState(completedAt: task.completedAt, reminder: task.reminder);

    final reminder = body['reminder'];
    if (reminder != null) {
      final r = ReminderOption.values.asNameMap()[reminder];
      if (r == null) throw ApiError.badRequest('Unknown reminder option', code: 'validation');
      state = state.copyWith(reminder: r);
    }
    final done = body['done'];
    if (done != null) {
      if (done is! bool) throw ApiError.badRequest('"done" must be true or false', code: 'validation');
      if (done && !task.isDone) {
        final now = _now();
        state = state.copyWith(completedAt: now);
        await _activities.put({
          ...ActivityRecord(
            id: _id('act'),
            cropId: task.cropId,
            type: _activityType(task.type),
            date: now,
            sourceTaskId: task.id,
            title: task.title,
          ).toJson(),
          'userId': userId,
        });
      } else if (!done && task.isDone) {
        state = state.copyWith(clearCompleted: true);
        await _activities.delete({'userId': userId, 'sourceTaskId': task.id});
      }
    }
    await _putState(userId, task.cropId, task.id, state);
    return task.copyWith(
      completedAt: state.completedAt,
      clearCompleted: state.completedAt == null,
      reminder: state.reminder,
    );
  }

  static ActivityType _activityType(TaskType t) => switch (t) {
    TaskType.sowing => ActivityType.sowing,
    TaskType.irrigation => ActivityType.irrigation,
    TaskType.fertilizer => ActivityType.fertilizer,
    TaskType.weeding => ActivityType.weeding,
    TaskType.inspection || TaskType.pestMonitoring => ActivityType.inspection,
    TaskType.harvest => ActivityType.harvest,
    TaskType.seedPrep || TaskType.harvestPrep => ActivityType.other,
  };

  // ───────────────────────── Records ─────────────────────────

  Future<List<ActivityRecord>> activities(String userId) async =>
      (await _activities.find({'userId': userId})).map(ActivityRecord.fromJson).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  Future<ActivityRecord> addActivity(String userId, Map<String, dynamic> body) async {
    final type = ActivityType.values.asNameMap()[body['type']];
    if (type == null) throw ApiError.badRequest('Unknown activity type', code: 'validation');
    final r = ActivityRecord(
      id: _id('act'),
      cropId: await _ownedCropIdOrNull(userId, body['cropId']),
      type: type,
      date: body.reqDate('date'),
      note: body.optString('note', max: 300),
    );
    await _activities.put({...r.toJson(), 'userId': userId});
    return r;
  }

  Future<void> deleteActivity(String userId, String id) async {
    if (await _activities.delete({'id': id, 'userId': userId}) == 0) throw ApiError.notFound('Record not found');
  }

  Future<List<ExpenseRecord>> expenses(String userId) async =>
      (await _expenses.find({'userId': userId})).map(ExpenseRecord.fromJson).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  Future<ExpenseRecord> addExpense(String userId, Map<String, dynamic> body) async {
    final category = ExpenseCategory.values.asNameMap()[body['category']];
    if (category == null) throw ApiError.badRequest('Unknown expense category', code: 'validation');
    final amount = body.reqNumber('amount', max: 100000000);
    if (amount != amount.roundToDouble()) throw ApiError.badRequest('Amount must be whole rupees', code: 'validation');
    final r = ExpenseRecord(
      id: _id('exp'),
      cropId: await _ownedCropIdOrNull(userId, body['cropId']),
      category: category,
      amount: amount.round(),
      date: body.reqDate('date'),
      note: body.optString('note', max: 300),
    );
    await _expenses.put({...r.toJson(), 'userId': userId});
    return r;
  }

  Future<void> deleteExpense(String userId, String id) async {
    if (await _expenses.delete({'id': id, 'userId': userId}) == 0) throw ApiError.notFound('Record not found');
  }

  Future<String?> _ownedCropIdOrNull(String userId, Object? cropId) async {
    if (cropId == null) return null;
    if (cropId is! String || await _crops.findOne({'id': cropId, 'userId': userId}) == null) {
      throw ApiError.badRequest('Unknown crop', code: 'validation');
    }
    return cropId;
  }

  // ───────────────────────── Weather & alerts ─────────────────────────

  Future<WeatherReport> weatherFor(String userId, {String? district}) async {
    final d = (district != null && district.isNotEmpty) ? district : (await _profile(userId))?.district;
    if (d == null || d.isEmpty) throw ApiError.badRequest('Set your district first', code: 'missing_location');
    return weather.forDistrict(d);
  }

  /// Generates alerts from the forecast, stores them (history + read state)
  /// and returns the last 30 days, newest first.
  Future<List<WeatherAlert>> alerts(String userId) async {
    final crops = await this.crops(userId);
    final types = crops.map((c) => c.cropTypeId).toSet().toList();
    try {
      final report = await weatherFor(userId);
      for (final a in const AlertRules().fromForecast(report, userCropTypes: types)) {
        final docId = '$userId:${a.id}';
        final existing = await _alerts.findOne({'id': docId});
        await _alerts.put({
          ...a.toJson(),
          'id': docId,
          'alertId': a.id,
          'userId': userId,
          'isRead': existing?['isRead'] ?? false,
        });
      }
    } on ApiError catch (e) {
      if (e.code != 'missing_location' && e.code != 'weather_unavailable') rethrow;
    }
    final cutoff = _now().subtract(const Duration(days: 30));
    return [
      for (final d in await _alerts.find({'userId': userId}))
        if (DateTime.parse(d['date'] as String).isAfter(cutoff)) WeatherAlert.fromJson({...d, 'id': d['alertId']}),
    ]..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> markAlertRead(String userId, String alertId) async {
    final d = await _alerts.findOne({'id': '$userId:$alertId'});
    if (d == null) throw ApiError.notFound('Alert not found');
    await _alerts.put({...d, 'isRead': true});
  }

  Future<void> markAllAlertsRead(String userId) async {
    for (final d in await _alerts.find({'userId': userId})) {
      await _alerts.put({...d, 'isRead': true});
    }
  }

  // ───────────────────────── Advice & assistant ─────────────────────────

  Future<WeatherReport?> _weatherOrNull(String userId) async {
    try {
      return await weatherFor(userId);
    } on ApiError {
      return null;
    }
  }

  CropDefinition? _def(String id) => kCropCatalog.where((d) => d.id == id).firstOrNull;

  Future<List<Advice>> advice(String userId) async {
    final crops = await this.crops(userId);
    return const AdviceEngine().build(
      crops: crops,
      defById: _def,
      tasks: await tasks(userId, crops: crops),
      weather: await _weatherOrNull(userId),
      now: _now(),
    );
  }

  Future<AssistantAnswer> ask(String userId, String question) async {
    final crops = await this.crops(userId);
    final answer = const AssistantEngine().answer(
      question: question,
      crops: crops,
      defById: _def,
      tasks: await tasks(userId, crops: crops),
      weather: await _weatherOrNull(userId),
      now: _now(),
    );
    return AssistantAnswer(question: question, answer: answer, isSample: true);
  }

  // ───────────────────────── Notifications ─────────────────────────

  /// Creates any due reminders/alerts for the user (idempotent: ids are
  /// deterministic, existing notifications keep their read/deleted state).
  Future<int> syncNotifications(String userId) async {
    final today = AppDates.dateOnly(_now());
    final crops = await this.crops(userId);
    final tasks = await this.tasks(userId, crops: crops);
    final candidates = <(AppNotification, String?)>[];

    for (final t in tasks.where((t) => !t.isDone && t.reminder != ReminderOption.off)) {
      final days = AppDates.daysBetween(today, t.dueDate);
      if (days == 0) {
        candidates.add((
          AppNotification(
            id: 'task_${t.id}',
            type: switch (t.type) {
              TaskType.irrigation => NotificationType.irrigation,
              TaskType.fertilizer => NotificationType.fertilizer,
              _ => NotificationType.task,
            },
            title: LocalizedText('Today: ${t.title.en}', 'آج: ${t.title.ur}'),
            body: t.description,
            createdAt: _now(),
            target: 'tasks',
          ),
          t.cropId,
        ));
      } else if (days == 1 && t.reminder == ReminderOption.dayBefore) {
        candidates.add((
          AppNotification(
            id: 'tomorrow_${t.id}',
            type: NotificationType.task,
            title: LocalizedText('Tomorrow: ${t.title.en}', 'کل: ${t.title.ur}'),
            body: t.description,
            createdAt: _now(),
            target: 'tasks',
          ),
          t.cropId,
        ));
      }
    }

    for (final c in crops) {
      final def = _def(c.cropTypeId);
      if (def == null) continue;
      final p = CropProgress.of(c, def, today: today);
      final stage = def.stages[p.stageIndex];
      if (!p.notSownYet && p.stageIndex > 0 && p.day - stage.startDay <= 2) {
        candidates.add((
          AppNotification(
            id: 'stage_${c.id}_${p.stageIndex}',
            type: NotificationType.stage,
            title: LocalizedText('${def.name.en}: ${stage.name.en} stage', '${def.name.ur}: ${stage.name.ur} کا مرحلہ'),
            body: stage.summary,
            createdAt: _now(),
            target: 'crops',
          ),
          c.id,
        ));
      }
    }

    for (final a in (await alerts(userId)).where((a) => a.isActive(_now()))) {
      candidates.add((
        AppNotification(
          id: 'alert_${a.id}',
          type: NotificationType.weather,
          title: a.title,
          body: a.message,
          createdAt: _now(),
          target: 'alerts',
        ),
        null,
      ));
    }

    var created = 0;
    final tokens = [
      for (final d in await _devices.find({'userId': userId})) d['token'] as String,
    ];
    for (final (n, cropId) in candidates) {
      final docId = '$userId:${n.id}';
      if (await _notifications.findOne({'id': docId}) != null) continue;
      await _notifications.put({
        ...n.toJson(),
        'id': docId,
        'notificationId': n.id,
        'userId': userId,
        'cropId': cropId,
        'deleted': false,
      });
      created++;
      await push.send(tokens: tokens, notification: n);
    }
    return created;
  }

  Future<List<AppNotification>> notifications(String userId) async {
    await syncNotifications(userId);
    final docs = (await _notifications.find({'userId': userId})).where((d) => d['deleted'] != true).toList();
    return [
      for (final d in docs) AppNotification.fromJson({...d, 'id': d['notificationId']}),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _updateNotification(String userId, String id, Map<String, dynamic> patch) async {
    final d = await _notifications.findOne({'id': '$userId:$id'});
    if (d == null) throw ApiError.notFound('Notification not found');
    await _notifications.put({...d, ...patch});
  }

  Future<void> markNotificationRead(String userId, String id) => _updateNotification(userId, id, {'isRead': true});
  Future<void> deleteNotification(String userId, String id) => _updateNotification(userId, id, {'deleted': true});
  Future<void> restoreNotification(String userId, String id) => _updateNotification(userId, id, {'deleted': false});

  Future<void> markAllNotificationsRead(String userId) async {
    for (final d in await _notifications.find({'userId': userId})) {
      await _notifications.put({...d, 'isRead': true});
    }
  }

  Future<void> registerDevice(String userId, String token, String platform) async {
    if (token.isEmpty || token.length > 4096) throw ApiError.badRequest('Invalid device token', code: 'validation');
    await _devices.put({
      'id': 'dev_${token.hashCode.toUnsigned(32)}_$userId',
      'userId': userId,
      'token': token,
      'platform': platform,
      'updatedAt': _now().toIso8601String(),
    });
  }

  /// Background job: sync notifications for every user (pushes new ones).
  Future<void> syncAllUsers() async {
    for (final u in await _users.find({})) {
      try {
        await syncNotifications(u['id'] as String);
      } catch (e) {
        _log.warning('Notification sync failed for ${u['id']}: $e');
      }
    }
  }
}
