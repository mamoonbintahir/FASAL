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
