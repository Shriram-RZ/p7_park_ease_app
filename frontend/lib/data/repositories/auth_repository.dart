import 'dart:convert';

import '../../core/storage.dart';
import '../api/api_client.dart';
import '../models/user.dart';

/// Server-backed authentication. Sign-up / sign-in hit the backend and persist
/// the returned bearer token. PIN + biometric remain a device-local app-lock.
class AuthRepository {
  AuthRepository(this._storage, this._api);

  final LocalStorage _storage;
  final ApiClient _api;

  /// Local-only fingerprint for the PIN app-lock (no extra deps).
  static String _hash(String input, [String salt = 'parkflow.v1']) {
    final bytes = utf8.encode('$salt::$input');
    int h1 = 0xcafebabe;
    int h2 = 0xdeadbeef;
    for (final b in bytes) {
      h1 = ((h1 ^ b) * 16777619) & 0xFFFFFFFF;
      h2 = ((h2 + b) * 2166136261) & 0xFFFFFFFF;
    }
    return '${h1.toRadixString(16).padLeft(8, '0')}'
        '${h2.toRadixString(16).padLeft(8, '0')}';
  }

  /// Restore the persisted token into the API client (call on bootstrap).
  String? loadToken() {
    final token = _storage.getString(StorageKeys.authToken);
    _api.token = token;
    return token;
  }

  PFUser? currentUser() {
    final json = _storage.getJson(StorageKeys.currentUser);
    if (json == null) return null;
    try {
      return PFUser.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<PFUser> signUp({
    required String name,
    required String email,
    required String password,
    PFUserRole role = PFUserRole.driver,
  }) async {
    final res = await _api.post('/api/auth/signup', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'role': role.name,
    }) as Map<String, dynamic>;
    return _persistSession(res);
  }

  /// Returns true on success, false on invalid credentials / network failure.
  Future<bool> signIn({required String email, required String password}) async {
    try {
      final res = await _api.post('/api/auth/signin', {
        'email': email.trim().toLowerCase(),
        'password': password,
      }) as Map<String, dynamic>;
      _persistSession(res);
      return true;
    } on ApiException {
      return false;
    }
  }

  PFUser _persistSession(Map<String, dynamic> res) {
    final token = res['token'] as String;
    final user = PFUser.fromJson(res['user'] as Map<String, dynamic>);
    _api.token = token;
    _storage.setString(StorageKeys.authToken, token);
    _storage.setJson(StorageKeys.currentUser, user.toJson());
    return user;
  }

  Future<void> signOut() async {
    _api.token = null;
    await _storage.remove(StorageKeys.authToken);
    await _storage.remove(StorageKeys.currentUser);
    await _storage.remove(StorageKeys.pinHash);
  }

  // ---- Device-local PIN + biometric (app-lock, not server auth) ----
  Future<void> setPin(String pin) async {
    await _storage.setString(StorageKeys.pinHash, _hash(pin, 'pf.pin'));
  }

  bool hasPin() => _storage.getString(StorageKeys.pinHash) != null;

  bool verifyPin(String pin) {
    final stored = _storage.getString(StorageKeys.pinHash);
    if (stored == null) return false;
    return stored == _hash(pin, 'pf.pin');
  }

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.setBool(StorageKeys.biometricEnabled, enabled);

  bool biometricEnabled() =>
      _storage.getBool(StorageKeys.biometricEnabled, defaultValue: false);
}
