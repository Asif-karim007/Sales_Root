import 'package:salesroot/core/utils/json_fields.dart';

enum NotificationKind {
  reminder('reminder'),
  taskDue('taskdue'),
  newLead('newlead'),
  mention('mention'),
  assigned('assigned'),
  approval('approval'),
  notice('notice'),
  billing('billing');

  const NotificationKind(this.wire);

  final String wire;

  /// Matches `task_due`, `taskDue` and `task.due` alike.
  static NotificationKind fromWire(String? value) {
    final key = value?.toLowerCase().replaceAll(RegExp('[^a-z]'), '');
    return values.firstWhere(
      (kind) => kind.wire == key,
      orElse: () => NotificationKind.notice,
    );
  }
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

  final String id;
  final NotificationKind kind;
  final LocalizedName title;
  final LocalizedName? body;
  final DateTime createdAt;
  final bool isRead;

  /// The in-app location the notification opens.
  final String? route;

  /// One of `GET notifications` items. Texts come as a `{en, bn}` object or
  /// as `titleEn`/`titleBn`; read ones carry `readAt`.
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final body = _text(json, 'body');
    return AppNotification(
      id: jsonId(json['id']) ?? '',
      kind: NotificationKind.fromWire(
        (json['type'] ?? json['kind']) as String?,
      ),
      title: _text(json, 'title'),
      body: body.en.isEmpty && body.bn.isEmpty ? null : body,
      createdAt: jsonDate(json['createdAt']) ?? DateTime(2000),
      isRead: json['readAt'] != null || jsonBool(json['isRead']),
      route: json['route'] as String?,
    );
  }

  static LocalizedName _text(Map<String, dynamic> json, String key) =>
      json[key] is Map
      ? LocalizedName.of(json[key])
      : LocalizedName.pair(json, key);

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
