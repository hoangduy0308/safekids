import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';

class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback? onGranted;

  const LocationPermissionDialog({Key? key, this.onGranted}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.childPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                size: 40,
                color: AppColors.childPrimary,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Quyền Vị Trí',
              style: AppTypography.h2.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'SafeKids cần quyền vị trí để bảo vệ bạn và giúp phụ huynh biết bạn đang ở đâu.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final granted = await _requestPermission(context);
                  if (granted && onGranted != null) onGranted!();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.childPrimary,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Cho Phép', style: AppTypography.button),
              ),
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Để Sau',
                style: AppTypography.button.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _requestPermission(BuildContext context) async {
    // Step 1: Request foreground location
    var status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      // Step 2: Request background location (Android 10+)
      var backgroundStatus = await Permission.locationAlways.request();

      if (backgroundStatus.isDenied) {
        _showBackgroundPermissionDialog(context);
      }

      return true;
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog(context);
      return false;
    }
    return false;
  }

  void _showBackgroundPermissionDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => BackgroundPermissionDialog());
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => PermissionDeniedDialog());
  }
}

class PermissionDeniedDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 60, color: AppColors.danger),
            SizedBox(height: 16),
            Text(
              'Quyền Bị Từ Chối',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            Text(
              'Vui lòng bật quyền vị trí trong Cài Đặt để SafeKids có thể bảo vệ bạn.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                icon: Icon(Icons.settings, size: 20),
                label: Text('Mở Cài Đặt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.childPrimary,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }
}

class BackgroundPermissionDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield, size: 40, color: AppColors.warning),
            ),
            SizedBox(height: 16),
            Text(
              'Quyền Vị Trí Nền',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            Text(
              'Để bảo vệ bạn tốt nhất, SafeKids cần quyền theo dõi vị trí ngay cả khi app đóng.\n\nVui lòng chọn "Cho phép mọi lúc" trong Cài Đặt.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                icon: Icon(Icons.settings, size: 20),
                label: Text('Mở Cài Đặt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Để Sau'),
            ),
          ],
        ),
      ),
    );
  }
}
