import 'package:flutter/material.dart';
import 'package:safekids_app/theme/app_typography.dart';

class GeofenceAlertDialog extends StatelessWidget {
  final String childName;
  final String geofenceName;
  final String action; // 'enter' or 'exit'
  final VoidCallback onViewMap;
  final VoidCallback onClose;

  const GeofenceAlertDialog({
    Key? key,
    required this.childName,
    required this.geofenceName,
    required this.action,
    required this.onViewMap,
    required this.onClose,
  }) : super(key: key);

  String get _alertText {
    final actionText = action == 'exit' ? 'đã rời khỏi' : 'đã vào';
    return '$childName $actionText $geofenceName';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 24),
          const SizedBox(width: 8),
          const Text('Cảnh Báo Vùng'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _alertText,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Thời gian: ${TimeOfDay.now().format(context)}',
            style: AppTypography.label.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: onClose, child: const Text('Đóng')),
        ElevatedButton(
          onPressed: onViewMap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Xem Bản Đồ'),
        ),
      ],
    );
  }
}
