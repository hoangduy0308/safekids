import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'location_service.dart';

/// Battery monitoring service (Task 2.6.2)
/// Monitors battery level and adjusts location tracking frequency
class BatteryService extends ChangeNotifier {
  static final BatteryService _instance = BatteryService._internal();
  factory BatteryService() => _instance;
  BatteryService._internal();

  static BatteryService get instance => _instance;

  final Battery _battery = Battery();
  int _batteryLevel = 100;
  bool _isCharging = false;
  bool _isLowBatteryMode = false;
  Timer? _batteryCheckTimer;
  Function(int)? onBatteryChanged; // Callback for battery level changes

  int get batteryLevel => _batteryLevel;
  bool get isCharging => _isCharging;
  bool get isLowBatteryMode => _isLowBatteryMode;

  String get batteryStatus {
    if (_batteryLevel > 50) return 'Bình thường';
    if (_batteryLevel > 20) return 'Tiết kiệm';
    if (_batteryLevel > 10) return 'Siêu tiết kiệm';
    return 'Khẩn cấp';
  }

  double get estimatedDrainPerHour {
    if (_batteryLevel > 50) return 2.0;
    if (_batteryLevel > 20) return 1.5;
    if (_batteryLevel > 10) return 0.8;
    return 0.5;
  }

  /// Get current battery level (Task 2.6.7)
  Future<int> getCurrentBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      debugPrint('[Battery] Error getting current battery level: $e');
      return 100; // Default to full if error
    }
  }

  /// Start monitoring battery level
  Future<void> startMonitoring() async {
    debugPrint('[Battery] Starting battery monitoring');

    // Get initial battery level
    await _updateBatteryLevel();

    // Listen to battery state changes (charging/discharging)
    _battery.onBatteryStateChanged.listen((BatteryState state) {
      debugPrint('[Battery] Battery state changed: $state');
      if (state == BatteryState.charging) {
        _handleCharging();
      } else {
        _isCharging = false;
        notifyListeners();
      }
    });

    // Check battery level every minute
    _batteryCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _updateBatteryLevel();
    });

    debugPrint('[Battery] Battery monitoring started');
  }

  /// Update battery level and adjust tracking accordingly
  Future<void> _updateBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;

      if (level != _batteryLevel) {
        _batteryLevel = level;
        debugPrint('[Battery] Battery level: $_batteryLevel%');

        await _handleBatteryLevel(level);
        // Task 2.6.7: Trigger onBatteryChanged callback
        onBatteryChanged?.call(level);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Battery] Error getting battery level: $e');
    }
  }

  /// Handle battery level changes and adjust tracking interval
  Future<void> _handleBatteryLevel(int level) async {
    final locationService = LocationService();

    if (level > 50) {
      // Normal mode
      debugPrint('[Battery] Mode: Normal (>50%)');
      _isLowBatteryMode = false;
      await locationService.updateInterval('continuous');
    } else if (level > 20) {
      // Reduced mode - 2 minute interval
      debugPrint('[Battery] Mode: Reduced (20-50%)');
      _isLowBatteryMode = false;
      await locationService.updateInterval('normal');
    } else if (level > 10) {
      // Battery saver mode - 5 minute interval
      debugPrint('[Battery] Mode: Battery Saver (10-20%)');
      _isLowBatteryMode = true;
      await locationService.updateInterval('battery-saver');
      await _sendLowBatteryNotification(level);
    } else {
      // Critical mode - 10 minute interval
      debugPrint('[Battery] Mode: Critical (<10%)');
      _isLowBatteryMode = true;
      await locationService.updateInterval('battery-saver');
      await _sendCriticalBatteryNotification(level);
    }
  }

  /// Handle charging - resume normal tracking
  Future<void> _handleCharging() async {
    debugPrint('[Battery] Device is charging - resuming normal tracking');
    _isCharging = true;
    _isLowBatteryMode = false;
    await LocationService().updateInterval('continuous');
    notifyListeners();
  }

  /// Send low battery notification to parent via backend
  Future<void> _sendLowBatteryNotification(int level) async {
    try {
      debugPrint('[Battery] Sending low battery notification: $level%');
      // NOTE: Implementation depends on notification service setup
      // This would typically use FCM or a notification service
    } catch (e) {
      debugPrint('[Battery] Error sending low battery notification: $e');
    }
  }

  /// Send critical battery notification
  Future<void> _sendCriticalBatteryNotification(int level) async {
    try {
      debugPrint('[Battery] Sending critical battery notification: $level%');
      // NOTE: Implementation depends on notification service setup
      // This would typically use urgent FCM notification
    } catch (e) {
      debugPrint('[Battery] Error sending critical battery notification: $e');
    }
  }

  /// Stop monitoring
  void stopMonitoring() {
    _batteryCheckTimer?.cancel();
    debugPrint('[Battery] Battery monitoring stopped');
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
