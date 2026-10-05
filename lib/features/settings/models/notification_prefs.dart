import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/utils/json_fields.dart';

/// A kind of push notification. [module] hides the switch from users who
/// can't see that module.
enum NotificationTopic {
  reminders('reminders', AppModule.task),
  assignments('assignments', AppModule.lead),
  chat('chat', AppModule.chat),
  newLeads('newLeads', AppModule.inbox),
  inbox('inbox', AppModule.inbox),
  approvals('approvals', AppModule.approvals),
  notices('notices', AppModule.notice),
  billing('billing', AppModule.billing),
  academy('academy', null);

  const NotificationTopic(this.wire, this.module);

  final String wire;
  final AppModule? module;

  static NotificationTopic? fromWire(String? value) {
    for (final topic in values) {
      if (topic.wire == value) return topic;
    }
    return null;
  }
}

/// Kept on the phone: the server has no notification settings yet.
class NotificationPrefs {
  const NotificationPrefs({
    required this.topics,
    required this.digestMinute,
    required this.quietEnabled,
    required this.quietFromMinute,
    required this.quietToMinute,
  });

  /// The topics that are switched on.
  final Set<NotificationTopic> topics;

  /// Minutes after midnight.
  final int digestMinute;
  final bool quietEnabled;
  final int quietFromMinute;
  final int quietToMinute;

  static const defaults = NotificationPrefs(
    topics: {
      NotificationTopic.reminders,
      NotificationTopic.assignments,
      NotificationTopic.chat,
      NotificationTopic.newLeads,
      NotificationTopic.inbox,
      NotificationTopic.notices,
      NotificationTopic.billing,
    },
    digestMinute: 9 * 60,
    quietEnabled: true,
    quietFromMinute: 22 * 60,
    quietToMinute: 7 * 60,
  );

  bool isOn(NotificationTopic topic) => topics.contains(topic);

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) =>
      NotificationPrefs(
        topics: {
          for (final wire in jsonStrings(json['topics']))
            ?NotificationTopic.fromWire(wire),
        },
        digestMinute: jsonInt(json['digestMinute']) ?? defaults.digestMinute,
        quietEnabled: jsonBool(json['quietEnabled']),
        quietFromMinute:
            jsonInt(json['quietFromMinute']) ?? defaults.quietFromMinute,
        quietToMinute: jsonInt(json['quietToMinute']) ?? defaults.quietToMinute,
      );

  Map<String, dynamic> toJson() => {
    'topics': [for (final topic in topics) topic.wire],
    'digestMinute': digestMinute,
    'quietEnabled': quietEnabled,
    'quietFromMinute': quietFromMinute,
    'quietToMinute': quietToMinute,
  };

  NotificationPrefs copyWith({
    Set<NotificationTopic>? topics,
    int? digestMinute,
    bool? quietEnabled,
    int? quietFromMinute,
    int? quietToMinute,
  }) => NotificationPrefs(
    topics: topics ?? this.topics,
    digestMinute: digestMinute ?? this.digestMinute,
    quietEnabled: quietEnabled ?? this.quietEnabled,
    quietFromMinute: quietFromMinute ?? this.quietFromMinute,
    quietToMinute: quietToMinute ?? this.quietToMinute,
  );

  NotificationPrefs toggle(NotificationTopic topic, bool on) =>
      copyWith(topics: on ? {...topics, topic} : ({...topics}..remove(topic)));
}
