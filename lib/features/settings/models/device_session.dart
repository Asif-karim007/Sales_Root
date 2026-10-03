import 'package:salesroot/core/utils/json_fields.dart';

enum DeviceKind {
  android('Android'),
  ios('iOS'),
  web('Web');

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
    required this.location,
    required this.isCurrent,
    this.lastActiveAt,
  });

  final int id;
  final String name;
  final DeviceKind kind;
  final String location;
  final bool isCurrent;
  final DateTime? lastActiveAt;

  factory DeviceSession.fromJson(Map<String, dynamic> json) => DeviceSession(
    id: jsonInt(json['Id']) ?? 0,
    name: json['Name'] as String? ?? '',
    kind: DeviceKind.fromWire(json['Kind'] as String?),
    location: json['Location'] as String? ?? '',
    isCurrent: jsonBool(json['IsCurrent']),
    lastActiveAt: jsonDate(json['LastActiveAt']),
  );
}

enum LoginMethod {
  pin('Pin'),
  face('Face'),
  fingerprint('Fingerprint'),
  otp('Otp'),
  passwordOtp('PasswordOtp');

  const LoginMethod(this.wire);

  final String wire;

  static LoginMethod fromWire(String? value) =>
      values.firstWhere((m) => m.wire == value, orElse: () => LoginMethod.otp);
}

/// One sign-in on the account.
class LoginEvent {
  const LoginEvent({
    required this.id,
    required this.device,
    required this.method,
    this.at,
  });

  final int id;
  final String device;
  final LoginMethod method;
  final DateTime? at;

  factory LoginEvent.fromJson(Map<String, dynamic> json) => LoginEvent(
    id: jsonInt(json['Id']) ?? 0,
    device: json['Device'] as String? ?? '',
    method: LoginMethod.fromWire(json['Method'] as String?),
    at: jsonDate(json['At']),
  );
}
