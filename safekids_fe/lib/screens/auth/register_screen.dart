import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../theme/app_typography.dart';
import 'email_verification_waiting_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();

  String _selectedRole = 'parent';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.register(
      name: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      role: _selectedRole,
      age: _selectedRole == 'child' && _ageController.text.isNotEmpty
          ? int.tryParse(_ageController.text)
          : null,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to email verification waiting screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EmailVerificationWaitingScreen(
            email: _emailController.text.trim(),
            userName: _fullNameController.text.trim(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Đăng ký thất bại'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(),
                SizedBox(height: AppSpacing.xxl),

                // Registration Form
                _buildRegistrationForm(),

                SizedBox(height: AppSpacing.xl),

                // Login Link
                _buildLoginLink(),
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
        // Small Logo
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.parentPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            Icons.shield_outlined,
            size: AppSpacing.iconLg,
            color: AppColors.parentPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.md),

        Text('Tạo tài khoản', style: AppTypography.h1),
        SizedBox(height: AppSpacing.xs),
        Text(
          'Điền thông tin để bắt đầu',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
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
          // Full Name
          _buildTextField(
            controller: _fullNameController,
            label: 'Họ và tên',
            hint: 'Nguyễn Văn A',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập họ và tên';
              }
              if (value.trim().length < 2) {
                return 'Họ và tên phải có ít nhất 2 ký tự';
              }
              return null;
            },
          ),
          SizedBox(height: AppSpacing.md),

          // Email
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
          ),
          SizedBox(height: 16),

          // Password
          _buildTextField(
            controller: _passwordController,
            label: 'Mật khẩu',
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
          SizedBox(height: 16),

          // Phone
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
          SizedBox(height: 16),

          // Role Selection
          _buildRoleSelector(),

          // Age (conditional for child)
          if (_selectedRole == 'child') ...[
            SizedBox(height: 16),
            _buildTextField(
              controller: _ageController,
              label: 'Tuổi',
              hint: 'Từ 6-17 tuổi',
              prefixIcon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_selectedRole == 'child') {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tuổi';
                  }
                  final age = int.tryParse(value);
                  if (age == null) {
                    return 'Tuổi phải là số';
                  }
                  if (age < 6 || age > 17) {
                    return 'Tuổi phải từ 6-17';
                  }
                }
                return null;
              },
            ),
          ],

          SizedBox(height: AppSpacing.xl),

          // Register Button
          _buildRegisterButton(),
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
        SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
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
            fillColor: AppColors.inputBackground,
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

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn vai trò', style: AppTypography.label),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                icon: Icons.family_restroom,
                label: 'Phụ huynh',
                value: 'parent',
                color: AppColors.parentPrimary,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildRoleCard(
                icon: Icons.child_care,
                label: 'Con em',
                value: 'child',
                color: AppColors.childPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isSelected = _selectedRole == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? color : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textLight,
              size: AppSpacing.iconLg,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodySmall
                  .copyWith(color: isSelected ? color : AppColors.textSecondary)
                  .copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          height: AppSpacing.buttonHeightMd,
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleRegister,
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
                    'Đăng ký',
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

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            minimumSize: Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Đăng nhập',
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
