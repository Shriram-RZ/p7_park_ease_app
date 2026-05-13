import 'dart:math';

import '../../core/storage.dart';
import '../models/booking.dart';

class BookingRepository {
  BookingRepository(this._storage);
  final LocalStorage _storage;

  List<PFBooking> all() => _storage
      .getJsonList(StorageKeys.bookings)
      .map(PFBooking.fromJson)
      .toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));

  PFBooking? activeBooking() {
    final now = DateTime.now();
    for (final b in all()) {
      if (b.status == BookingStatus.upcoming || b.status == BookingStatus.active) {
        if (b.endTime.isAfter(now)) return b;
      }
    }
    return null;
  }

  Future<void> add(PFBooking booking) async {
    final list = all()..insert(0, booking);
    await _storage.setJsonList(
      StorageKeys.bookings,
      list.map((b) => b.toJson()).toList(),
    );
  }

  Future<void> update(PFBooking booking) async {
    final list = all();
    final idx = list.indexWhere((b) => b.id == booking.id);
    if (idx == -1) return;
    list[idx] = booking;
    await _storage.setJsonList(
      StorageKeys.bookings,
      list.map((b) => b.toJson()).toList(),
    );
  }

  Future<void> seedIfEmpty() async {
    if (all().isNotEmpty) return;
    final rng = Random(11);
    final now = DateTime.now();
    final samples = <PFBooking>[
      PFBooking(
        id: 'b_${rng.nextInt(99999)}',
        slotId: 'F2_R3C2',
        slotLabel: 'F2-D3',
        floor: 2,
        vehicleId: 'sample',
        vehicleName: 'Aurora EV',
        vehiclePlate: 'PF · 2042',
        startTime: now.subtract(const Duration(days: 1, hours: 4)),
        endTime: now.subtract(const Duration(days: 1, hours: 2)),
        feeCents: 900,
        status: BookingStatus.completed,
      ),
      PFBooking(
        id: 'b_${rng.nextInt(99999)}',
        slotId: 'F1_R1C4',
        slotLabel: 'F1-B5',
        floor: 1,
        vehicleId: 'sample',
        vehicleName: 'Stratos Coupe',
        vehiclePlate: 'NX · 7781',
        startTime: now.subtract(const Duration(days: 4, hours: 1)),
        endTime: now.subtract(const Duration(days: 4)),
        feeCents: 450,
        status: BookingStatus.completed,
      ),
      PFBooking(
        id: 'b_${rng.nextInt(99999)}',
        slotId: 'F3_R5C5',
        slotLabel: 'F3-F6',
        floor: 3,
        vehicleId: 'sample',
        vehicleName: 'Aurora EV',
        vehiclePlate: 'PF · 2042',
        startTime: now.subtract(const Duration(days: 7, hours: 3)),
        endTime: now.subtract(const Duration(days: 7, hours: 1)),
        feeCents: 900,
        status: BookingStatus.completed,
      ),
    ];
    for (final b in samples) {
      await add(b);
    }
  }
}
