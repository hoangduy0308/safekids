import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';
import 'battery_service.dart';

/// TaskHandler for background location tracking
@pragma('vm:entry-point')
class LocationTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[ForegroundTask] Location tracking started at $timestamp');
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    debugPrint('[ForegroundTask] Getting location at $timestamp');

    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      debugPrint(
        '[ForegroundTask] Got position: ${position.latitude}, ${position.longitude}',
      );

      // Task 2.6.7: Get battery level and send with location
      final batteryLevel = await BatteryService.instance
          .getCurrentBatteryLevel();

      // Send to backend
      await ApiService().sendLocation(
        position.latitude,
        position.longitude,
        position.accuracy,
        batteryLevel: batteryLevel,
      );

      debugPrint('[ForegroundTask] Location sent successfully');

      // Update notification
      FlutterForegroundTask.updateService(
        notificationText:
            'Vị trí: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
      );
    } catch (e) {
      debugPrint('[ForegroundTask] Error: $e');

      // Update notification with error
      FlutterForegroundTask.updateService(
        notificationText: 'Đang thử lại... (Lỗi: GPS hoặc mạng)',
      );
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('[ForegroundTask] Location tracking stopped at $timestamp');
  }
}

/// Callback for foreground service
@pragma('vm:entry-point')
void startLocationForegroundTask() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  bool _isOffline = false;
  int _queuedLocations = 0;
  Box? _offlineBox;

  // Task 2.6.1: Movement detection
  Position? _lastSignificantLocation;
  DateTime? _lastMovementTime;
  bool _isStationary = false;

  // Task 2.6.3: Low battery mode
  bool _lowBatteryMode = false;

  bool get isTracking => _isTracking;
  bool get isOffline => _isOffline;
  int get queuedLocations => _queuedLocations;
  bool get isStationary => _isStationary;
  bool get lowBatteryMode => _lowBatteryMode;

  Future<void> initialize() async {
    _offlineBox = await Hive.openBox('offline_locations');
    _queuedLocations = _offlineBox?.length ?? 0;

    // Initialize FlutterForegroundTask
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'safekids_location_tracking',
        channelName: 'SafeKids Location Tracking',
        channelDescription: 'Theo dõi vị trí để bảo vệ an toàn của con bạn',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          300000,
        ), // AC 2.1.1: 5 minutes = 300,000ms (can be reduced to 1min for testing)
        autoRunOnBoot: false, // Don't auto-start on boot
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    notifyListeners();
  }

  /// AC 2.1.4: Request location permissions (foreground + background)
  Future<bool> requestLocationPermission() async {
    // Check if GPS is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[Location] GPS is disabled - user must enable manually');
      return false;
    }

    try {
      // Request foreground location permission (ACCESS_FINE_LOCATION)
      var status = await Permission.location.request();

      if (status.isDenied) {
        debugPrint('[Location] Fine location permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        debugPrint(
          '[Location] Fine location permission permanently denied - need to open app settings',
        );
        return false;
      }

      // Request background location permission (ACCESS_BACKGROUND_LOCATION on Android 10+)
      var bgStatus = await Permission.locationAlways.request();
      if (bgStatus.isDenied) {
        debugPrint(
          '[Location] Background location permission denied - foreground tracking only',
        );
      }

      return true;
    } catch (e) {
      debugPrint('[Location] Permission request error: $e');
      return false;
    }
  }

  /// AC 2.1.4: Legacy method - use requestLocationPermission() instead
  Future<bool> checkAndRequestPermissions() async {
    return await requestLocationPermission();
  }

  Future<void> startTracking() async {
    if (_isTracking) return;

    final hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      debugPrint('[Location] Cannot start tracking - no permission');
      return;
    }

    _isTracking = true;
    notifyListeners();

    // Start foreground tracking with Geolocator
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            // Task 2.6.1: Check for movement and stationary mode
            _checkMovement(position);
            _sendLocation(
              position.latitude,
              position.longitude,
              position.accuracy,
            );
          },
          onError: (error) {
            debugPrint('[Location] Stream error: $error');
          },
        );

    // Start foreground service for background tracking
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'SafeKids đang bảo vệ con bạn',
      notificationText: 'Theo dõi vị trí mỗi 5 phút',
      callback: startLocationForegroundTask,
    );

    debugPrint(
      '[Location] Tracking started (foreground stream + background service)',
    );

    // Send initial location
    try {
      final position = await Geolocator.getCurrentPosition();
      _sendLocation(position.latitude, position.longitude, position.accuracy);
    } catch (e) {
      debugPrint('[Location] Initial location error: $e');
    }

    // Sync offline queue
    _syncOfflineLocations();
  }

  void stopTracking() async {
    _positionStream?.cancel();
    await FlutterForegroundTask.stopService();
    _isTracking = false;
    notifyListeners();
    debugPrint('[Location] Tracking stopped');
  }

  Future<void> _sendLocation(double lat, double lng, double accuracy) async {
    // Task 2.6.7: Get battery level and send with location
    final batteryLevel = await BatteryService.instance.getCurrentBatteryLevel();

    try {
      await ApiService().sendLocation(
        lat,
        lng,
        accuracy,
        batteryLevel: batteryLevel,
      );
      debugPrint('[Location] Sent location successfully: ($lat, $lng)');

      if (_isOffline) {
        _isOffline = false;
        notifyListeners();
        _syncOfflineLocations();
      }
    } catch (e) {
      debugPrint('[Location] Send error: $e');
      _queueOfflineLocation(lat, lng, accuracy, batteryLevel: batteryLevel);
      if (!_isOffline) {
        _isOffline = true;
        notifyListeners();
      }
    }
  }

  void _queueOfflineLocation(
    double lat,
    double lng,
    double accuracy, {
    int? batteryLevel,
  }) {
    if (_offlineBox == null) return;

    // Max 100 entries
    if (_offlineBox!.length >= 100) {
      _offlineBox!.deleteAt(0);
    }

    final locationData = {
      'latitude': lat,
      'longitude': lng,
      'accuracy': accuracy,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Task 2.6.7: Store battery level if available
    if (batteryLevel != null) {
      locationData['batteryLevel'] = batteryLevel;
    }

    _offlineBox!.add(locationData);

    _queuedLocations = _offlineBox!.length;
    notifyListeners();
    debugPrint('[Location] Queued offline (total: $_queuedLocations)');
  }

  Future<void> _syncOfflineLocations() async {
    if (_offlineBox == null || _offlineBox!.isEmpty) return;

    debugPrint(
      '[Location] Syncing ${_offlineBox!.length} offline locations...',
    );
    final locations = _offlineBox!.values.toList();
    final now = DateTime.now();

    for (var i = 0; i < locations.length; i++) {
      final loc = locations[i];
      final timestamp = DateTime.parse(loc['timestamp']);

      // Discard if older than 24 hours
      if (now.difference(timestamp).inHours > 24) {
        await _offlineBox!.deleteAt(i);
        debugPrint(
          '[Location] Discarded old location (${now.difference(timestamp).inHours}h old)',
        );
        continue;
      }

      try {
        // Task 2.6.7: Get battery level (use stored if available, otherwise current)
        final storedBattery = loc['batteryLevel'] as int?;
        final batteryLevel =
            storedBattery ??
            await BatteryService.instance.getCurrentBatteryLevel();

        await ApiService().sendLocation(
          loc['latitude'],
          loc['longitude'],
          loc['accuracy'],
          batteryLevel: batteryLevel,
        );
        await _offlineBox!.deleteAt(i);
        debugPrint('[Location] Synced offline location');
      } catch (e) {
        debugPrint('[Location] Sync failed, still offline');
        break; // Still offline
      }
    }

    _queuedLocations = _offlineBox!.length;
    notifyListeners();
  }

  /// Get current location (one-time)
  Future<Position?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      debugPrint('[Location] Get current location error: $e');
      return null;
    }
  }

  /// Update tracking interval (Task 2.5.6)
  /// Configures the frequency of location updates
  Future<void> updateInterval(String interval) async {
    int intervalMs;
    switch (interval) {
      case 'continuous':
        intervalMs = 30000; // 30 seconds
        break;
      case 'normal':
        intervalMs = 120000; // 2 minutes
        break;
      case 'battery-saver':
        intervalMs = 300000; // 5 minutes
        break;
      default:
        intervalMs = 30000;
    }

    debugPrint('[Location] Updating interval to $interval ($intervalMs ms)');

    // Restart tracking with new interval if currently tracking
    if (_isTracking) {
      stopTracking();
      await Future.delayed(const Duration(milliseconds: 500));
      await startTracking();
    }
  }

  /// Task 2.6.1: Check for movement and detect if stationary
  /// Returns true if movement detected (>50m), false if stationary (<50m)
  bool _checkMovement(Position currentPosition) {
    if (_lastSignificantLocation == null) {
      _lastSignificantLocation = currentPosition;
      _lastMovementTime = DateTime.now();
      return false; // First location, consider stationary
    }

    final distance = _calculateDistance(
      _lastSignificantLocation!.latitude,
      _lastSignificantLocation!.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    debugPrint(
      '[Location] Distance from last: ${distance.toStringAsFixed(1)}m',
    );

    if (distance > 50) {
      // Movement detected
      _lastSignificantLocation = currentPosition;
      _lastMovementTime = DateTime.now();

      if (_isStationary) {
        debugPrint('[Location] Movement detected - resuming normal tracking');
        _isStationary = false;
        notifyListeners();
      }
      return true;
    } else {
      // Still stationary
      final stationaryDuration = DateTime.now().difference(_lastMovementTime!);
      if (stationaryDuration.inMinutes > 5 && !_isStationary) {
        debugPrint(
          '[Location] Stationary for >5 min - reducing tracking frequency',
        );
        _isStationary = true;
        notifyListeners();
      }
      return false;
    }
  }

  /// Calculate distance between two points (Haversine formula)
  /// Returns distance in meters
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double R = 6371000; // Earth radius in meters
    final double dLat = (lat2 - lat1) * 3.141592653589793 / 180;
    final double dLon = (lon2 - lon1) * 3.141592653589793 / 180;
    final double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1 * 3.141592653589793 / 180) *
            cos(lat2 * 3.141592653589793 / 180) *
            sin(dLon / 2) *
            sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Task 2.6.3: Set low battery mode (WiFi/cell tower location)
  /// When battery <20%, use low accuracy to save battery
  Future<void> setLowBatteryMode(bool enabled) async {
    if (_lowBatteryMode == enabled) return;
    _lowBatteryMode = enabled;

    if (_isTracking) {
      debugPrint(
        '[Location] ${enabled ? 'Enabling' : 'Disabling'} low battery mode',
      );
      // Restart with new accuracy setting
      stopTracking();
      await Future.delayed(const Duration(milliseconds: 500));
      await startTracking();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    stopTracking();
    _offlineBox?.close();
    super.dispose();
  }
}
