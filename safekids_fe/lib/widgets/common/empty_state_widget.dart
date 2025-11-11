import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? color;

  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emptyColor = color ?? AppColors.textSecondary;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon container
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: emptyColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: emptyColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(icon, size: 48, color: emptyColor.withOpacity(0.8)),
              ),
            ),

            SizedBox(height: 24),

            // Title
            Text(
              title,
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 8),

            // Message
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button (optional)
            if (actionText != null && onAction != null) ...[
              SizedBox(height: 24),
              TextButton.icon(
                onPressed: onAction,
                icon: Icon(Icons.add, size: 20),
                label: Text(
                  actionText!,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: emptyColor,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: emptyColor.withOpacity(0.3)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
