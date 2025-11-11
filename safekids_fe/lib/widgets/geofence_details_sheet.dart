import 'package:flutter/material.dart';
import '../models/geofence.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

class GeofenceDetailsSheet extends StatelessWidget {
  final Geofence geofence;
  final List<Map<String, dynamic>> linkedChildrenNames;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GeofenceDetailsSheet({
    Key? key,
    required this.geofence,
    required this.linkedChildrenNames,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOpenNote = geofence.isDangerZone
        ? 'Cảnh báo khi con vào vùng'
        : 'Cảnh báo khi con rời vùng';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: geofence.isDangerZone
                            ? Colors.red
                            : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        geofence.isDangerZone ? Icons.warning : Icons.shield,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            geofence.name,
                            style: AppTypography.h3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            geofence.isDangerZone
                                ? 'Vùng nguy hiểm'
                                : 'Vùng an toàn',
                            style: AppTypography.caption.copyWith(
                              color: geofence.isDangerZone
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
                _buildDetailRow('Bán kính', '${geofence.radius.toInt()}m'),
                _buildDetailRow('Chế độ cảnh báo', isOpenNote),
                if (geofence.activeHours != null)
                  _buildDetailRow(
                    'Giờ hoạt động',
                    '${geofence.activeHours!.start} - ${geofence.activeHours!.end}',
                  ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Áp dụng cho',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                ...linkedChildrenNames.map(
                  (child) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      '• ${child['name']}',
                      style: AppTypography.body,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onEdit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.parentPrimaryLight,
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                        child: Text('Chỉnh sửa'),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showDeleteConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                        child: Text(
                          'Xóa',
                          style: AppTypography.button.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption),
          Text(
            value,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    // This will be called from the parent, so we use a callback
    onDelete();
  }
}
