import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_typography.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _otpSent = false;
  bool _obscurePassword = true;
  String _selectedMethod = 'email'; // 'email' or 'sms'
  String _contactInfo = ''; // Store email or phone after sending

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestOTP() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    // Get contact info based on method
    final contactInfo = _selectedMethod == 'email'
        ? _emailController.text.trim()
        : _phoneController.text.trim();

    final result = await authProvider.forgotPassword(
      contactInfo,
      _selectedMethod,
    );

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _otpSent = true;
        _contactInfo = contactInfo;
      });

      final method = result['data']['method'];
      final message = method == 'email'
          ? 'Mã OTP đã được gửi đến email của bạn'
          : 'Mã OTP đã được gửi đến số điện thoại của bạn';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Yêu cầu thất bại'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (_otpController.text.isEmpty || _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mã OTP phải là 6 chữ số'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mật khẩu phải có ít nhất 6 ký tự'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.resetPassword(
      _contactInfo,
      _otpController.text.trim(),
      _newPasswordController.text,
      _selectedMethod,
    );

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đặt lại mật khẩu thành công!'),
          backgroundColor: AppColors.success,
        ),
      );

      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Đặt lại mật khẩu thất bại'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                SizedBox(height: AppSpacing.xxl),

                if (!_otpSent) ...[_buildEmailStep()] else ...[_buildOTPStep()],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.parentPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            Icons.lock_reset,
            size: AppSpacing.iconLg,
            color: AppColors.parentPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.md),

        Text(
          _otpSent ? 'Xác thực OTP' : 'Quên mật khẩu',
          style: AppTypography.h1,
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          _otpSent
              ? 'Nhập mã OTP và mật khẩu mới'
              : 'Chọn phương thức nhận mã OTP',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.parentPrimary.withOpacity(0.08),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Method selection
          Text('Chọn phương thức nhận mã OTP', style: AppTypography.label),
          SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _buildMethodCard(
                  icon: Icons.email,
                  label: 'Email',
                  value: 'email',
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildMethodCard(
                  icon: Icons.sms,
                  label: 'SMS',
                  value: 'sms',
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.md),

          // Conditional input based on method
          if (_selectedMethod == 'email')
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'example@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@[\w-]+\.[a-zA-Z]{2,}$',
                ).hasMatch(value.trim())) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            )
          else
            _buildTextField(
              controller: _phoneController,
              label: 'Số điện thoại',
              hint: '0912345678',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value.trim())) {
                  return 'Số điện thoại không hợp lệ (10-15 chữ số)';
                }
                return null;
              },
            ),

          SizedBox(height: AppSpacing.xl),

          _buildButton(text: 'Gửi mã OTP', onPressed: _requestOTP),
        ],
      ),
    );
  }

  Widget _buildOTPStep() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.parentPrimary.withOpacity(0.08),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _otpController,
            label: 'Mã OTP',
            hint: 'Nhập 6 chữ số',
            prefixIcon: Icons.vpn_key_outlined,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: AppSpacing.md),

          _buildTextField(
            controller: _newPasswordController,
            label: 'Mật khẩu mới',
            hint: 'Ít nhất 6 ký tự',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textLight,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          SizedBox(height: AppSpacing.xl),

          _buildButton(text: 'Đặt lại mật khẩu', onPressed: _resetPassword),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isSelected = _selectedMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.parentPrimary.withOpacity(0.1)
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.parentPrimary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.parentPrimary : AppColors.textLight,
              size: 28,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected
                    ? AppColors.parentPrimary
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          style: AppTypography.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body.copyWith(color: AppColors.textLight),
            prefixIcon: Icon(
              prefixIcon,
              color: AppColors.parentPrimary,
              size: AppSpacing.iconSm,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: readOnly
                ? AppColors.borderLight
                : AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: AppColors.borderLight, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: AppColors.parentPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: AppColors.danger, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: AppColors.danger, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          height: AppSpacing.buttonHeightMd,
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.parentPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              disabledBackgroundColor: AppColors.buttonDisabled,
            ),
            child: authProvider.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    text,
                    style: AppTypography.buttonLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
