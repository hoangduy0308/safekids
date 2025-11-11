import 'package:flutter/material.dart';
import 'dart:ui';
import '../../providers/notification_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import 'notification_item.dart';

class NotificationPanel extends StatefulWidget {
  final NotificationProvider notificationProvider;
  final VoidCallback onClose;

  const NotificationPanel({
    Key? key,
    required this.notificationProvider,
    required this.onClose,
  }) : super(key: key);

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
          ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(AppSpacing.radiusLg),
              bottomRight: Radius.circular(AppSpacing.radiusLg),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.95),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.parentPrimary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.parentPrimary.withOpacity(0.05),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thông báo (${widget.notificationProvider.unreadCount})',
                          style: AppTypography.h4,
                        ),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Body - Notifications List
                  Expanded(
                    child: widget.notificationProvider.notifications.isEmpty
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                children: [
                                  ...widget
                                      .notificationProvider
                                      .sortedNotifications
                                      .map((notification) {
                                        return NotificationItemWidget(
                                          item: notification,
                                          onDismiss: () {
                                            widget.notificationProvider
                                                .dismissNotification(
                                                  notification.id,
                                                );
                                          },
                                          onAction: () {
                                            widget.notificationProvider
                                                .markAsRead(notification.id);
                                          },
                                        );
                                      })
                                      .toList(),
                                ],
                              ),
                            ),
                          ),
                  ),
                  // Footer
                  if (widget.notificationProvider.notifications.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Navigate to full notifications page
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_forward, size: 16),
                              SizedBox(width: AppSpacing.sm),
                              Text('Xem tất cả'),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 48,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Không có thông báo mới',
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Bạn sẽ nhận được thông báo khi có cập nhật',
              style: AppTypography.captionSmall,
            ),
          ],
        ),
      ),
    );
  }
}
