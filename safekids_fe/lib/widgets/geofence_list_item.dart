import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/geofence.dart';
import '../theme/app_typography.dart';

class GeofenceListItem extends StatefulWidget {
  final Geofence geofence;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const GeofenceListItem({
    Key? key,
    required this.geofence,
    this.isSelected = false,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  }) : super(key: key);

  @override
  _GeofenceListItemState createState() => _GeofenceListItemState();
}

class _GeofenceListItemState extends State<GeofenceListItem> {
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _isActive = widget.geofence.active ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: widget.isSelected ? 6 : 2,
      color: widget.isSelected ? Colors.teal.withOpacity(0.1) : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: _getGeofenceTypeColor(),
          child: Icon(
            Icons.location_on,
            color: _isActive ? _getGeofenceIconColor() : Colors.grey,
            size: 28,
          ),
        ),
        title: Text(
          widget.geofence.name,
          style: AppTypography.body.copyWith(
            color: _isActive ? Colors.black87 : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Bán kính: ${widget.geofence.radius}m',
              style: AppTypography.captionSmall.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.blue.shade400),
                const SizedBox(width: 4),
                Text(
                  '${widget.geofence.linkedChildren?.length ?? 0} trẻ',
                  style: AppTypography.captionSmall.copyWith(
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toggle switch
            Switch.adaptive(
              value: _isActive,
              onChanged: (value) async {
                // Haptic feedback (platform implementation dependent)
                await _updateGeofenceStatus(widget.geofence.id, value);
                widget.onToggle(value);
              },
              activeColor: Colors.teal,
              inactiveThumbColor: Colors.grey.shade400,
            ),

            // Delete button
            if (widget.isSelected)
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red.shade400),
                onPressed: () => _showDeleteConfirmDialog(context),
              ),
          ],
        ),
        onTap: () {
          // Haptic feedback (platform implementation dependent)
          widget.onTap();
        },
      ),
    );
  }

  Color _getGeofenceTypeColor() {
    switch (widget.geofence.type) {
      case 'safe':
        return Colors.green.shade100;
      case 'danger':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getGeofenceIconColor() {
    switch (widget.geofence.type) {
      case 'safe':
        return Colors.green;
      case 'danger':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateGeofenceStatus(String geofenceId, bool active) async {
    try {
      // TODO: Call API service to update status
      // For MVP, simulate update
      setState(() {
        _isActive = active;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active ? 'Đã kích hoạt vùng' : 'Đã vô hiệu hóa vùng'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Xóa'),
        content: Text('Bạn có chắc muốn xóa "${widget.geofence.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
