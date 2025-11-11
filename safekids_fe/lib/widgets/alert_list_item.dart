import 'package:flutter/material.dart';
import '../models/geofence_alert.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AlertListItem extends StatelessWidget {
  final GeofenceAlertModel alert;
  final VoidCallback? onTap;
  const AlertListItem({super.key, required this.alert, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEnter = alert.action == 'enter';
    final icon = isEnter ? Icons.arrow_downward : Icons.arrow_upward;
    final color = isEnter ? AppColors.danger : AppColors.warning;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(
        '${alert.childName} ${isEnter ? 'đã vào' : 'đã rời khỏi'} ${alert.geofenceName}',
        style: AppTypography.body,
      ),
      subtitle: Text(
        _formatTime(alert.timestamp),
        style: AppTypography.caption,
      ),
      trailing: Chip(
        label: Text(alert.geofenceType == 'safe' ? 'An toàn' : 'Nguy hiểm'),
        backgroundColor: alert.geofenceType == 'safe'
            ? AppColors.successLight
            : AppColors.borderError.withOpacity(0.1),
        labelStyle: AppTypography.caption,
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${ts.day}/${ts.month}/${ts.year} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}';
  }
}
