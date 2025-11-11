import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LocationTrackingIndicator extends StatefulWidget {
  final bool isTracking;
  final bool isOffline;
  final int queuedLocations;

  const LocationTrackingIndicator({
    Key? key,
    required this.isTracking,
    this.isOffline = false,
    this.queuedLocations = 0,
  }) : super(key: key);

  @override
  State<LocationTrackingIndicator> createState() =>
      _LocationTrackingIndicatorState();
}

class _LocationTrackingIndicatorState extends State<LocationTrackingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isTracking && !widget.isOffline)
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(_controller.value),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          if (widget.isOffline)
            Icon(Icons.cloud_off, size: 16, color: AppColors.warning),
          if (!widget.isTracking)
            Icon(Icons.location_off, size: 16, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Text(
            _getStatusText(),
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: _getTextColor(),
            ),
          ),
          if (widget.isOffline && widget.queuedLocations > 0) ...[
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.queuedLocations}',
                style: AppTypography.overline.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    if (!widget.isTracking) return AppColors.surfaceVariant;
    if (widget.isOffline) return AppColors.warning.withOpacity(0.1);
    return AppColors.success.withOpacity(0.1);
  }

  Color _getTextColor() {
    if (!widget.isTracking) return AppColors.textSecondary;
    if (widget.isOffline) return AppColors.warning;
    return AppColors.success;
  }

  String _getStatusText() {
    if (!widget.isTracking) return 'Không theo dõi';
    if (widget.isOffline) return 'Offline';
    return 'Đang theo dõi';
  }
}
