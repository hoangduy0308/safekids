import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'package:safekids_app/theme/app_typography.dart';

class ChildLocationInfo extends StatefulWidget {
  final String childId;
  final String childName;

  const ChildLocationInfo({
    Key? key,
    required this.childId,
    required this.childName,
  }) : super(key: key);

  @override
  State<ChildLocationInfo> createState() => _ChildLocationInfoState();
}

class _ChildLocationInfoState extends State<ChildLocationInfo> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _locationFuture;
  late Future<int> _batteryFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _locationFuture = _apiService.getChildLatestLocation(widget.childId);
    _batteryFuture = _apiService.getChildBatteryLevel(widget.childId);
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: AppSpacing.md),
        _buildSection('Vị trí hiện tại', _buildLocationContent()),
        SizedBox(height: AppSpacing.lg),
        _buildSection('Pin thiết bị', _buildBatteryContent()),
        SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.label.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: AppSpacing.sm),
          content,
        ],
      ),
    );
  }

  Widget _buildLocationContent() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _locationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCard(child: _buildSpinner());
        }

        if (snapshot.hasError) {
          return _buildCard(
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.danger),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Không thể tải vị trí',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
            borderColor: AppColors.danger,
            bgColor: AppColors.danger,
          );
        }

        if (!snapshot.hasData) {
          return _buildCard(
            child: Text(
              'Chưa có dữ liệu',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        final location = snapshot.data ?? {};
        return _buildLocationCard(location);
      },
    );
  }

  Widget _buildBatteryContent() {
    return FutureBuilder<int>(
      future: _batteryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCard(child: _buildSpinner());
        }

        final battery = snapshot.data ?? 0;
        final color = battery > 50
            ? AppColors.success
            : battery > 20
            ? AppColors.warning
            : AppColors.danger;

        return _buildCard(
          child: Row(
            children: [
              Icon(
                battery > 80
                    ? Icons.battery_full
                    : battery > 50
                    ? Icons.battery_6_bar
                    : battery > 20
                    ? Icons.battery_3_bar
                    : Icons.battery_alert,
                size: 24,
                color: color,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$battery%',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: battery / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          borderColor: color,
          bgColor: color,
        );
      },
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    final lat = location['latitude'] as double?;
    final lng = location['longitude'] as double?;
    final address = location['address'] as String?;
    final updatedAt = location['updatedAt'] != null
        ? DateTime.tryParse(location['updatedAt'] as String)
        : null;
    final inSafeZone = location['inSafeZone'] as bool? ?? false;
    final color = inSafeZone ? AppColors.success : AppColors.warning;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: AppColors.parentPrimary),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  address ??
                      '${lat?.toStringAsFixed(4)}, ${lng?.toStringAsFixed(4)}',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (lat != null && lng != null) ...[
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.pin_drop, size: 14, color: AppColors.textSecondary),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                    style: AppTypography.overline.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Updated: ${_formatTime(updatedAt)}',
                    style: AppTypography.overline.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              _buildSafeZoneBadge(inSafeZone),
            ],
          ),
        ],
      ),
      borderColor: color,
      bgColor: color,
    );
  }

  Widget _buildSafeZoneBadge(bool inSafeZone) {
    final color = inSafeZone ? AppColors.success : AppColors.warning;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            inSafeZone ? Icons.shield_outlined : Icons.warning_outlined,
            size: 12,
            color: color,
          ),
          SizedBox(width: 4),
          Text(
            inSafeZone ? 'Safe' : 'Outside',
            style: AppTypography.captionSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinner() {
    return Center(
      child: SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(AppColors.parentPrimary),
        ),
      ),
    );
  }

  Widget _buildCard({
    required Widget child,
    Color? borderColor,
    Color? bgColor,
  }) {
    final actualBgColor = bgColor ?? AppColors.divider;
    final actualBorderColor = borderColor ?? AppColors.divider;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: actualBgColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: actualBorderColor.withOpacity(0.3)),
      ),
      child: child,
    );
  }
}
