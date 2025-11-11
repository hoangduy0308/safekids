import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class NotificationBadge extends StatefulWidget {
  final int count;

  const NotificationBadge({Key? key, required this.count}) : super(key: key);

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    if (widget.count > 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > 0 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.count == 0 && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count == 0) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.danger,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surface, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.danger.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.count > 9 ? '9+' : widget.count.toString(),
            style: AppTypography.buttonSmall.copyWith(
              color: AppColors.textWhite,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
