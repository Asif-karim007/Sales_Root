import 'package:salesroot/core/utils/json_fields.dart';

enum DeviceKind {
  android('android'),
  ios('ios'),
  web('web');

  const DeviceKind(this.wire);

  final String wire;

  static DeviceKind fromWire(String? value) =>
      values.firstWhere((k) => k.wire == value, orElse: () => DeviceKind.web);
}

/// A device signed in to the account.
class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.name,
    required this.kind,
    this.appVersion,
    this.signedInAt,
    this.lastActiveAt,
  });

  final String id;
  final String name;
  final DeviceKind kind;
  final String? appVersion;
  final DateTime? signedInAt;
  final DateTime? lastActiveAt;

  factory DeviceSession.fromJson(Map<String, dynamic> json) => DeviceSession(
    id: jsonId(json['id']) ?? '',
    name: json['deviceName'] as String? ?? '',
    kind: DeviceKind.fromWire(json['platform'] as String?),
    appVersion: json['appVersion'] as String?,
    signedInAt: jsonDate(json['createdAt']),
    lastActiveAt: jsonDate(json['lastUsedAt']),
  );
}
