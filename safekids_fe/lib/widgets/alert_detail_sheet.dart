import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/environment.dart';
import '../models/geofence_alert.dart';
import '../models/location.dart' as location_model;
import '../models/child_detail_data.dart';
import '../screens/parent/child_map_screen.dart';
import '../theme/app_typography.dart';
import '../theme/app_colors.dart';

String _buildStaticMapUrl(double latitude, double longitude) {
  final key = EnvironmentConfig.mapTilerApiKey;
  if (key.isEmpty) {
    return 'https://staticmap.openstreetmap.de/staticmap.php?center=$latitude,$longitude&zoom=15&size=600x300&markers=$latitude,$longitude,red';
  }
  return 'https://api.maptiler.com/maps/streets/static/${longitude},${latitude},15/600x300.png?key=$key';
}

class AlertDetailSheet extends StatelessWidget {
  final GeofenceAlertModel alert;
  const AlertDetailSheet({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chi Tiết Cảnh Báo', style: AppTypography.h3),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _buildStaticMapUrl(alert.latitude, alert.longitude),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _row(Icons.person, 'Trẻ em', alert.childName),
            _row(Icons.shield, 'Vùng', alert.geofenceName),
            _row(
              Icons.label,
              'Loại',
              alert.geofenceType == 'safe' ? 'Vùng An Toàn' : 'Vùng Nguy Hiểm',
            ),
            _row(
              Icons.access_time,
              'Thời gian',
              alert.timestamp.toLocal().toString(),
            ),
            _row(
              Icons.my_location,
              'Vị trí',
              '${alert.latitude}, ${alert.longitude}',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Xem tr�n b?n d?'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final selected = location_model.Location(
                    id: 'alert-${alert.id ?? ''}',
                    userId: alert.childId,
                    latitude: alert.latitude,
                    longitude: alert.longitude,
                    accuracy: 0,
                    timestamp: alert.timestamp,
                  );
                  final childDetail = ChildDetailData(
                    childId: alert.childId,
                    name: alert.childName,
                    batteryLevel: null,
                    lastSeen: alert.timestamp.toLocal().toIso8601String(),
                    locationName: alert.geofenceName,
                    isInSafeZone: alert.geofenceType == 'safe',
                    screenTimeMinutes: 0,
                    screenTimeLimit: 0,
                    selectedLocation: selected,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChildMapScreen(
                        childId: alert.childId,
                        childName: alert.childName,
                        childDetail: childDetail,
                        selectedLocation: selected,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                Text(value, style: AppTypography.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
