import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../parent/parent_dashboard_screen.dart';
import '../child/child_home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Save BuildContext before async call
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success) {
      // Navigate to appropriate screen based on user role
      if (!mounted) return;

      final isParent = authProvider.isParent;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isParent
              ? const ParentDashboardScreen()
              : const ChildHomeScreen(),
        ),
      );
    } else {
      final errorMsg = authProvider.errorMessage ?? 'Đăng nhập thất bại';

      // Show error using saved ScaffoldMessenger (works even if widget unmounts)
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMsg,
                  style: AppTypography.subtitle.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(seconds: 4),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Spacer
                  SizedBox(height: screenHeight * 0.08),

                  // Logo & Brand
                  _buildHeader(),

                  // Spacer
                  SizedBox(height: screenHeight * 0.06),

                  // Login Form Card
                  _buildLoginForm(),

                  // Bottom Actions
                  SizedBox(height: 24),
                  _buildRegisterLink(),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Modern Shield Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.parentPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Icon(
            Icons.shield_outlined,
            size: AppSpacing.iconXl,
            color: AppColors.parentPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.lg),

        // App Name
        Text('SafeKids', style: AppTypography.h1),
        SizedBox(height: AppSpacing.xs),

        // Tagline
        Text(
          'Bảo vệ con em, An tâm cha mẹ',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
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
          // Form Title
          Text('Đăng nhập', style: AppTypography.h2),
          SizedBox(height: AppSpacing.xl),

          // Email Field
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'example@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!value.contains('@')) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
          SizedBox(height: AppSpacing.md),

          // Password Field
          _buildTextField(
            controller: _passwordController,
            label: 'Mật khẩu',
            hint: 'Nhập mật khẩu',
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              if (value.length < 6) {
                return 'Mật khẩu phải có ít nhất 6 ký tự';
              }
              return null;
            },
          ),

          // Forgot Password Link
          SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Quên mật khẩu?',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.parentPrimary)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          SizedBox(height: AppSpacing.xl),

          // Login Button
          _buildLoginButton(),
        ],
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
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: AppTypography.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.textLight,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: AppColors.parentPrimary,
              size: AppSpacing.iconSm,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderLight, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: AppColors.parentPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.danger, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.danger, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          height: AppSpacing.buttonHeightMd,
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.parentPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: AppColors.parentPrimary.withOpacity(0.3),
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
                    'Đăng nhập',
                    style: AppTypography.buttonLarge.copyWith(
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản? ',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            minimumSize: Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Đăng ký ngay',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.parentPrimary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.parentPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
