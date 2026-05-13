import '../../core/storage.dart';
import '../models/notification.dart';

class NotificationRepository {
  NotificationRepository(this._storage);
  final LocalStorage _storage;

  List<PFNotification> all() => _storage
      .getJsonList(StorageKeys.notifications)
      .map(PFNotification.fromJson)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int unreadCount() => all().where((n) => !n.read).length;

  Future<void> add(PFNotification n) async {
    final list = all()..insert(0, n);
    await _storage.setJsonList(
      StorageKeys.notifications,
      list.map((n) => n.toJson()).toList(),
    );
  }

  Future<void> markAllRead() async {
    final list = all().map((n) => n.copyWith(read: true)).toList();
    await _storage.setJsonList(
      StorageKeys.notifications,
      list.map((n) => n.toJson()).toList(),
    );
  }

  Future<void> markRead(String id) async {
    final list = all();
    final idx = list.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    list[idx] = list[idx].copyWith(read: true);
    await _storage.setJsonList(
      StorageKeys.notifications,
      list.map((n) => n.toJson()).toList(),
    );
  }

  Future<void> seedIfEmpty() async {
    if (all().isNotEmpty) return;
    final now = DateTime.now();
    final seeds = <PFNotification>[
      PFNotification(
        id: 'n1',
        title: 'Welcome to ParkFlow',
        body: 'Your smart offline parking ecosystem is ready.',
        type: PFNotificationType.system,
        createdAt: now,
      ),
      PFNotification(
        id: 'n2',
        title: 'Slot recommendation ready',
        body: 'Level B2 has 14 available slots near the elevator.',
        type: PFNotificationType.navigation,
        createdAt: now.subtract(const Duration(minutes: 12)),
      ),
    ];
    for (final n in seeds) {
      await add(n);
    }
  }
}
