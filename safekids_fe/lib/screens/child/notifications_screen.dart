import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notificationProvider =
        context.read<NotificationProvider>();
    await notificationProvider.loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              expandedHeight: 0,
              flexibleSpace: const FlexibleSpaceBar(
                background: SizedBox.shrink(),
              ),
              title: Text(
                'Thông báo',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: false,
              actions: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã xóa tất cả thông báo'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Center(
                      child: Text(
                        'Xóa tất cả',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.childPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, _) {
                  final notifications = notificationProvider.sortedNotifications;

                  if (notificationProvider.isLoading) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.childPrimary),
                        ),
                      ),
                    );
                  }

                  if (notifications.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 100),
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          SizedBox(height: AppSpacing.lg),
                          Text(
                            'Không có thông báo',
                            style: AppTypography.h3.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: AppSpacing.md),
                          Text(
                            'Tất cả thông báo sẽ được hiển thị ở đây',
                            style: AppTypography.caption.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: notifications
                          .map((notif) => _buildNotificationCard(notif))
                          .toList(),
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

  Widget _buildNotificationCard(NotificationItem notif) {
    Color getTypeColor() {
      switch (notif.category) {
        case NotificationCategory.alert:
          return AppColors.danger;
        case NotificationCategory.update:
          return AppColors.success;
        case NotificationCategory.warning:
          return AppColors.warning;
        case NotificationCategory.general:
          return AppColors.childPrimary;
      }
    }

    IconData getIcon() {
      switch (notif.category) {
        case NotificationCategory.alert:
          return Icons.error;
        case NotificationCategory.update:
          return Icons.check_circle;
        case NotificationCategory.warning:
          return Icons.warning;
        case NotificationCategory.general:
          return Icons.notifications;
      }
    }

    final typeColor = getTypeColor();
    final icon = getIcon();

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: typeColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: typeColor,
              size: 20,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (notif.description != null && notif.description!.isNotEmpty)
                  SizedBox(height: 4),
                if (notif.description != null && notif.description!.isNotEmpty)
                  Text(
                    notif.description!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 6),
                Text(
                  _getTimeAgo(notif.timestamp),
                  style: AppTypography.overline.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              final notificationProvider =
                  context.read<NotificationProvider>();
              notificationProvider.dismissNotification(notif.id);
            },
            child: Icon(
              Icons.close,
              size: 18,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${(difference.inDays / 30).toStringAsFixed(0)} tháng trước';
    }
  }
}
