import '../../core/storage.dart';
import '../api/api_client.dart';
import '../models/ticket.dart';

/// Server-backed tickets with a synchronous in-memory cache.
class TicketRepository {
  TicketRepository(this._storage, this._api) {
    _cache
      ..clear()
      ..addAll(_storage
          .getJsonList(StorageKeys.tickets)
          .map(PFTicket.fromJson));
    _sort();
  }

  final LocalStorage _storage;
  final ApiClient _api;
  final List<PFTicket> _cache = [];

  List<PFTicket> all() => List<PFTicket>.unmodifiable(_cache);

  PFTicket? byBookingId(String bookingId) {
    for (final t in _cache) {
      if (t.bookingId == bookingId) return t;
    }
    return null;
  }

  Future<void> pull() async {
    final res = await _api.get('/api/tickets') as List;
    _cache
      ..clear()
      ..addAll(res.map((e) => PFTicket.fromJson(e as Map<String, dynamic>)));
    _sort();
    await _save();
  }

  Future<void> add(PFTicket ticket) async {
    await _api.post('/api/tickets', ticket.toJson());
    _cache.insert(0, ticket);
    await _save();
  }

  Future<void> update(PFTicket ticket) async {
    await _api.patch('/api/tickets/${ticket.id}', ticket.toJson());
    final idx = _cache.indexWhere((t) => t.id == ticket.id);
    if (idx != -1) _cache[idx] = ticket;
    await _save();
  }

  /// Validate a scanned QR server-side (works across users for operators).
  /// Returns the result string and the matched ticket (if any), and refreshes
  /// the local cache when the ticket belongs to this device.
  Future<({String result, PFTicket? ticket})> validate(String code) async {
    final res = await _api.post('/api/tickets/validate', {'code': code})
        as Map<String, dynamic>;
    final ticketJson = res['ticket'];
    PFTicket? ticket;
    if (ticketJson is Map<String, dynamic>) {
      ticket = PFTicket.fromJson(ticketJson);
      final idx = _cache.indexWhere((t) => t.id == ticket!.id);
      if (idx != -1) {
        _cache[idx] = ticket;
        await _save();
      }
    }
    return (result: res['result'] as String, ticket: ticket);
  }

  void _sort() => _cache.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));

  Future<void> _save() => _storage.setJsonList(
        StorageKeys.tickets,
        _cache.map((t) => t.toJson()).toList(),
      );
}
