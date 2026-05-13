import 'dart:async';
import 'dart:math';
import 'dart:ui' show VoidCallback;

import '../../core/constants.dart';
import '../models/parking_slot.dart';
import '../repositories/parking_repository.dart';

/// Periodically mutates slot statuses to simulate "real-time" parking activity
/// while completely offline. Listeners receive a tick whenever the state
/// changes so the parking map and dashboard can animate.
class SimulationService {
  SimulationService(this._parking);

  final ParkingRepository _parking;
  final Random _rng = Random();
  Timer? _timer;
  final List<VoidCallback> _listeners = [];
  bool _peakMode = false;

  bool get peakMode => _peakMode;
  set peakMode(bool value) {
    _peakMode = value;
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(PFConstants.simulationTick, (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);

  void _emit() {
    for (final cb in List.of(_listeners)) {
      cb();
    }
  }

  /// Manually trigger a tick (used after reservations to recompute analytics).
  void pulse() => _emit();

  void _tick() {
    final slots = _parking.all();
    final hour = DateTime.now().hour;
    final pressure = _peakMode
        ? 0.55
        : (hour >= 8 && hour <= 10) || (hour >= 17 && hour <= 19)
            ? 0.42
            : 0.22;

    final candidates = <PFSlot>[];
    candidates.addAll(slots);
    candidates.shuffle(_rng);
    final toMutate = candidates.take(3 + _rng.nextInt(4));

    for (final s in toMutate) {
      if (s.status == SlotStatus.disabled) continue;
      final r = _rng.nextDouble();
      switch (s.status) {
        case SlotStatus.available:
          if (r < pressure) _parking.occupy(s.id);
          break;
        case SlotStatus.occupied:
          if (r < pressure * 0.7) _parking.free(s.id);
          break;
        case SlotStatus.reserved:
          if (r < 0.15) _parking.occupy(s.id);
          break;
        case SlotStatus.selected:
        case SlotStatus.disabled:
          break;
      }
    }
    _emit();
  }
}
