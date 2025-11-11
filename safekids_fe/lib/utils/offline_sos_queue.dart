import 'package:hive_flutter/hive_flutter.dart';
import '../services/api_service.dart';
import 'dart:async';

class OfflineSOSQueue {
  static const String _boxName = 'sos_queue';
  static final OfflineSOSQueue _instance = OfflineSOSQueue._internal();

  late Box<Map> _box;
  bool _initialized = false;
  Timer? _retryTimer;

  OfflineSOSQueue._internal();

  factory OfflineSOSQueue() => _instance;

  Future<void> initialize() async {
    if (_initialized) return;

    _box = await Hive.openBox<Map>(_boxName);
    _initialized = true;

    _listenToConnectivity();
    _processQueue();
  }

  /// Add SOS to offline queue
  Future<void> addToQueue(Map<String, dynamic> sosData) async {
    if (!_initialized) await initialize();

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _box.put(id, sosData);

    print('[OfflineSOSQueue] Added SOS to queue: $id');
  }

  /// Get all queued SOS alerts
  List<Map<String, dynamic>> getQueue() {
    if (!_initialized) return [];
    return _box.values.cast<Map<String, dynamic>>().toList();
  }

  /// Process and send queued SOS alerts
  Future<void> processQueue() async {
    if (!_initialized) return;
    await _processQueue();
  }

  Future<void> _processQueue() async {
    if (_box.isEmpty) return;

    final apiService = ApiService();
    final queuedItems = List.from(_box.keys);

    for (final key in queuedItems) {
      try {
        final sosData = _box.get(key);
        if (sosData == null) continue;

        print('[OfflineSOSQueue] Sending queued SOS: $key');

        // Extract location data from queue
        final location = sosData['location'] as Map?;
        final latitude = location?['latitude'] as double?;
        final longitude = location?['longitude'] as double?;
        final accuracy = location?['accuracy'] as double?;
        final batteryLevel = sosData['batteryLevel'] as int?;
        final networkStatus = sosData['networkStatus'] as String?;

        if (latitude == null || longitude == null) {
          print(
            '[OfflineSOSQueue] Invalid location data in queue, skipping: $key',
          );
          await _box.delete(key);
          continue;
        }

        await apiService.triggerSOS(
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          batteryLevel: batteryLevel,
          networkStatus: networkStatus,
        );

        // Remove from queue if successful
        await _box.delete(key);
        print('[OfflineSOSQueue] Sent successfully, removed from queue: $key');
      } catch (e) {
        print('[OfflineSOSQueue] Error sending SOS $key: $e');
        // Keep in queue for retry
      }
    }
  }

  void _listenToConnectivity() {
    _retryTimer = Timer.periodic(Duration(seconds: 10), (_) {
      if (_box.isNotEmpty) {
        print('[OfflineSOSQueue] Retry timer: processing queue...');
        _processQueue();
      }
    });
  }

  Future<void> dispose() async {
    _retryTimer?.cancel();
    if (_initialized) {
      await _box.close();
    }
  }
}
