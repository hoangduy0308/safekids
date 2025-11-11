import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class SOSSuccessScreen extends StatefulWidget {
  final List<String> parentNames;
  final VoidCallback onDismiss;
  final String? sosId;
  final DateTime? sosTimestamp;

  const SOSSuccessScreen({
    Key? key,
    required this.parentNames,
    required this.onDismiss,
    this.sosId,
    this.sosTimestamp,
  }) : super(key: key);

  @override
  State<SOSSuccessScreen> createState() => _SOSSuccessScreenState();
}

class _SOSSuccessScreenState extends State<SOSSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ApiService _apiService = ApiService();
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _animationController.forward();

    Future.delayed(Duration(seconds: 5), () {
      if (mounted) Navigator.pop(context);
    });
  }

  bool _canCancel() {
    if (widget.sosId == null || widget.sosTimestamp == null) return false;
    final timeSince = DateTime.now().difference(widget.sosTimestamp!);
    return timeSince.inMinutes <= 5;
  }

  Future<void> _cancelSOS() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hủy Cảnh Báo SOS'),
        content: Text(
          'Bạn có chắc muốn hủy cảnh báo SOS này? Ba mẹ sẽ được thông báo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Hủy SOS'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _cancelling = true);

    try {
      await _apiService.updateSOSStatus(
        widget.sosId!,
        'false_alarm',
        reason: 'accidental',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã hủy cảnh báo. Ba mẹ đã được thông báo.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Không thể hủy: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(color: AppColors.success.withOpacity(0.1)),

          // Content
          Center(
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withOpacity(0.2),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 80,
                      color: AppColors.success,
                    ),
                  ),

                  SizedBox(height: 24),

                  // Message
                  Text(
                    '✅ Đã gửi cảnh báo',
                    style: AppTypography.h1.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 16),

                  // Parents notified
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(
                          'Ba mẹ đã nhận được thông báo:',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        ...widget.parentNames
                            .map(
                              (name) => Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: AppColors.success,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      name,
                                      style: AppTypography.label.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Cancel button (AC 4.4.2)
                  if (_canCancel())
                    Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: ElevatedButton.icon(
                        onPressed: _cancelling ? null : _cancelSOS,
                        icon: _cancelling
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.cancel),
                        label: Text(
                          _cancelling ? 'Đang hủy...' : 'HỦY CẢNH BÁO',
                          style: AppTypography.button.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  // Close button
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Đóng',
                      style: AppTypography.button.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
