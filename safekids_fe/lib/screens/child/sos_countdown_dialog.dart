import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class SOSCountdownDialog extends StatefulWidget {
  final Duration duration;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const SOSCountdownDialog({
    Key? key,
    this.duration = const Duration(seconds: 3),
    required this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  @override
  State<SOSCountdownDialog> createState() => _SOSCountdownDialogState();
}

class _SOSCountdownDialogState extends State<SOSCountdownDialog>
    with TickerProviderStateMixin {
  late AnimationController _countdownController;
  late int _secondsRemaining;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.duration.inSeconds;

    _countdownController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _countdownController.addListener(_updateCountdown);
    _countdownController.addStatusListener(_onCountdownStatus);
    _countdownController.forward();
  }

  void _updateCountdown() {
    final elapsed =
        (_countdownController.value * widget.duration.inMilliseconds).toInt();
    final remaining = (widget.duration.inMilliseconds - elapsed) ~/ 1000;

    if (mounted && remaining != _secondsRemaining) {
      setState(() => _secondsRemaining = remaining);
    }
  }

  void _onCountdownStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_cancelled && mounted) {
      Navigator.pop(context);
      widget.onConfirm();
    }
  }

  void _handleCancel() {
    if (!_cancelled) {
      setState(() => _cancelled = true);
      _countdownController.stop();
      Navigator.pop(context);
      widget.onCancel?.call();
    }
  }

  @override
  void dispose() {
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.danger.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, size: 60, color: AppColors.danger),
              SizedBox(height: 16),
              Text(
                'Gửi cảnh báo khẩn cấp?',
                style: AppTypography.h2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Ba mẹ sẽ nhận được thông báo ngay lập tức',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),

              // Countdown Timer
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger.withOpacity(0.1),
                  border: Border.all(color: AppColors.danger, width: 3),
                ),
                child: Center(
                  child: Text(
                    _secondsRemaining.toString(),
                    style: AppTypography.h1.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'HỦY',
                    style: AppTypography.button.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
