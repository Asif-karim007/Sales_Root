import 'package:salesroot/core/utils/json_fields.dart';

/// The filter chips on the notifications screen.
enum NotificationCategory {
  reminders('Reminders'),
  team('Team'),
  newLeads('NewLeads'),
  billing('Billing');

  const NotificationCategory(this.wire);

  final String wire;
}

enum NotificationKind {
  reminder('Reminder', NotificationCategory.reminders),
  taskDue('TaskDue', NotificationCategory.reminders),
  newLead('NewLead', NotificationCategory.newLeads),
  mention('Mention', NotificationCategory.team),
  assigned('Assigned', NotificationCategory.team),
  approval('Approval', NotificationCategory.team),
  notice('Notice', NotificationCategory.team),
  billing('Billing', NotificationCategory.billing);

  const NotificationKind(this.wire, this.category);

  final String wire;
  final NotificationCategory category;

  static NotificationKind fromWire(String? value) => values.firstWhere(
    (kind) => kind.wire == value,
    orElse: () => NotificationKind.notice,
  );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.createdAt,
    required this.isRead,
    this.body,
    this.route,
  });

  final int id;
  final NotificationKind kind;
  final LocalizedName title;
  final String? body;
  final DateTime createdAt;
  final bool isRead;

  /// The in-app location the notification opens.
  final String? route;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: jsonInt(json['Id']) ?? 0,
        kind: NotificationKind.fromWire(json['Kind'] as String?),
        title: LocalizedName(
          json['Title'] as String? ?? '',
          json['TitleBn'] as String? ?? '',
        ),
        body: json['Body'] as String?,
        createdAt: jsonDate(json['CreatedAt']) ?? DateTime(2000),
        isRead: jsonBool(json['IsRead']),
        route: json['Route'] as String?,
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
    route: route,
  );
}
