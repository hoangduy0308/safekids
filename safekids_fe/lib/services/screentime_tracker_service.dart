import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'device_usage_service.dart';

/// Screen Time Tracker Service (AC 5.2.1, 5.2.2, 5.2.4) - Story 5.2
/// Tracks device-wide screen time via Android UsageStatsManager
/// Falls back to app-level session tracking if UsageStatsManager returns 0
///
/// NOTE: PACKAGE_USAGE_STATS permission requires manual enable:
/// Settings → Apps → SafeKids → Permissions → Usage access
/// Without this, UsageStatsManager returns 0 and falls back to session tracking
class ScreenTimeTrackerService {
  static final ScreenTimeTrackerService _instance =
      ScreenTimeTrackerService._internal();
  factory ScreenTimeTrackerService() => _instance;
  ScreenTimeTrackerService._internal();

  final ApiService _apiService = ApiService();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Timer? _uploadTimer;
  Timer? _deviceUsageTimer;
  DateTime? _sessionStart;
  Box<Map>? _sessionsBox;

  int _todayUsageMinutes = 0;
  String _currentDate = '';
  bool _initialized = false;

  final DeviceUsageService _deviceUsageService = DeviceUsageService();

  Future<void> init() async {
    if (_initialized) return;

    try {
      _sessionsBox = await Hive.openBox<Map>('screentime_sessions');
      _currentDate = _getTodayDate();
      await _loadTodayUsage();

      // Initialize notifications
      await _notifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

      // Query device usage immediately and upload
      await _queryDeviceUsage();
      await _uploadUsage();

      // Start device usage query timer (every 5 minutes)
      _deviceUsageTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        _queryDeviceUsage();
      });

