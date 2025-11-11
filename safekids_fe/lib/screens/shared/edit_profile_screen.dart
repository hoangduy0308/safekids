import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _initialName = '';
  String _initialPhone = '';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _initialName = user.fullName ?? '';
      _initialPhone = user.phone != null ? user.phone! : '';
      _nameController.text = _initialName;
      _phoneController.text = _initialPhone;
    }
  }

  bool _hasUnsavedChanges() {
    return _nameController.text != _initialName ||
        _phoneController.text != _initialPhone;
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hủy thay đổi?'),
        content: Text('Các thay đổi chưa lưu sẽ bị mất.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Tiếp tục chỉnh sửa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text('Hủy bỏ'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedUser = await ApiService().updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      // Update auth provider with new user data
      final authProvider = context.read<AuthProvider>();
      authProvider.updateUserData(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật thông tin'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Chỉnh Sửa Hồ Sơ')),
        body: Center(child: Text('Không có dữ liệu người dùng')),
      );
    }

    final isParent = user.role == 'parent';
    final roleColor = isParent
        ? AppColors.parentPrimary
        : AppColors.childPrimary;

    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges()) {
          return await _showDiscardDialog();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Stack(
          children: [
            SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                MediaQuery.of(context).padding.top + 60,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [roleColor, roleColor.withOpacity(0.5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'U',
                                style: AppTypography.h1
                                    .copyWith(color: roleColor)
                                    .copyWith(fontSize: 48),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl),

                    // Full Name Field
                    Text(
                      'Họ và Tên',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Semantics(
                      label: 'Họ và tên',
                      hint: 'Nhập họ và tên đầy đủ của bạn',
                      child: TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        maxLength: 50,
                        decoration: InputDecoration(
                          hintText: 'Nhập họ và tên',
                          hintStyle: AppTypography.body.copyWith(
                            color: AppColors.textLight,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          counterText: '${_nameController.text.length}/50',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            borderSide: BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            borderSide: BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            borderSide: BorderSide(color: roleColor, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập họ và tên';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),

                    // Phone Field
                    Text(
                      'Số Điện Thoại',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Semantics(
                      label: 'Số điện thoại',
                      hint: 'Nhập số điện thoại 10-15 chữ số',
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Nhập số điện thoại',
                          hintStyle: AppTypography.body.copyWith(
                            color: AppColors.textLight,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          helperText: '10-15 chữ số',
                          helperStyle: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            borderSide: BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            borderSide: BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            borderSide: BorderSide(color: roleColor, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final phoneRegex = RegExp(r'^[0-9]{10,15}$');
                            if (!phoneRegex.hasMatch(value.trim())) {
                              return 'Số điện thoại không hợp lệ';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),

                    // Email (read-only)
                    Text(
                      'Email (không thể thay đổi)',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: AppColors.textSecondary,
                            size: AppSpacing.iconSm,
                          ),
                          SizedBox(width: AppSpacing.md),
                          Text(
                            user.email,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),

                    // Role (read-only)
                    Text(
                      'Vai Trò (không thể thay đổi)',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: roleColor.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isParent ? Icons.family_restroom : Icons.child_care,
                            color: roleColor,
                            size: AppSpacing.iconSm,
                          ),
                          SizedBox(width: AppSpacing.md),
                          Text(
                            isParent ? 'Phụ Huynh' : 'Trẻ Em',
                            style: AppTypography.body
                                .copyWith(color: roleColor)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: AppSpacing.buttonHeightMd,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                HapticFeedback.mediumImpact();
                                _saveProfile();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: roleColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: AppSpacing.iconSm,
                                width: AppSpacing.iconSm,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Lưu Thay Đổi',
                                style: AppTypography.body
                                    .copyWith(color: Colors.white)
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating back button
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSpacing.sm,
              left: AppSpacing.sm,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor.withOpacity(0.1),
                      blurRadius: AppSpacing.sm,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    if (_hasUnsavedChanges()) {
                      final shouldPop = await _showDiscardDialog();
                      if (shouldPop && mounted) {
                        Navigator.pop(context);
                      }
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
