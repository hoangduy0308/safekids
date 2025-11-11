import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';

class NotificationCenter extends StatefulWidget {
  final int pendingRequestsCount;
  final VoidCallback? onShowPendingRequests;
  final List<Map<String, dynamic>> recentActivities;
  final List<Map<String, dynamic>> sosSignals;

  const NotificationCenter({
    Key? key,
    required this.pendingRequestsCount,
    this.onShowPendingRequests,
    this.recentActivities = const [],
    this.sosSignals = const [],
  }) : super(key: key);

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trung tâm thông báo',
                  style: AppTypography.h2.copyWith(fontWeight: FontWeight.w700),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    size: 24,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.divider),

          // Pending Link Requests Section
          if (widget.pendingRequestsCount > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person_add,
                            color: AppColors.childPrimary,
                            size: 24,
                          ),
                          SizedBox(width: AppSpacing.md),
                          Text(
                            'Yêu cầu liên kết',
                            style: AppTypography.h3.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.pendingRequestsCount.toString(),
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Bạn có ${widget.pendingRequestsCount} yêu cầu liên kết chưa xử lý',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.onShowPendingRequests,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.childPrimary,
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Xem yêu cầu',
                            style: AppTypography.button.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.divider),
              ],
            ),

          // SOS Signals Section
          if (widget.sosSignals.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.emergency,
                            color: AppColors.danger,
                            size: 24,
                          ),
                          SizedBox(width: AppSpacing.md),
                          Text(
                            'Tín hiệu SOS',
                            style: AppTypography.h3.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      ...widget.sosSignals.map((signal) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.md),
                          child: _buildSOSItem(signal),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.divider),
              ],
            ),

          // Recent Activities Section
          if (widget.recentActivities.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: AppColors.childAccent,
                        size: 24,
                      ),
                      SizedBox(width: AppSpacing.md),
                      Text(
                        'Hoạt động gần đây',
                        style: AppTypography.h3.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  ...widget.recentActivities.map((activity) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: _buildActivityItem(activity),
                    );
                  }).toList(),
                ],
              ),
            ),

          // Empty State
          if (widget.pendingRequestsCount == 0 &&
              widget.recentActivities.isEmpty &&
              widget.sosSignals.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 60,
                horizontal: AppSpacing.lg,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: AppColors.divider,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Không có thông báo',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Bạn không có thông báo mới',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  (activity['color'] as Color?)?.withOpacity(0.1) ??
                  AppColors.childPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity['icon'] as IconData?,
              color: activity['color'] ?? AppColors.childPrimary,
              size: 20,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? '',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  activity['description'] ?? '',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            activity['time'] ?? '',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSItem(Map<String, dynamic> signal) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.danger.withOpacity(0.1),
            AppColors.danger.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emergency, color: AppColors.danger, size: 28),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Gửi tín hiệu SOS',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Đã gửi',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  signal['description'] ??
                      'Tín hiệu SOS đã được gửi đến phụ huynh',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        signal['location'] ?? 'Chưa có vị trí',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      signal['time'] ?? '',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
