import 'dart:math';

import '../../core/constants.dart';
import '../../core/storage.dart';
import '../api/api_client.dart';
import '../models/parking_slot.dart';

/// Server-owned parking layout with a synchronous in-memory cache. Reservations
/// sync to the backend; the local simulation (if enabled) only nudges the cache
/// for visual liveliness.
class ParkingRepository {
  ParkingRepository(this._storage, this._api) {
    _ensureLayout();
  }

  final LocalStorage _storage;
  final ApiClient _api;
  final List<PFSlot> _slots = <PFSlot>[];

  List<PFSlot> all() => List<PFSlot>.unmodifiable(_slots);

  List<PFSlot> byFloor(int floor) =>
      _slots.where((s) => s.floor == floor).toList(growable: false);

  PFSlot? byId(String id) {
    for (final s in _slots) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Fetch the shared garage layout from the backend.
  Future<void> pull() async {
    final res = await _api.get('/api/slots') as List;
    _slots
      ..clear()
      ..addAll(res.map((e) => PFSlot.fromJson(e as Map<String, dynamic>)));
    _persist();
  }

  /// Local-only status change (used by the simulation; no server write).
  void updateStatus(String id, SlotStatus status) {
    final idx = _slots.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    _slots[idx] = _slots[idx].copyWith(status: status);
    _persist();
  }

  /// Real, server-backed status changes.
  Future<void> reserve(String id) => _setStatus(id, SlotStatus.reserved);
  Future<void> free(String id) => _setStatus(id, SlotStatus.available);

  Future<void> _setStatus(String id, SlotStatus status) async {
    await _api.patch('/api/slots/$id/status', {'status': status.name});
    updateStatus(id, status);
  }

  Map<int, ({int total, int free, int taken, int reserved})> stats() {
    final out = <int, ({int total, int free, int taken, int reserved})>{};
    for (int f = 1; f <= PFConstants.floorsCount; f++) {
      final floor = byFloor(f);
      out[f] = (
        total: floor.length,
        free: floor.where((s) => s.status == SlotStatus.available).length,
        taken: floor.where((s) => s.status == SlotStatus.occupied).length,
        reserved: floor.where((s) => s.status == SlotStatus.reserved).length,
      );
    }
    return out;
  }

  ({int total, int free, int taken, int reserved}) totalStats() {
    int total = 0, free = 0, taken = 0, reserved = 0;
    for (final s in _slots) {
      total++;
      switch (s.status) {
        case SlotStatus.available:
          free++;
          break;
        case SlotStatus.occupied:
          taken++;
          break;
        case SlotStatus.reserved:
          reserved++;
          break;
        case SlotStatus.selected:
        case SlotStatus.disabled:
          break;
      }
    }
    return (total: total, free: free, taken: taken, reserved: reserved);
  }

  void _ensureLayout() {
    final saved = _storage.getJsonList(StorageKeys.parkingLayout);
    if (saved.isNotEmpty) {
      _slots
        ..clear()
        ..addAll(saved.map(PFSlot.fromJson));
      return;
    }
    // Offline fallback layout until the first server pull replaces it.
    _slots
      ..clear()
      ..addAll(_generate());
    _persist();
  }

  List<PFSlot> _generate() {
    final rng = Random(42);
    final List<PFSlot> out = [];
    const int side = 6; // 6x6 = 36 slots per floor
    for (int f = 1; f <= PFConstants.floorsCount; f++) {
      for (int r = 0; r < side; r++) {
        for (int c = 0; c < side; c++) {
          final id = 'F${f}_R${r}C$c';
          final roll = rng.nextDouble();
          SlotStatus status;
          if (roll < 0.35) {
            status = SlotStatus.occupied;
          } else if (roll < 0.45) {
            status = SlotStatus.reserved;
          } else if (roll < 0.48) {
            status = SlotStatus.disabled;
          } else {
            status = SlotStatus.available;
          }
          final label = 'F$f-${String.fromCharCode(65 + r)}${c + 1}';
          out.add(PFSlot(
            id: id,
            floor: f,
            row: r,
            col: c,
            label: label,
            status: status,
            size: c == 0 || c == side - 1 ? SlotSize.large : SlotSize.standard,
            hasCharger: rng.nextDouble() < 0.18,
            disabledAccess: rng.nextDouble() < 0.07,
            walkingDistance: 30 + rng.nextInt(180),
            score: 0.55 + rng.nextDouble() * 0.45,
          ));
        }
      }
    }
    return out;
  }

  void _persist() {
    _storage.setJsonList(
      StorageKeys.parkingLayout,
      _slots.map((s) => s.toJson()).toList(),
    );
  }
}
