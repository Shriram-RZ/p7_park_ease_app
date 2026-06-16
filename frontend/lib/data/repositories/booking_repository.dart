import '../../core/storage.dart';
import '../api/api_client.dart';
import '../models/booking.dart';

/// Server-backed bookings with a synchronous in-memory cache.
class BookingRepository {
  BookingRepository(this._storage, this._api) {
    _cache
      ..clear()
      ..addAll(_storage
          .getJsonList(StorageKeys.bookings)
          .map(PFBooking.fromJson));
    _sort();
  }

  final LocalStorage _storage;
  final ApiClient _api;
  final List<PFBooking> _cache = [];

  List<PFBooking> all() => List<PFBooking>.unmodifiable(_cache);

  PFBooking? activeBooking() {
    final now = DateTime.now();
    for (final b in _cache) {
      if (b.status == BookingStatus.upcoming ||
          b.status == BookingStatus.active) {
        if (b.endTime.isAfter(now)) return b;
      }
    }
    return null;
  }

  Future<void> pull() async {
    final res = await _api.get('/api/bookings') as List;
    _cache
      ..clear()
      ..addAll(res.map((e) => PFBooking.fromJson(e as Map<String, dynamic>)));
    _sort();
    await _save();
  }

  Future<void> add(PFBooking booking) async {
    await _api.post('/api/bookings', booking.toJson());
    _cache.insert(0, booking);
    await _save();
  }

  Future<void> update(PFBooking booking) async {
    await _api.patch('/api/bookings/${booking.id}', booking.toJson());
    final idx = _cache.indexWhere((b) => b.id == booking.id);
    if (idx != -1) _cache[idx] = booking;
    await _save();
  }

  void _sort() => _cache.sort((a, b) => b.startTime.compareTo(a.startTime));

  Future<void> _save() => _storage.setJsonList(
        StorageKeys.bookings,
        _cache.map((b) => b.toJson()).toList(),
      );
}
