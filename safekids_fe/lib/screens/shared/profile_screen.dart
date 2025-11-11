import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/empty_state_widget.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Hồ sơ')),
        body: Center(child: Text('Không có dữ liệu người dùng')),
      );
    }

    final isParent = user.role == 'parent';
    final linkedAccounts = user.linkedUsersData
        .where((u) => u['role'] == (isParent ? 'child' : 'parent'))
        .toList();
    final roleColor = isParent ? AppColors.parentPrimary : AppColors.childPrimary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              await authProvider.refreshUser();
            },
            color: roleColor,
            child: CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                // Modern AppBar with gradient header
                SliverAppBar(
                  expandedHeight: 240,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: Colors.white,
                  leading: Container(
                    margin: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.edit, color: roleColor),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.logout, color: AppColors.textSecondary),
                        onPressed: () {
                          _showLogoutDialog(context, authProvider);
                        },
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            roleColor,
                            roleColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Avatar
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                )
                              ],
                            ),
                            child: Center(
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: roleColor,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: AppSpacing.md),
                          // Name
                          Text(
                            user.name,
                            style: AppTypography.h2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacing.xs),
                          // Role badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              isParent ? 'Phụ Huynh' : 'Trẻ Em',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SizedBox(height: AppSpacing.lg),
                      _buildStatsSection(user, linkedAccounts, isParent, roleColor),
                      SizedBox(height: AppSpacing.lg),
                      _buildInfoSection(user, isParent, roleColor),
                      SizedBox(height: AppSpacing.lg),
                      _buildLinkedAccountsSection(
                        context,
                        linkedAccounts,
                        isParent,
                        roleColor,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      _buildSettingsSection(context, authProvider, roleColor),
                      SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(
    user,
    List linkedAccounts,
    bool isParent,
    Color roleColor,
  ) {
    final createdDate = user.createdAt != null
        ? DateFormat('dd/MM/yyyy').format(user.createdAt)
        : 'N/A';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              Icons.people_outline_rounded,
              linkedAccounts.length.toString(),
              isParent ? 'Trẻ em' : 'Phụ huynh',
              roleColor,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              Icons.calendar_today_rounded,
              createdDate,
              'Tham gia',
              roleColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(user, bool isParent, Color roleColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.sm),
            child: Text(
              'Thông tin cá nhân',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          if (user.email.isNotEmpty)
            _buildInfoRow(
              Icons.email_outlined,
              'Email',
              user.email,
              roleColor,
            ),
          if (user.phone != null && user.phone.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: _buildInfoRow(
                Icons.phone_outlined,
                'Số điện thoại',
                user.phone,
                roleColor,
              ),
            ),
          if (user.age != null)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: _buildInfoRow(
                Icons.cake_outlined,
                'Tuổi',
                '${user.age} tuổi',
                roleColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildLinkedAccountsSection(
    BuildContext context,
    List<Map<String, dynamic>> accounts,
    bool isParent,
    Color roleColor,
  ) {

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.08),
            blurRadius: AppSpacing.xs,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  isParent ? Icons.child_care : Icons.family_restroom,
                  color: roleColor,
                  size: AppSpacing.iconSm,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  isParent ? 'Con em được liên kết' : 'Phụ huynh đang theo dõi',
                  style: AppTypography.h3
                      .copyWith(color: AppColors.textPrimary)
                      .copyWith(letterSpacing: -0.3),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          if (accounts.isEmpty)
            EmptyStateWidget(
              icon: isParent
                  ? Icons.child_care_outlined
                  : Icons.family_restroom_outlined,
              title: isParent ? 'Chưa có liên kết nào' : 'Chưa có phụ huynh',
              message: isParent
                  ? 'Bạn chưa liên kết với tài khoản trẻ em nào.\nHãy thêm con em để bắt đầu theo dõi!'
                  : 'Tài khoản của bạn chưa được liên kết\nvới phụ huynh nào.',
              color: isParent
                  ? AppColors.parentSecondary
                  : AppColors.childPrimary,
            )
          else
            ...accounts
                .map((account) => _buildAccountCard(account, isParent))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account, bool isParent) {
    final avatarColor = isParent
        ? AppColors.childAccent
        : AppColors.parentPrimary;
    final accountId = account['_id'] ?? account['id'];

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Center(
                child: Text(
                  (account['name'] ?? 'U')[0].toUpperCase(),
                  style: AppTypography.h3.copyWith(color: avatarColor),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account['name'] ?? 'Unknown',
                    style: AppTypography.body
                        .copyWith(color: AppColors.textPrimary)
                        .copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    account['email'] ?? '',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showUnlinkDialog(context, accountId, account['name'] ?? 'Unknown'),
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUnlinkDialog(
    BuildContext context,
    String accountId,
    String accountName,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final shouldUnlink = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa liên kết'),
        content: Text('Bạn có chắc chắn muốn xóa liên kết với $accountName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Xóa',
              style: AppTypography.button.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (shouldUnlink == true) {
      try {
        final apiService = ApiService();
        await apiService.removeChildLink(accountId);
        await authProvider.refreshUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa liên kết với $accountName'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Widget _buildSettingsSection(
    BuildContext context,
    AuthProvider authProvider,
    Color roleColor,
  ) {
    return SizedBox.shrink();
  }

  void _showLogoutDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đăng xuất'),
        content: Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Đăng xuất',
              style: AppTypography.button.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await authProvider.logout();
    }
  }

}
