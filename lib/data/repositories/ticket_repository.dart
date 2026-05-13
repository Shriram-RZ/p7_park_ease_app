import '../../core/storage.dart';
import '../models/ticket.dart';

class TicketRepository {
  TicketRepository(this._storage);
  final LocalStorage _storage;

  List<PFTicket> all() => _storage
      .getJsonList(StorageKeys.tickets)
      .map(PFTicket.fromJson)
      .toList()
    ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));

  PFTicket? byBookingId(String bookingId) {
    for (final t in all()) {
      if (t.bookingId == bookingId) return t;
    }
    return null;
  }

  Future<void> add(PFTicket ticket) async {
    final list = all()..insert(0, ticket);
    await _storage.setJsonList(
      StorageKeys.tickets,
      list.map((t) => t.toJson()).toList(),
    );
  }

  Future<void> update(PFTicket ticket) async {
    final list = all();
    final idx = list.indexWhere((t) => t.id == ticket.id);
    if (idx == -1) return;
    list[idx] = ticket;
    await _storage.setJsonList(
      StorageKeys.tickets,
      list.map((t) => t.toJson()).toList(),
    );
  }
}
