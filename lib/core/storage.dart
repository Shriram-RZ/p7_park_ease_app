import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight key/value JSON-backed storage on top of SharedPreferences.
/// All persistence in ParkFlow is offline — no remote services.
class LocalStorage {
  LocalStorage._(this._prefs);

  static LocalStorage? _instance;
  final SharedPreferences _prefs;

  static Future<LocalStorage> instance() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = LocalStorage._(prefs);
    return _instance!;
  }

  // Primitive helpers.
  String? getString(String key) => _prefs.getString(key);
  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;
  int getInt(String key, {int defaultValue = 0}) =>
      _prefs.getInt(key) ?? defaultValue;

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
  Future<void> remove(String key) => _prefs.remove(key);

  // JSON-backed object/list helpers.
  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> setJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  List<Map<String, dynamic>> getJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .toList(growable: true);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> setJsonList(String key, List<Map<String, dynamic>> list) =>
      _prefs.setString(key, jsonEncode(list));
}

/// Centralised storage keys to avoid typos.
class StorageKeys {
  StorageKeys._();
  static const String onboardingComplete = 'pf.onboarding_complete';
  static const String currentUser = 'pf.user';
  static const String pinHash = 'pf.pin_hash';
  static const String biometricEnabled = 'pf.biometric_enabled';
  static const String themeMode = 'pf.theme_mode';
  static const String accentSeed = 'pf.accent_seed';
  static const String vehicles = 'pf.vehicles';
  static const String activeVehicleId = 'pf.active_vehicle_id';
  static const String bookings = 'pf.bookings';
  static const String tickets = 'pf.tickets';
  static const String notifications = 'pf.notifications';
  static const String parkingLayout = 'pf.parking_layout';
  static const String simulationSeed = 'pf.simulation_seed';
  static const String reduceMotion = 'pf.reduce_motion';
  static const String language = 'pf.language';
}
