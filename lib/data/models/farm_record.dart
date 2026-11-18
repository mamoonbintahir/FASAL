import 'localized_text.dart';

enum ActivityType { sowing, irrigation, fertilizer, spray, weeding, inspection, harvest, note, other }

extension ActivityTypeX on ActivityType {
  String get emoji => switch (this) {
    ActivityType.sowing => '🌱',
    ActivityType.irrigation => '💧',
    ActivityType.fertilizer => '🧪',
    ActivityType.spray => '🐛',
    ActivityType.weeding => '🌿',
    ActivityType.inspection => '🔍',
    ActivityType.harvest => '🌾',
    ActivityType.note => '📝',
    ActivityType.other => '📌',
  };
}

enum ExpenseCategory { seeds, fertilizer, pesticide, labor, irrigation, machinery, other }

extension ExpenseCategoryX on ExpenseCategory {
  String get emoji => switch (this) {
    ExpenseCategory.seeds => '🌰',
    ExpenseCategory.fertilizer => '🧪',
    ExpenseCategory.pesticide => '🐛',
    ExpenseCategory.labor => '👷',
    ExpenseCategory.irrigation => '💧',
    ExpenseCategory.machinery => '🚜',
    ExpenseCategory.other => '💰',
  };
}

class ActivityRecord {
  const ActivityRecord({
    required this.id,
    this.cropId,
    required this.type,
    required this.date,
    this.note = '',
    this.sourceTaskId,
    this.title,
  });

  final String id;
  final String? cropId;
  final ActivityType type;

  /// Task title when the record came from completing a calendar task.
  final LocalizedText? title;
  final DateTime date;
  final String note;

  /// Set when the record was created by completing a calendar task.
  final String? sourceTaskId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'cropId': cropId,
    'type': type.name,
    'date': date.toIso8601String(),
    'note': note,
    'sourceTaskId': sourceTaskId,
    'title': title?.toJson(),
  };

  factory ActivityRecord.fromJson(Map<String, dynamic> j) => ActivityRecord(
    id: j['id'] as String,
    cropId: j['cropId'] as String?,
    type: ActivityType.values.asNameMap()[j['type']] ?? ActivityType.other,
    date: DateTime.parse(j['date'] as String),
    note: j['note'] as String? ?? '',
    sourceTaskId: j['sourceTaskId'] as String?,
    title: j['title'] is Map<String, dynamic> ? LocalizedText.fromJson(j['title'] as Map<String, dynamic>) : null,
  );
}

class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    this.cropId,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
  });

  final String id;
  final String? cropId;
  final ExpenseCategory category;

  /// Pakistani rupees, whole numbers.
  final int amount;
  final DateTime date;
  final String note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'cropId': cropId,
    'category': category.name,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory ExpenseRecord.fromJson(Map<String, dynamic> j) => ExpenseRecord(
    id: j['id'] as String,
    cropId: j['cropId'] as String?,
    category: ExpenseCategory.values.asNameMap()[j['category']] ?? ExpenseCategory.other,
    amount: (j['amount'] as num).round(),
    date: DateTime.parse(j['date'] as String),
    note: j['note'] as String? ?? '',
  );
}
