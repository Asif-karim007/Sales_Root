import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/utils/json_fields.dart';

/// A kind of push notification. [module] hides the switch from users who
/// can't see that module.
enum NotificationTopic {
  reminders('Reminders', AppModule.task),
  assignments('Assignments', AppModule.lead),
  chat('Chat', AppModule.chat),
  newLeads('NewLeads', AppModule.inbox),
  inbox('Inbox', AppModule.inbox),
  approvals('Approvals', AppModule.approvals),
  notices('Notices', AppModule.notice),
  billing('Billing', AppModule.billing),
  academy('Academy', null);

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

  bool isOn(NotificationTopic topic) => topics.contains(topic);

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) =>
      NotificationPrefs(
        topics: {
          for (final wire in jsonStrings(json['Topics']))
            ?NotificationTopic.fromWire(wire),
        },
        digestMinute: jsonInt(json['DigestMinute']) ?? 9 * 60,
        quietEnabled: jsonBool(json['QuietEnabled']),
        quietFromMinute: jsonInt(json['QuietFromMinute']) ?? 22 * 60,
        quietToMinute: jsonInt(json['QuietToMinute']) ?? 7 * 60,
      );

  Map<String, dynamic> toJson() => {
    'Topics': [for (final topic in topics) topic.wire],
    'DigestMinute': digestMinute,
    'QuietEnabled': quietEnabled,
    'QuietFromMinute': quietFromMinute,
    'QuietToMinute': quietToMinute,
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
