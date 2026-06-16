import '../../core/storage.dart';
import '../api/api_client.dart';
import '../models/scan_event.dart';

/// Server-backed operator scan history with a synchronous in-memory cache.
class ScanRepository {
  ScanRepository(this._storage, this._api) {
    _cache
      ..clear()
      ..addAll(_storage
          .getJsonList(StorageKeys.scanHistory)
          .map(PFScanEvent.fromJson));
    _sort();
  }

  final LocalStorage _storage;
  final ApiClient _api;
  final List<PFScanEvent> _cache = [];

  static const int _maxHistory = 100;

  List<PFScanEvent> all() => List<PFScanEvent>.unmodifiable(_cache);

  Future<void> pull() async {
    final res = await _api.get('/api/scans') as List;
    _cache
      ..clear()
      ..addAll(res.map((e) => PFScanEvent.fromJson(e as Map<String, dynamic>)));
    _sort();
    await _save();
  }

  Future<void> add(PFScanEvent event) async {
    await _api.post('/api/scans', event.toJson());
    _cache.insert(0, event);
    if (_cache.length > _maxHistory) {
      _cache.removeRange(_maxHistory, _cache.length);
    }
    await _save();
  }

  Future<void> clear() async {
    await _api.delete('/api/scans');
    _cache.clear();
    await _storage.remove(StorageKeys.scanHistory);
  }

  void _sort() => _cache.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));

  Future<void> _save() => _storage.setJsonList(
        StorageKeys.scanHistory,
        _cache.map((e) => e.toJson()).toList(),
      );
}
