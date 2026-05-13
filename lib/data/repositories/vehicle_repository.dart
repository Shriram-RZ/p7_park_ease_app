import 'dart:math';

import '../../core/storage.dart';
import '../models/vehicle.dart';

class VehicleRepository {
  VehicleRepository(this._storage);
  final LocalStorage _storage;

  List<PFVehicle> all() => _storage
      .getJsonList(StorageKeys.vehicles)
      .map(PFVehicle.fromJson)
      .toList();

  String? activeVehicleId() => _storage.getString(StorageKeys.activeVehicleId);

  PFVehicle? activeVehicle() {
    final id = activeVehicleId();
    final list = all();
    if (id == null) return list.isNotEmpty ? list.first : null;
    return list.cast<PFVehicle?>().firstWhere(
          (v) => v?.id == id,
          orElse: () => list.isNotEmpty ? list.first : null,
        );
  }

  Future<void> setActive(String id) =>
      _storage.setString(StorageKeys.activeVehicleId, id);

  Future<void> add(PFVehicle vehicle) async {
    final list = all()..add(vehicle);
    await _storage.setJsonList(
      StorageKeys.vehicles,
      list.map((v) => v.toJson()).toList(),
    );
    if (activeVehicleId() == null) {
      await setActive(vehicle.id);
    }
  }

  Future<void> update(PFVehicle vehicle) async {
    final list = all();
    final idx = list.indexWhere((v) => v.id == vehicle.id);
    if (idx == -1) return;
    list[idx] = vehicle;
    await _storage.setJsonList(
      StorageKeys.vehicles,
      list.map((v) => v.toJson()).toList(),
    );
  }

  Future<void> remove(String id) async {
    final list = all()..removeWhere((v) => v.id == id);
    await _storage.setJsonList(
      StorageKeys.vehicles,
      list.map((v) => v.toJson()).toList(),
    );
    if (activeVehicleId() == id) {
      if (list.isNotEmpty) {
        await setActive(list.first.id);
      } else {
        await _storage.remove(StorageKeys.activeVehicleId);
      }
    }
  }

  /// Seed sample vehicles on first launch so the dashboard never feels empty.
  Future<void> seedIfEmpty() async {
    if (all().isNotEmpty) return;
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
}
