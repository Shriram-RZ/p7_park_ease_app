import 'dart:math';

import '../../core/storage.dart';
import '../api/api_client.dart';
import '../models/vehicle.dart';

/// Server-backed vehicles with a synchronous in-memory cache (mirrored to local
/// storage for cold-start / offline rendering).
class VehicleRepository {
  VehicleRepository(this._storage, this._api) {
    _cache
      ..clear()
      ..addAll(_storage
          .getJsonList(StorageKeys.vehicles)
          .map(PFVehicle.fromJson));
    _activeId = _storage.getString(StorageKeys.activeVehicleId);
  }

  final LocalStorage _storage;
  final ApiClient _api;
  final List<PFVehicle> _cache = [];
  String? _activeId;

  List<PFVehicle> all() => List<PFVehicle>.unmodifiable(_cache);

  String? activeVehicleId() => _activeId;

  PFVehicle? activeVehicle() {
    if (_cache.isEmpty) return null;
    if (_activeId == null) return _cache.first;
    return _cache.cast<PFVehicle?>().firstWhere(
          (v) => v?.id == _activeId,
          orElse: () => _cache.first,
        );
  }

  /// Fetch the server's vehicles into the cache.
  Future<void> pull() async {
    final res = await _api.get('/api/vehicles') as Map<String, dynamic>;
    final items = (res['items'] as List)
        .map((e) => PFVehicle.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache
      ..clear()
      ..addAll(items);
    _activeId = res['activeVehicleId'] as String?;
    await _save();
  }

  Future<void> setActive(String id) async {
    await _api.put('/api/vehicles/active', {'id': id});
    _activeId = id;
    await _storage.setString(StorageKeys.activeVehicleId, id);
  }

  Future<void> add(PFVehicle vehicle) async {
    await _api.post('/api/vehicles', vehicle.toJson());
    _cache.add(vehicle);
    _activeId ??= vehicle.id;
    await _save();
  }

  Future<void> update(PFVehicle vehicle) async {
    await _api.put('/api/vehicles/${vehicle.id}', vehicle.toJson());
    final idx = _cache.indexWhere((v) => v.id == vehicle.id);
    if (idx != -1) _cache[idx] = vehicle;
    await _save();
  }

  Future<void> remove(String id) async {
    final res = await _api.delete('/api/vehicles/$id');
    _cache.removeWhere((v) => v.id == id);
    if (res is Map && res.containsKey('activeVehicleId')) {
      _activeId = res['activeVehicleId'] as String?;
    } else if (_activeId == id) {
      _activeId = _cache.isNotEmpty ? _cache.first.id : null;
    }
    await _save();
  }

  /// Seed two sample vehicles for a brand-new account so the booking flow has
  /// an active vehicle to use.
  Future<void> seedIfEmpty() async {
    if (_cache.isNotEmpty) return;
    final rng = Random(7);
    final seeds = <PFVehicle>[
      PFVehicle(
        id: 'v_${rng.nextInt(99999)}_a',
        name: 'Aurora EV',
        plate: 'PF · 2042',
        type: VehicleType.ev,
        colorValue: 0xFF22C55E,
        notes: 'Daily driver',
        isFavorite: true,
      ),
      PFVehicle(
        id: 'v_${rng.nextInt(99999)}_b',
        name: 'Stratos Coupe',
        plate: 'NX · 7781',
        type: VehicleType.car,
        colorValue: 0xFF0EA5E9,
        notes: 'Weekend ride',
      ),
    ];
    for (final v in seeds) {
      await add(v);
    }
    await setActive(seeds.first.id);
  }

  Future<void> _save() async {
    await _storage.setJsonList(
      StorageKeys.vehicles,
      _cache.map((v) => v.toJson()).toList(),
    );
    if (_activeId != null) {
      await _storage.setString(StorageKeys.activeVehicleId, _activeId!);
    }
  }
}
