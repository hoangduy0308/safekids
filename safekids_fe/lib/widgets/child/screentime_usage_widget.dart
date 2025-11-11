import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/screentime_tracker_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Screen Time Usage Widget (AC 5.2.3) - Story 5.2
/// Displays daily screen time usage with progress bar
class ScreenTimeUsageWidget extends StatefulWidget {
  const ScreenTimeUsageWidget({Key? key}) : super(key: key);

  @override
  State<ScreenTimeUsageWidget> createState() => _ScreenTimeUsageWidgetState();
}

class _ScreenTimeUsageWidgetState extends State<ScreenTimeUsageWidget> {
  int _todayUsage = 0;
  int _dailyLimit = 120; // default 2 hours
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _loadUsage();

    // Update every minute
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadUsage();
    });
  }

  Future<void> _loadUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dailyLimit = prefs.getInt('screentime_daily_limit') ?? 120;
      final todayUsage = ScreenTimeTrackerService().getTodayUsage();

      if (mounted) {
        setState(() {
          _todayUsage = todayUsage;
          _dailyLimit = dailyLimit;
        });
      }
    } catch (e) {
      print('Load usage error: $e');
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usageHours = _todayUsage ~/ 60;
    final usageMinutes = _todayUsage % 60;
    final limitHours = _dailyLimit ~/ 60;
    final limitMinutes = _dailyLimit % 60;

    final remaining = (_dailyLimit - _todayUsage).clamp(0, _dailyLimit);
    final remainingHours = remaining ~/ 60;
    final remainingMinutes = remaining % 60;

    final percent = _dailyLimit > 0
        ? (_todayUsage / _dailyLimit).clamp(0.0, 1.0)
        : 0.0;

    Color progressColor;
    if (percent < 0.8) {
      progressColor = AppColors.success;
    } else if (percent < 1.0) {
      progressColor = Colors.orange;
    } else {
      progressColor = AppColors.danger;
    }

    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: AppColors.childPrimary,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Thời Gian Màn Hình',
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Usage text
            Text(
              'Thời gian dùng hôm nay',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${usageHours}h ${usageMinutes}p / ${limitHours}h ${limitMinutes}p',
              style: AppTypography.h2.copyWith(
                fontWeight: FontWeight.w700,
                color: progressColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Remaining time
            Text(
              remaining > 0
                  ? 'Còn lại: ${remainingHours}h ${remainingMinutes}p'
                  : 'Đã hết thời gian!',
              style: AppTypography.label.copyWith(
                color: progressColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
