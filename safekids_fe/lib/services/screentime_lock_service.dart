import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screentime_tracker_service.dart';
import '../screens/child/lock_screen.dart';
import '../screens/child/child_home_screen.dart';

/// Screen Time Lock Service (AC 5.3.1, 5.3.7, 5.3.8) - Story 5.3
/// Enforces screen time limits and bedtime mode with lock screen overlay
class ScreenTimeLockService {
  static final ScreenTimeLockService _instance =
      ScreenTimeLockService._internal();
  factory ScreenTimeLockService() => _instance;
  ScreenTimeLockService._internal();

  Timer? _checkTimer;
  Timer? _midnightTimer;
  bool _isLocked = false;
  BuildContext? _context;

  Future<void> init(BuildContext context) async {
    _context = context;

    // Check lock status on startup
    await _checkLockStatus();

    // Check every minute
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkLockStatus();
    });

    // Schedule midnight reset
    _scheduleMidnightReset();
  }

  Future<void> _checkLockStatus() async {
    if (_context == null || !_context!.mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get config
      final dailyLimit = prefs.getInt('screentime_daily_limit') ?? 120;
      final bedtimeEnabled =
          prefs.getBool('screentime_bedtime_enabled') ?? false;
      final bedtimeStart =
          prefs.getString('screentime_bedtime_start') ?? '21:00';
      final bedtimeEnd = prefs.getString('screentime_bedtime_end') ?? '07:00';

      // Get current usage
      final todayUsage = ScreenTimeTrackerService().getTodayUsage();

      // Check bedtime mode first (higher priority)
      if (bedtimeEnabled && _isInBedtime(bedtimeStart, bedtimeEnd)) {
        await _showLockScreen('bedtime', todayUsage, dailyLimit, bedtimeEnd);
        return;
      }

      // Check daily limit
      if (dailyLimit > 0 && todayUsage >= dailyLimit) {
        await _showLockScreen('limit', todayUsage, dailyLimit, null);
        return;
      }

      // Not locked, ensure flag is false
      if (_isLocked) {
        _isLocked = false;
        await prefs.setBool('screentime_locked', false);
      }
    } catch (e) {
      print('[Lock Service] Check error: $e');
    }
  }

  bool _isInBedtime(String startStr, String endStr) {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    final startParts = startStr.split(':');
    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);

    final endParts = endStr.split(':');
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    // Handle overnight bedtime (e.g., 21:00 - 07:00)
    if (startMinutes > endMinutes) {
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    } else {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
  }

  Future<void> _showLockScreen(
    String lockType,
    int todayUsage,
    int dailyLimit,
    String? bedtimeEnd,
  ) async {
    if (_isLocked || _context == null || !_context!.mounted) return;

    _isLocked = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('screentime_locked', true);

    // Push lock screen as modal (cannot dismiss)
    Navigator.of(_context!).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => LockScreen(
          lockType: lockType,
          todayUsage: todayUsage,
          dailyLimit: dailyLimit,
          bedtimeEnd: bedtimeEnd,
        ),
      ),
      (route) => false, // Remove all previous routes
    );
  }

  void _scheduleMidnightReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now);

    _midnightTimer = Timer(duration, () async {
      // Reset usage counter
      await _resetDailyUsage();

      // Unlock if locked
      if (_isLocked && _context != null && _context!.mounted) {
        _isLocked = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('screentime_locked', false);

        // Navigate back to home (unlock)
        Navigator.of(_context!).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ChildHomeScreen()),
          (route) => false,
        );
      }

      // Schedule next midnight reset
      _scheduleMidnightReset();
    });
  }

  Future<void> _resetDailyUsage() async {
    final prefs = await SharedPreferences.getInstance();

    // Reset notification flags
    final today = _getTodayDate();
    await prefs.remove('screentime_80_sent_$today');
    await prefs.remove('screentime_100_sent_$today');

    print('[Lock Service] Daily usage reset at midnight');
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _checkTimer?.cancel();
    _midnightTimer?.cancel();
  }
}
