import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';

class GpsDisabledDialog extends StatelessWidget {
  const GpsDisabledDialog({Key? key}) : super(key: key);

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
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off,
                size: 40,
                color: AppColors.danger,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'GPS Đã Tắt',
              style: AppTypography.h2.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Vui lòng bật GPS để SafeKids có thể theo dõi vị trí và bảo vệ bạn.',
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
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  Navigator.pop(context);
                },
                icon: Icon(Icons.gps_fixed, size: 20),
                label: Text('Bật GPS', style: AppTypography.button),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
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
              child: Text(
                'Đóng',
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
}