      // Start upload timer (every 5 minutes)
      _uploadTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        _uploadUsage();
      });

      _initialized = true;
      print(
        '[ScreenTime Tracker] Initialized successfully with device usage tracking',
      );
    } catch (e) {
      print('[ScreenTime Tracker] Init error: $e');
    }
  }

  /// Query device usage from UsageStatsManager
  /// Falls back to session tracking if device usage is 0
  /// Updates _todayUsageMinutes with total device app usage
  Future<void> _queryDeviceUsage() async {
    try {
      final deviceUsage = await _deviceUsageService.getTodayDeviceUsage();
      var totalAppUsageMinutes =
          deviceUsage['totalAppUsageMinutes'] as int? ?? 0;

      // Fallback to session tracking if device usage is 0
      if (totalAppUsageMinutes == 0) {
        await _loadTodayUsage();
        print(
          '[ScreenTime] Device usage returned 0, using session tracking: $_todayUsageMinutes minutes',
        );
      } else {
        // Update today's usage from device
        _todayUsageMinutes = totalAppUsageMinutes;
        print('[ScreenTime] Device usage updated: $_todayUsageMinutes minutes');
      }

      // Check if new day
      final today = _getTodayDate();
      if (today != _currentDate) {
        _currentDate = today;
        _clearDailyFlags();
      }
    } catch (e) {
      print('[ScreenTime] Query device usage error: $e');
      // Fallback to session tracking on error
      await _loadTodayUsage();
    }
  }

  void startSession() {
    if (_sessionStart != null) return; // Already tracking

    _sessionStart = DateTime.now();
    print('[ScreenTime] Session started: $_sessionStart');
  }

  void endSession() {
    if (_sessionStart == null) return; // No active session

    final now = DateTime.now();
    final duration = now.difference(_sessionStart!).inMinutes;

    if (duration > 0) {
      _saveSession(_sessionStart!, now, duration);
      _todayUsageMinutes += duration;

      // Check if new day
      final today = _getTodayDate();
      if (today != _currentDate) {
        _currentDate = today;
        _todayUsageMinutes = duration; // Reset for new day
        _clearDailyFlags(); // Reset notification flags
      }

      print(
        '[ScreenTime] Session ended: $duration minutes (total today: $_todayUsageMinutes)',
      );
    }

    _sessionStart = null;
  }

  Future<void> _saveSession(DateTime start, DateTime end, int duration) async {
    try {
      final session = {
        'startTime': start.toIso8601String(),
        'endTime': end.toIso8601String(),
        'duration': duration,
        'date': _getTodayDate(),
        'app': 'SafeKids',
        'appPackage': 'com.safekids.app',
      };

      await _sessionsBox?.add(session);
    } catch (e) {
      print('[ScreenTime] Save session error: $e');
    }
  }

  Future<void> _loadTodayUsage() async {
    try {
      final today = _getTodayDate();
      final sessions =
          _sessionsBox?.values.where((s) => s['date'] == today).toList() ?? [];

      _todayUsageMinutes = sessions.fold<int>(
        0,
        (sum, s) => sum + (s['duration'] as int? ?? 0),
      );
      print('[ScreenTime] Loaded today usage: $_todayUsageMinutes minutes');
    } catch (e) {
      print('[ScreenTime] Load usage error: $e');
    }
  }

  Future<void> _uploadUsage() async {
    try {
      final today = _getTodayDate();
      final sessions =
          _sessionsBox?.values.where((s) => s['date'] == today).toList() ?? [];

      // Always upload if totalMinutes > 0 (from device usage or sessions)
      if (_todayUsageMinutes == 0) return;

      final prefs = await SharedPreferences.getInstance();
      final childId = prefs.getString('userId');

      if (childId == null || childId.isEmpty) {
        print('[ScreenTime] No userId found, skipping upload');
        return;
      }

      await _apiService.recordScreenTimeUsage(
        childId: childId,
        date: today,
        totalMinutes: _todayUsageMinutes,
        sessions: sessions.cast<Map<String, dynamic>>(),
      );

      print(
        '[ScreenTime] Usage uploaded: $_todayUsageMinutes minutes (${sessions.length} sessions)',
      );

      // Check for local notifications (AC 5.2.8)
      await _checkLimitsForLocalNotification();
    } catch (e) {
      print('[ScreenTime] Upload error: $e');
    }
  }

  Future<void> _checkLimitsForLocalNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dailyLimit = prefs.getInt('screentime_daily_limit') ?? 120;

      if (dailyLimit == 0) return;

      final percent = (_todayUsageMinutes / dailyLimit) * 100;

      // 80% warning (local notification)
      if (percent >= 80 && percent < 90) {
        final sent80 =
            prefs.getBool('screentime_80_sent_$_currentDate') ?? false;
        if (!sent80) {
          await _showLocalNotification(
            '⚠️ Cảnh Báo Thời Gian',
            'Bạn đã dùng 80% thời gian màn hình hôm nay',
          );
          await prefs.setBool('screentime_80_sent_$_currentDate', true);
        }
      }

      // 100% exceeded (local notification)
      if (percent >= 100) {
        final sent100 =
            prefs.getBool('screentime_100_sent_$_currentDate') ?? false;
        if (!sent100) {
          await _showLocalNotification(
            '🚫 Hết Thời Gian',
            'Bạn đã hết thời gian dùng thiết bị hôm nay',
          );
          await prefs.setBool('screentime_100_sent_$_currentDate', true);
        }
      }
    } catch (e) {
      print('[ScreenTime] Check limits error: $e');
    }
  }

  Future<void> _showLocalNotification(String title, String body) async {
    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'screentime',
            'Screen Time',
            channelDescription: 'Screen time limit notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      print('[ScreenTime] Local notification error: $e');
    }
  }

  Future<void> _clearDailyFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('screentime_80_sent_$_currentDate');
      await prefs.remove('screentime_100_sent_$_currentDate');
    } catch (e) {
      print('[ScreenTime] Clear flags error: $e');
    }
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int getTodayUsage() => _todayUsageMinutes;

  void dispose() {
    _uploadTimer?.cancel();
    _deviceUsageTimer?.cancel();
    _sessionsBox?.close();
  }
}
