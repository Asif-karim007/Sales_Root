import 'package:salesroot/core/utils/json_fields.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.name,
    this.phone,
    this.email,
    this.expiresAt,
  });

  final String token;
  final int userId;
  final String name;
  final String? phone;
  final String? email;
  final DateTime? expiresAt;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    token: json['Token'] as String? ?? '',
    userId: jsonInt(json['UserId']) ?? 0,
    name: json['Name'] as String? ?? '',
    phone: json['Phone'] as String?,
    email: json['Email'] as String?,
    expiresAt: jsonDate(json['ExpiresAt']),
  );

  Map<String, dynamic> toJson() => {
    'Token': token,
    'UserId': userId,
    'Name': name,
    'Phone': phone,
    'Email': email,
    'ExpiresAt': jsonUtc(expiresAt),
  }..removeWhere((_, value) => value == null);

  AuthSession copyWith({String? name, String? email}) => AuthSession(
    token: token,
    userId: userId,
    name: name ?? this.name,
    phone: phone,
    email: email ?? this.email,
    expiresAt: expiresAt,
  );
}
