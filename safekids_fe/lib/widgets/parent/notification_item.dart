import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';

class NotificationItemWidget extends StatefulWidget {
  final NotificationItem item;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;

  const NotificationItemWidget({
    Key? key,
    required this.item,
    required this.onDismiss,
    this.onAction,
  }) : super(key: key);

  @override
  State<NotificationItemWidget> createState() => _NotificationItemWidgetState();
}

class _NotificationItemWidgetState extends State<NotificationItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _dismissController;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _dismissController.dispose();
    super.dispose();
  }

  Color _getCategoryColor() {
    switch (widget.item.category) {
      case NotificationCategory.alert:
        return AppColors.danger;
      case NotificationCategory.update:
        return AppColors.info;
      case NotificationCategory.warning:
        return AppColors.warning;
      case NotificationCategory.general:
        return AppColors.textTertiary;
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.item.category) {
      case NotificationCategory.alert:
        return Icons.warning;
      case NotificationCategory.update:
        return Icons.info;
      case NotificationCategory.warning:
        return Icons.notifications;
      case NotificationCategory.general:
        return Icons.description;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else {
      return '${diff.inDays} ngày trước';
    }
  }

  void _dismiss() async {
    await _dismissController.forward();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();
    final isAlert = widget.item.category == NotificationCategory.alert;

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(1.5, 0),
      ).animate(_dismissController),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(_dismissController),
        child: Container(
          margin: EdgeInsets.only(bottom: AppSpacing.sm),
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isAlert ? categoryColor : AppColors.divider,
              width: isAlert ? 2 : 1,
            ),
            boxShadow: isAlert
                ? [
                    BoxShadow(
                      color: categoryColor.withOpacity(0.15),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Content + Timestamp + Close
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: categoryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: isAlert
                          ? [
                              BoxShadow(
                                color: categoryColor.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: categoryColor,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  // Main Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.item.childName} ${widget.item.title}',
                          style: AppTypography.label.copyWith(
                            fontWeight: isAlert
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isAlert
                                ? AppColors.danger
                                : AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.item.description != null) ...[
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.item.description!,
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  // Timestamp + Close
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(widget.item.timestamp),
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Action Buttons
              if (widget.item.actionLabel != null) ...[
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onAction?.call();
                          _dismiss();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: categoryColor.withOpacity(0.15),
                          foregroundColor: categoryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                            side: BorderSide(
                              color: categoryColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.place, size: 16),
                            SizedBox(width: 6),
                            Text(widget.item.actionLabel!),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: _dismiss,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(
                          color: AppColors.divider,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      child: Text('Tắt'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
