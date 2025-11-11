import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import '../../theme/app_typography.dart';

/// Battery Optimization Guide (Task 2.6.4)
class BatteryOptimizationGuide {
  static Future<void> showGuideIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('battery_guide_shown') ?? false;

    if (!shown) {
      await prefs.setBool('battery_guide_shown', true);
      _showGuide(context);
    }
  }

  static void _showGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚡ Tối Ưu Hóa Pin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.battery_alert, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'SafeKids cần tắt tối ưu hóa pin để theo dõi liên tục khi ứng dụng đóng.',
                style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Điều này đảm bảo bạn luôn được bảo vệ.',
                style: AppTypography.captionSmall.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (Platform.isAndroid) ...[
                Text(
                  '📱 Android:',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTip('Vô hiệu hóa "Pin Saver" cho SafeKids'),
                _buildTip('Thêm vào "Never Sleeping Apps" (nếu dùng Samsung)'),
              ],
              if (Platform.isIOS) ...[
                Text(
                  '🍎 iOS:',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTip('Bật "Background App Refresh"'),
                _buildTip('Cho phép "Always" vị trí'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bỏ qua'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openBatterySettings();
            },
            child: const Text('Bật ngay'),
          ),
        ],
      ),
    );
  }

  static Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(text, style: AppTypography.caption)),
        ],
      ),
    );
  }

  static void _openBatterySettings() {
    if (Platform.isAndroid) {
      AppSettings.openAppSettings(asAnotherTask: true);
    } else if (Platform.isIOS) {
      AppSettings.openAppSettings(asAnotherTask: true);
    }
  }
}
