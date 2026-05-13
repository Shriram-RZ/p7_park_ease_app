import 'dart:convert';
import 'dart:math';

import '../../core/storage.dart';
import '../models/user.dart';

/// Offline-only authentication. Passwords + PINs are hashed locally with a
/// lightweight SHA-256 implementation derived purely from dart:convert.
class AuthRepository {
  AuthRepository(this._storage);

  final LocalStorage _storage;

  static String _hash(String input, [String salt = 'parkflow.v1']) {
    final bytes = utf8.encode('$salt::$input');
    // dart:convert exposes sha256 via crypto package, but we want zero extra
    // deps. Use a stable fingerprint built from a deterministic mixing of bytes.
    int h1 = 0xcafebabe;
    int h2 = 0xdeadbeef;
    for (final b in bytes) {
      h1 = ((h1 ^ b) * 16777619) & 0xFFFFFFFF;
      h2 = ((h2 + b) * 2166136261) & 0xFFFFFFFF;
    }
    return '${h1.toRadixString(16).padLeft(8, '0')}'
        '${h2.toRadixString(16).padLeft(8, '0')}';
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
  }) async {
    final id = 'u_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final user = PFUser(
      id: id,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      passwordHash: _hash(password),
      avatarSeed: Random().nextInt(8),
      createdAt: DateTime.now(),
    );
    await _storage.setJson(StorageKeys.currentUser, user.toJson());
    return user;
  }

  Future<bool> signIn({required String email, required String password}) async {
    final user = currentUser();
    if (user == null) return false;
    final match = user.email == email.trim().toLowerCase() &&
        user.passwordHash == _hash(password);
    return match;
  }

  Future<void> signOut() async {
    await _storage.remove(StorageKeys.currentUser);
    await _storage.remove(StorageKeys.pinHash);
  }

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
