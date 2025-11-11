import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class LinkChildScreen extends StatefulWidget {
  const LinkChildScreen({Key? key}) : super(key: key);

  @override
  State<LinkChildScreen> createState() => _LinkChildScreenState();
}

class _LinkChildScreenState extends State<LinkChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await ApiService().sendLinkRequest(
        _emailController.text.trim(),
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã gửi yêu cầu! Chờ trẻ em chấp nhận.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${e.toString()}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
        title: Text('Liên Kết Tài Khoản Trẻ Em'),
        backgroundColor: AppColors.parentPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.md),

                // Linked Children Section
                _buildLinkedChildrenSection(),

                SizedBox(height: AppSpacing.xl),

                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.parentSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    Icons.link,
                    size: AppSpacing.iconXl,
                    color: AppColors.parentSecondary,
                  ),
                ),

                SizedBox(height: AppSpacing.lg),

                // Title
                Text(
                  'Liên kết với con em',
                  style: AppTypography.h2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),

                // Description
                Text(
                  'Gửi yêu cầu liên kết đến tài khoản trẻ em. Con em cần chấp nhận yêu cầu để hoàn tất kết nối.',
                  style: AppTypography.body
                      .copyWith(color: AppColors.textSecondary)
                      .copyWith(fontSize: 15),
                ),

                SizedBox(height: AppSpacing.xl),

                // Email Field
                _buildEmailField(),

                SizedBox(height: AppSpacing.md),

                // Message Field (Optional)
                _buildMessageField(),

                SizedBox(height: AppSpacing.lg),

                // Send Request Button
                _buildSendButton(),

                SizedBox(height: AppSpacing.md),

                // Info Card
                _buildInfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email của trẻ em',
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textPrimary)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'child@email.com',
            hintStyle: AppTypography.body.copyWith(color: AppColors.textLight),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: AppColors.parentSecondary,
              size: AppSpacing.iconSm,
            ),
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
              borderSide: BorderSide(
                color: AppColors.parentSecondary,
                width: 2,
              ),
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
      ],
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lời nhắn (tùy chọn)',
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textPrimary)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _messageController,
          maxLength: 200,
          maxLines: 3,
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Viết lời nhắn cho con em...',
            hintStyle: AppTypography.body.copyWith(color: AppColors.textLight),
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
              borderSide: BorderSide(
                color: AppColors.parentSecondary,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      height: AppSpacing.buttonHeightMd,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSendRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.parentSecondary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.parentSecondary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          disabledBackgroundColor: AppColors.buttonDisabled,
        ),
        child: _isLoading
            ? SizedBox(
                height: AppSpacing.iconSm,
                width: AppSpacing.iconSm,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Gửi Yêu Cầu',
                style: AppTypography.body
                    .copyWith(color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3),
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.info.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.info,
            size: AppSpacing.iconSm,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Trẻ em sẽ nhận được thông báo và cần chấp nhận yêu cầu để hoàn tất liên kết.',
              style: AppTypography.caption
                  .copyWith(color: AppColors.info)
                  .copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedChildrenSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Get linked children from AuthProvider
        final linkedChildren = authProvider.user?.linkedUsersData ?? [];

        // Filter for children only (role == 'child')
        final childrenList = linkedChildren
            .where((user) => user['role'] == 'child')
            .toList();

        if (childrenList.isEmpty) {
          return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Các con em đã liên kết',
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            ),
            SizedBox(height: AppSpacing.md),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: childrenList.length,
              itemBuilder: (context, index) {
                final child = childrenList[index];
                final name = child['name'] ?? child['fullName'] ?? 'Unknown';
                final email = child['email'] ?? '';
                final initial = name.isNotEmpty
                    ? name.substring(0, 1).toUpperCase()
                    : '?';

                return ListTile(
                  leading: CircleAvatar(child: Text(initial)),
                  title: Text(name),
                  subtitle: Text(email),
                  trailing: Icon(Icons.check_circle, color: AppColors.success),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
