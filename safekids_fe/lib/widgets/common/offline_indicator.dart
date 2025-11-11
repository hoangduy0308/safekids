import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../services/location_service.dart';
import '../../theme/app_typography.dart';

/// Widget hiển thị trạng thái offline và số lượng vị trí đang chờ sync
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationService>(
      builder: (context, locationService, child) {
        // Chỉ hiển thị khi offline hoặc có location queue
        if (!locationService.isOffline &&
            locationService.queuedLocations == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            border: Border.all(color: AppColors.warning, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                locationService.isOffline ? Icons.cloud_off : Icons.cloud_queue,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationService.isOffline
                          ? 'Chế độ offline'
                          : 'Đang đồng bộ',
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                    if (locationService.queuedLocations > 0)
                      Text(
                        '${locationService.queuedLocations} vị trí đang chờ đồng bộ',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                  ],
                ),
              ),
              if (!locationService.isOffline &&
                  locationService.queuedLocations > 0)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.warning,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
