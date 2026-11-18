import 'localized_text.dart';

enum NotificationType { task, stage, weather, irrigation, fertilizer, general }

extension NotificationTypeX on NotificationType {
  String get emoji => switch (this) {
    NotificationType.task => '✅',
    NotificationType.stage => '🌱',
    NotificationType.weather => '🌧️',
    NotificationType.irrigation => '💧',
    NotificationType.fertilizer => '🧪',
    NotificationType.general => '📢',
  };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.target,
  });

  final String id;
  final NotificationType type;
  final LocalizedText title;
  final LocalizedText body;
  final DateTime createdAt;
  final bool isRead;

  /// Where tapping the notification should take the farmer
  /// (a shell-relative route such as `tasks` or `alerts`).
  final String? target;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title.toJson(),
    'body': body.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
    'target': target,
  };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    type: NotificationType.values.asNameMap()[j['type']] ?? NotificationType.general,
    title: LocalizedText.fromJson(j['title'] as Map<String, dynamic>),
    body: LocalizedText.fromJson(j['body'] as Map<String, dynamic>),
    createdAt: DateTime.parse(j['createdAt'] as String),
    isRead: j['isRead'] as bool? ?? false,
    target: j['target'] as String?,
  );

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
    target: target,
  );
}
