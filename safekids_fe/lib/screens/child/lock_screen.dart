import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import './sos_countdown_dialog.dart';

/// Lock Screen Widget (AC 5.3.2, 5.3.3, 5.3.4) - Story 5.3
/// Full-screen blocking overlay when screen time limit exceeded or bedtime active
class LockScreen extends StatelessWidget {
  final String lockType; // 'limit' or 'bedtime'
  final int todayUsage;
  final int dailyLimit;
  final String? bedtimeEnd;

  const LockScreen({
    Key? key,
    required this.lockType,
    required this.todayUsage,
    required this.dailyLimit,
    this.bedtimeEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final usageHours = todayUsage ~/ 60;
    final usageMinutes = todayUsage % 60;
    final limitHours = dailyLimit ~/ 60;
    final limitMinutes = dailyLimit % 60;

    String title;
    String message;
    IconData icon;
    Color bgColor;

    if (lockType == 'bedtime') {
      title = '🌙 Giờ Ngủ';
      message =
          'Đây là giờ nghỉ ngơi.\nThiết bị sẽ mở lại vào ${bedtimeEnd ?? '07:00'} sáng';
      icon = Icons.nightlight_round;
      bgColor = Colors.indigo;
    } else {
      title = '🔒 Hết Thời Gian Màn Hình';
      message = 'Bạn đã dùng hết thời gian cho phép hôm nay';
      icon = Icons.lock_clock;
      bgColor = Colors.red[700]!;
    }

    return PopScope(
      canPop: false, // Prevent back button (newer API for Flutter 3.12+)
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lock icon
                  Icon(icon, size: 120, color: Colors.white),
                  const SizedBox(height: AppSpacing.xl),

                  // Title
                  Text(
                    title,
                    style: AppTypography.h1.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Message
                  Text(
                    message,
                    style: AppTypography.body.copyWith(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (lockType == 'limit') ...[
                    const SizedBox(height: AppSpacing.xl),
                    // Usage stats
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Đã dùng hôm nay',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${usageHours}h ${usageMinutes}p / ${limitHours}h ${limitMinutes}p',
                            style: AppTypography.h2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // SOS Emergency Button (ALWAYS VISIBLE)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.warning, size: 32),
                    label: Text(
                      'SOS KHẨN CẤP',
                      style: AppTypography.button.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => _triggerSOS(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _triggerSOS(BuildContext context) {
    // Navigate to SOS confirmation dialog (Story 4.1)
    showDialog(
      context: context,
      builder: (context) => SOSCountdownDialog(
        onConfirm: () {
          Navigator.of(context).pop();
          // SOS alert will be sent, return to lock screen
        },
      ),
      barrierDismissible: false,
    );
  }
}
