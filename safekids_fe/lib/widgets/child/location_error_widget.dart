import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_colors.dart';
import 'package:safekids_app/theme/app_typography.dart';

enum LocationErrorType {
  gpsDisabled,
  permissionDenied,
  networkError,
  batteryOptimization,
}

class LocationErrorWidget extends StatelessWidget {
  final LocationErrorType errorType;
  final VoidCallback? onRetry;

  const LocationErrorWidget({Key? key, required this.errorType, this.onRetry})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: 48, color: _getIconColor()),
          SizedBox(height: 12),
          Text(
            _getTitle(),
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            _getMessage(),
            style: AppTypography.label.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _getAction(),
        icon: Icon(_getActionIcon(), size: 18),
        label: Text(_getActionText()),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getIconColor(),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (errorType) {
      case LocationErrorType.networkError:
        return AppColors.warning.withOpacity(0.1);
      default:
        return AppColors.danger.withOpacity(0.1);
    }
  }

  Color _getBorderColor() {
    switch (errorType) {
      case LocationErrorType.networkError:
        return AppColors.warning.withOpacity(0.3);
      default:
        return AppColors.danger.withOpacity(0.3);
    }
  }

  Color _getIconColor() {
    switch (errorType) {
      case LocationErrorType.networkError:
        return AppColors.warning;
      default:
        return AppColors.danger;
    }
  }

  IconData _getIcon() {
    switch (errorType) {
      case LocationErrorType.gpsDisabled:
        return Icons.location_off;
      case LocationErrorType.permissionDenied:
        return Icons.lock;
      case LocationErrorType.networkError:
        return Icons.wifi_off;
      case LocationErrorType.batteryOptimization:
        return Icons.battery_alert;
    }
  }

  IconData _getActionIcon() {
    switch (errorType) {
      case LocationErrorType.networkError:
        return Icons.refresh;
      default:
        return Icons.settings;
    }
  }

  String _getTitle() {
    switch (errorType) {
      case LocationErrorType.gpsDisabled:
        return 'GPS Đã Tắt';
      case LocationErrorType.permissionDenied:
        return 'Không Có Quyền';
      case LocationErrorType.networkError:
        return 'Mất Kết Nối';
      case LocationErrorType.batteryOptimization:
        return 'Tối Ưu Pin Bật';
    }
  }

  String _getMessage() {
    switch (errorType) {
      case LocationErrorType.gpsDisabled:
        return 'Vui lòng bật GPS trong Cài Đặt để SafeKids có thể theo dõi vị trí của bạn.';
      case LocationErrorType.permissionDenied:
        return 'SafeKids cần quyền vị trí để bảo vệ bạn. Vui lòng cấp quyền trong Cài Đặt.';
      case LocationErrorType.networkError:
        return 'Không có kết nối mạng. Vị trí sẽ được lưu và gửi khi có mạng trở lại.';
      case LocationErrorType.batteryOptimization:
        return 'Tối ưu pin đang chặn theo dõi. Vui lòng tắt tối ưu pin cho SafeKids.';
    }
  }

  String _getActionText() {
    switch (errorType) {
      case LocationErrorType.networkError:
        return 'Thử Lại';
      default:
        return 'Mở Cài Đặt';
    }
  }

  VoidCallback? _getAction() {
    switch (errorType) {
      case LocationErrorType.gpsDisabled:
        return () => Geolocator.openLocationSettings();
      case LocationErrorType.permissionDenied:
        return () => Geolocator.openAppSettings();
      case LocationErrorType.networkError:
        return onRetry;
      case LocationErrorType.batteryOptimization:
        return () => Geolocator.openAppSettings();
    }
  }
}
