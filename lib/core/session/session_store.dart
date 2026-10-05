import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/session/auth_session.dart';

part 'session_store.g.dart';

class SessionStore {
  const SessionStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _sessionKey = 'session';
  static const _pinKey = 'pin_hash';

  Future<AuthSession?> read() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null) return null;
    final json = jsonDecode(raw);
    return json is Map<String, dynamic> ? AuthSession.fromJson(json) : null;
  }

  Future<void> write(AuthSession session) =>
      _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));

  Future<void> clear() async {
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _pinKey);
  }

  Future<bool> hasPin() async => await _storage.read(key: _pinKey) != null;

  Future<void> writePin(String pin, String userId) =>
      _storage.write(key: _pinKey, value: _hash(pin, userId));

  Future<bool> checkPin(String pin, String userId) async =>
      await _storage.read(key: _pinKey) == _hash(pin, userId);

  static String _hash(String pin, String userId) =>
      sha256.convert(utf8.encode('salesroot:$userId:$pin')).toString();
}

@Riverpod(keepAlive: true)
SessionStore sessionStore(Ref ref) =>
    const SessionStore(FlutterSecureStorage());
