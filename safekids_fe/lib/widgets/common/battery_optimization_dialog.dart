import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../theme/app_colors.dart';
import 'package:safekids_app/theme/app_typography.dart';

/// Dialog hướng dẫn tắt battery optimization theo từng hãng điện thoại
class BatteryOptimizationDialog extends StatefulWidget {
  const BatteryOptimizationDialog({Key? key}) : super(key: key);

  @override
  State<BatteryOptimizationDialog> createState() =>
      _BatteryOptimizationDialogState();
}

class _BatteryOptimizationDialogState extends State<BatteryOptimizationDialog> {
  String _manufacturer = 'unknown';
  bool _isIgnoring = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (!Platform.isAndroid) return;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final isIgnoring =
          await FlutterForegroundTask.isIgnoringBatteryOptimizations;

      setState(() {
        _manufacturer = androidInfo.manufacturer.toLowerCase();
        _isIgnoring = isIgnoring;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestExemption() async {
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();

    // Recheck status after returning from settings
    await Future.delayed(Duration(seconds: 1));
    await _checkStatus();
  }

  String _getManufacturerName() {
    if (_manufacturer.contains('samsung')) return 'Samsung';
    if (_manufacturer.contains('xiaomi') ||
        _manufacturer.contains('redmi') ||
        _manufacturer.contains('poco')) {
      return 'Xiaomi/Redmi/Poco';
    }
    if (_manufacturer.contains('huawei') || _manufacturer.contains('honor'))
      return 'Huawei/Honor';
    if (_manufacturer.contains('oppo') || _manufacturer.contains('realme'))
      return 'Oppo/Realme';
    if (_manufacturer.contains('vivo') || _manufacturer.contains('iqoo'))
      return 'Vivo/iQOO';
    if (_manufacturer.contains('oneplus')) return 'OnePlus';
    return 'Android';
  }

  List<String> _getInstructions() {
    final manufacturer = _manufacturer.toLowerCase();

    if (manufacturer.contains('samsung')) {
      return [
        'Settings → Apps → SafeKids → Battery',
        'Battery optimization → Don\'t optimize',
        'Settings → Device care → Battery',
        'Background usage limits → Remove SafeKids',
        'Allow background activity → ON',
      ];
    }

    if (manufacturer.contains('xiaomi') ||
        manufacturer.contains('redmi') ||
        manufacturer.contains('poco')) {
      return [
        '⚠️ MIUI rất strict về battery!',
        'Settings → Apps → SafeKids',
        'Battery saver → No restrictions',
        'Autostart → ON',
        'Other permissions → Display pop-up → Allow',
        'Settings → Battery & performance → SafeKids → No restrictions',
      ];
    }

    if (manufacturer.contains('huawei') || manufacturer.contains('honor')) {
      return [
        'Settings → Apps → SafeKids → Battery',
        'Allow background activity → ON',
        'Launch → Manage manually',
        '  • Auto-launch → ON',
        '  • Secondary launch → ON',
        '  • Run in background → ON',
        'Phone Manager → Protected apps → SafeKids → ON',
      ];
    }

    if (manufacturer.contains('oppo') || manufacturer.contains('realme')) {
      return [
        'Settings → Battery → Energy Saver',
        'SafeKids → No restrictions',
        'Settings → App management → SafeKids',
        'Battery usage → Background freeze → Never',
        'Startup Manager → SafeKids → Allow',
      ];
    }

    if (manufacturer.contains('vivo') || manufacturer.contains('iqoo')) {
      return [
        'Settings → Battery',
        'High background power consumption → SafeKids → Allow',
        'Settings → More settings → Applications',
        'Autostart → SafeKids → Enable',
        'Background activity manager → Allow high power consumption',
      ];
    }

    if (manufacturer.contains('oneplus')) {
      return [
        'Settings → Apps → SafeKids → Battery',
        'Battery optimization → Don\'t optimize',
        'Advanced optimization → Deep optimization → Disable',
      ];
    }

    // Stock Android / Generic
    return [
      'Settings → Apps → SafeKids',
      'Battery → Battery optimization',
      'Dropdown "Not optimized" → All apps',
      'Find SafeKids → Don\'t optimize',
      'Confirm → Done',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.battery_charging_full, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cài đặt Battery Optimization',
              style: AppTypography.h4,
            ),
          ),
        ],
      ),
      content: _isLoading
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isIgnoring
                          ? Colors.green.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isIgnoring ? Colors.green : AppColors.warning,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isIgnoring ? Icons.check_circle : Icons.warning,
                          color: _isIgnoring ? Colors.green : AppColors.warning,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isIgnoring
                                ? 'Battery optimization đã được tắt ✓'
                                : 'Battery optimization đang BẬT (cần tắt)',
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _isIgnoring
                                  ? Colors.green
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Manufacturer
                  Text(
                    'Điện thoại: ${_getManufacturerName()}',
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Why
                  Text(
                    'Tại sao cần tắt?',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Để SafeKids có thể chạy ngầm và theo dõi vị trí liên tục, đảm bảo an toàn cho con bạn.',
                    style: AppTypography.captionSmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 12),

                  // Impact
                  Row(
                    children: [
                      Icon(
                        Icons.battery_std,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Pin: ~5-10% mỗi ngày',
                        style: AppTypography.overline.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.data_usage, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        'Data: ~1.7MB/tháng',
                        style: AppTypography.overline.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  if (!_isIgnoring) ...[
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),

                    // Instructions
                    Text(
                      'Hướng dẫn:',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),

                    ..._getInstructions().asMap().entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: 6,
                          left: entry.value.startsWith('⚠️') ? 0 : 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!entry.value.startsWith('⚠️'))
                              Text(
                                '${entry.key + 1}. ',
                                style: AppTypography.captionSmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: AppTypography.captionSmall.copyWith(
                                  color: entry.value.startsWith('⚠️')
                                      ? AppColors.warning
                                      : Colors.grey[700],
                                  fontWeight: entry.value.startsWith('⚠️')
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Đóng'),
        ),
        if (!_isIgnoring && !_isLoading)
          ElevatedButton.icon(
            onPressed: _requestExemption,
            icon: Icon(Icons.settings, size: 18),
            label: Text('Mở Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.childPrimary,
            ),
          ),
      ],
    );
  }
}

/// Helper function để show dialog
Future<void> showBatteryOptimizationDialog(BuildContext context) async {
  if (!Platform.isAndroid) return;

  return showDialog(
    context: context,
    builder: (context) => BatteryOptimizationDialog(),
  );
}
