import '../../core/storage.dart';
import '../api/api_client.dart';
import '../models/notification.dart';

/// Server-backed notifications with a synchronous in-memory cache.
class NotificationRepository {
  NotificationRepository(this._storage, this._api) {
    _cache
      ..clear()
      ..addAll(_storage
          .getJsonList(StorageKeys.notifications)
          .map(PFNotification.fromJson));
    _sort();
  }

  final LocalStorage _storage;
  final ApiClient _api;
  final List<PFNotification> _cache = [];

  List<PFNotification> all() => List<PFNotification>.unmodifiable(_cache);

  int unreadCount() => _cache.where((n) => !n.read).length;

  Future<void> pull() async {
    final res = await _api.get('/api/notifications') as List;
    _cache
      ..clear()
      ..addAll(
          res.map((e) => PFNotification.fromJson(e as Map<String, dynamic>)));
    _sort();
    await _save();
  }

  Future<void> add(PFNotification n) async {
    await _api.post('/api/notifications', n.toJson());
    _cache.insert(0, n);
    await _save();
  }

  Future<void> markAllRead() async {
    await _api.patch('/api/notifications/read-all');
    for (var i = 0; i < _cache.length; i++) {
      _cache[i] = _cache[i].copyWith(read: true);
    }
    await _save();
  }

  Future<void> markRead(String id) async {
    await _api.patch('/api/notifications/$id/read');
    final idx = _cache.indexWhere((n) => n.id == id);
    if (idx != -1) _cache[idx] = _cache[idx].copyWith(read: true);
    await _save();
  }

  void _sort() => _cache.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> _save() => _storage.setJsonList(
        StorageKeys.notifications,
        _cache.map((n) => n.toJson()).toList(),
      );
}
