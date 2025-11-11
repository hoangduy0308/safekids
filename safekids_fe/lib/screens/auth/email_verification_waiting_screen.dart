import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'login_screen.dart';

class EmailVerificationWaitingScreen extends StatefulWidget {
  final String email;
  final String? userName;

  const EmailVerificationWaitingScreen({
    Key? key,
    required this.email,
    this.userName,
  }) : super(key: key);

  @override
  State<EmailVerificationWaitingScreen> createState() =>
      _EmailVerificationWaitingScreenState();
}

class _EmailVerificationWaitingScreenState
    extends State<EmailVerificationWaitingScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendVerification() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() => _isResending = true);
    HapticFeedback.lightImpact();

    try {
      await _apiService.resendVerification(widget.email);

      if (!mounted) return;

      _startResendCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Email xác thực đã được gửi lại!')),
            ],
          ),
          backgroundColor: AppColors.success.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _goToLogin() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xxl),
              _buildEmailIcon(),
              SizedBox(height: AppSpacing.xl),
              _buildTitle(),
              SizedBox(height: AppSpacing.md),
              _buildMessage(),
              SizedBox(height: AppSpacing.xxl),
              _buildInfoCard(),
              SizedBox(height: AppSpacing.xl),
              _buildResendButton(),
              SizedBox(height: AppSpacing.md),
              _buildLoginButton(),
              SizedBox(height: AppSpacing.xl),
              _buildHelpText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailIcon() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.parentPrimary,
              AppColors.parentPrimary.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.parentPrimary.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          Icons.mark_email_unread_outlined,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Kiểm tra email của bạn',
      style: AppTypography.h1.copyWith(
        color: AppColors.textPrimary,
        fontSize: 28,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage() {
    return Column(
      children: [
        Text(
          'Chúng tôi đã gửi email xác thực đến:',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xs),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.parentPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Text(
            widget.email,
            style: AppTypography.body.copyWith(
              color: AppColors.parentPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 24),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Hướng dẫn',
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _buildInfoStep(
            '1',
            'Mở email từ SafeKids',
            'Kiểm tra hộp thư đến hoặc spam',
          ),
          SizedBox(height: AppSpacing.sm),
          _buildInfoStep(
            '2',
            'Nhấn vào nút "Xác thực Email"',
            'Email có hiệu lực trong 24 giờ',
          ),
          SizedBox(height: AppSpacing.sm),
          _buildInfoStep(
            '3',
            'Quay lại app và đăng nhập',
            'Sau khi xác thực thành công',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep(String number, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.parentPrimary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTypography.body.copyWith(
                color: AppColors.parentPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResendButton() {
    final bool canResend = _resendCountdown == 0 && !_isResending;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canResend ? _resendVerification : null,
        icon: _isResending
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.refresh),
        label: Text(
          _isResending
              ? 'Đang gửi...'
              : _resendCountdown > 0
              ? 'Gửi lại sau ${_resendCountdown}s'
              : 'Gửi lại email',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canResend
              ? AppColors.parentPrimary
              : AppColors.textSecondary.withOpacity(0.3),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _goToLogin,
        icon: Icon(Icons.login),
        label: Text('Đã xác thực, đăng nhập ngay'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.parentPrimary,
          side: BorderSide(color: AppColors.parentPrimary, width: 2),
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpText() {
    return Column(
      children: [
        Text(
          'Không nhận được email?',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'Kiểm tra thư mục spam hoặc nhấn "Gửi lại email"',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
