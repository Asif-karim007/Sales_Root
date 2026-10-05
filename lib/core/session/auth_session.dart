import 'package:salesroot/core/utils/json_fields.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.name,
    this.refreshToken,
    this.workspaceId,
    this.phone,
    this.email,
    this.photoUrl,
    this.hasPin = false,
    this.expiresAt,
  });

  final String token;
  final String? refreshToken;
  final String userId;
  final String name;

  /// The workspace the token is scoped to.
  final String? workspaceId;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final bool hasPin;
  final DateTime? expiresAt;

  /// The `{accessToken, refreshToken, accessExpiresAt, me}` body that sign-in,
  /// refresh and workspace switch return.
  factory AuthSession.fromTokens(Map<String, dynamic> json) {
    final me = jsonMap(json['me']);
    return AuthSession(
      token: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String?,
      expiresAt: jsonDate(json['accessExpiresAt']),
      userId: jsonId(me['userId']) ?? '',
      name: me['name'] as String? ?? '',
      workspaceId: jsonId(me['workspaceId']),
      phone: me['phone'] as String?,
      email: me['email'] as String?,
      photoUrl: me['photoUrl'] as String?,
      hasPin: jsonBool(me['hasPin']),
    );
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    token: json['token'] as String? ?? '',
    refreshToken: json['refreshToken'] as String?,
    userId: jsonId(json['userId']) ?? '',
    name: json['name'] as String? ?? '',
    workspaceId: jsonId(json['workspaceId']),
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    photoUrl: json['photoUrl'] as String?,
    hasPin: jsonBool(json['hasPin']),
    expiresAt: jsonDate(json['expiresAt']),
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'refreshToken': refreshToken,
    'userId': userId,
    'name': name,
    'workspaceId': workspaceId,
    'phone': phone,
    'email': email,
    'photoUrl': photoUrl,
    'hasPin': hasPin,
    'expiresAt': jsonUtc(expiresAt),
  }..removeWhere((_, value) => value == null);

  AuthSession copyWith({
    String? name,
    String? email,
    String? photoUrl,
    bool? hasPin,
  }) => AuthSession(
    token: token,
    refreshToken: refreshToken,
    userId: userId,
    name: name ?? this.name,
    workspaceId: workspaceId,
    phone: phone,
    email: email ?? this.email,
    photoUrl: photoUrl ?? this.photoUrl,
    hasPin: hasPin ?? this.hasPin,
    expiresAt: expiresAt,
  );
}
