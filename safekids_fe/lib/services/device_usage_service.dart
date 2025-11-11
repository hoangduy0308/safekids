import 'package:flutter/services.dart';

/// Device Usage Service
/// Queries Android UsageStatsManager to get device-wide usage statistics
/// Requires PACKAGE_USAGE_STATS permission
class DeviceUsageService {
  static final DeviceUsageService _instance = DeviceUsageService._internal();
  factory DeviceUsageService() => _instance;
  DeviceUsageService._internal();

  static const platform = MethodChannel('com.safekids/device_usage');

  /// Get device app usage for a time range
  /// Returns total app usage time in minutes and breakdown by app
  Future<Map<String, dynamic>> getDeviceUsage({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final result = await platform
          .invokeMethod<Map<dynamic, dynamic>>('getDeviceUsage', {
            'startTime': startTime.millisecondsSinceEpoch,
            'endTime': endTime.millisecondsSinceEpoch,
          });

      if (result == null) {
        return {'totalAppUsageMinutes': 0, 'appUsages': []};
      }

      return {
        'totalAppUsageMinutes': result['totalAppUsageMinutes'] ?? 0,
        'appUsages':
            (result['appUsages'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      };
    } catch (e) {
      print('[DeviceUsage] Error: $e');
      return {'totalAppUsageMinutes': 0, 'appUsages': []};
    }
  }

  /// Get today's device usage (from 00:00 to 23:59)
  Future<Map<String, dynamic>> getTodayDeviceUsage() async {
    final now = DateTime.now();
    final startTime = DateTime(now.year, now.month, now.day);
    final endTime = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getDeviceUsage(startTime: startTime, endTime: endTime);
  }

  /// Get device usage for a specific app package
  Future<int> getAppUsageMinutes(String packageName) async {
    final usage = await getTodayDeviceUsage();
    final appUsages = usage['appUsages'] as List?;

    if (appUsages == null) return 0;

    final appUsage = appUsages.firstWhere(
      (app) => app['packageName'] == packageName,
      orElse: () => <String, dynamic>{},
    );

    final foregroundTime = appUsage['totalTimeInForeground'] as int?;
    return foregroundTime != null
        ? foregroundTime ~/ 60000
        : 0; // Convert to minutes
  }

  /// Get SafeKids app specific usage
  Future<int> getSafeKidsUsageMinutes() async {
    return getAppUsageMinutes('com.safekids.safekids_app');
  }
}
