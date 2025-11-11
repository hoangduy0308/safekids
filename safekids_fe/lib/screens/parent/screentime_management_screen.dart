import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import './screentime_settings_screen.dart';
import './usage_reports_screen.dart';

/// Screen Time Management Screen - Parent Management Tab
/// Central hub for all screen time features (Stories 5.1-5.5)
/// Redesigned with realtime updates and visual status indicators
class ScreenTimeManagementScreen extends StatefulWidget {
  const ScreenTimeManagementScreen({Key? key}) : super(key: key);

  @override
  State<ScreenTimeManagementScreen> createState() =>
      _ScreenTimeManagementScreenState();
}

class _ScreenTimeManagementScreenState
    extends State<ScreenTimeManagementScreen> {
  List<Map<String, dynamic>> _children = [];
  Map<String, Map<String, dynamic>> _childUsage = {}; // childId → usage data
  bool _loading = true;
  bool _refreshing = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadChildren();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  /// Start auto-refresh timer (every 60 seconds)
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted && !_loading) {
        _refreshUsageData();
      }
    });
  }

  Future<void> _loadChildren() async {
    setState(() => _loading = true);

    try {
      final profile = await ApiService().getProfile();
      final linkedUsers = profile['linkedUsers'] as List?;
      _children = linkedUsers != null
          ? List<Map<String, dynamic>>.from(
              linkedUsers.where((u) => u['role'] == 'child'),
            )
          : [];

      // Load usage for each child
      await _loadUsageForAllChildren();

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: ${e.toString()}')),
        );
      }
    }
  }

  /// Load usage data for all children
  Future<void> _loadUsageForAllChildren() async {
    for (var child in _children) {
      final childId = child['_id'] as String;
      try {
        final usage = await ApiService().getTodayUsage(childId);
        final config = await ApiService().getScreenTimeConfig(childId);

        _childUsage[childId] = {
          ...usage,
          'dailyLimit': config['dailyLimitMinutes'] ?? 120,
          'bedtime': config['bedtime'],
          'wakeup': config['wakeup'],
        };
      } catch (e) {
        _childUsage[childId] = {
          'totalMinutes': 0,
          'sessions': [],
          'dailyLimit': 120,
        };
      }
    }
  }

  /// Refresh usage data (for auto-refresh and pull-to-refresh)
  Future<void> _refreshUsageData() async {
    setState(() => _refreshing = true);
    await _loadUsageForAllChildren();
    setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingState();
    }

    if (_children.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshUsageData,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Header
          Text(
            'Quản Lý Thời Gian Sử Dụng',
            style: AppTypography.h2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thiết lập giới hạn, xem báo cáo và nhận gợi ý thông minh',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Quick Actions Cards
          _buildQuickActionsSection(),

          const SizedBox(height: AppSpacing.xl),

          // Children List
          Text(
            'Trẻ Em Của Bạn',
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),

          // Realtime update indicator
          if (_refreshing)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đang cập nhật...',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          ..._children.map((child) => _buildChildUsageCard(child)),
        ],
      ),
    );
  }

  /// Build loading state with shimmer effect
  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildShimmerCard(height: 80),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildShimmerCard(height: 120)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildShimmerCard(height: 120)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildShimmerCard(height: 180),
        const SizedBox(height: AppSpacing.md),
        _buildShimmerCard(height: 180),
      ],
    );
  }

  Widget _buildShimmerCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.parentPrimary,
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Truy Cập Nhanh',
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.settings,
                title: 'Cài Đặt',
                subtitle: 'Giới hạn & Giờ ngủ',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScreenTimeSettingsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildActionCard(
                icon: Icons.bar_chart,
                title: 'Báo Cáo',
                subtitle: 'Thống kê chi tiết',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UsageReportsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build child usage card with realtime data and status
  Widget _buildChildUsageCard(Map<String, dynamic> child) {
    final childId = child['_id'] as String;
    final fullName =
        child['fullName'] as String? ?? child['name'] as String? ?? 'Unknown';
    final age = child['age'] as int?;
    final usage = _childUsage[childId];

    if (usage == null) {
      return _buildShimmerCard(height: 180);
    }

    final totalMinutes = usage['totalMinutes'] as int? ?? 0;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    // Get daily limit from config (loaded from database)
    final dailyLimit = usage['dailyLimit'] as int? ?? 120;
    final percent = dailyLimit > 0
        ? (totalMinutes / dailyLimit).clamp(0.0, 1.3)
        : 0.0;

    // Determine status
    final StatusInfo status = _getStatusInfo(percent);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + Name + Age + Usage
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.childPrimary.withOpacity(0.2),
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.childPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fullName,
                              style: AppTypography.label.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (age != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$age tuổi',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Hôm nay: ${hours}h ${minutes}p / ${dailyLimit ~/ 60}h',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_refreshing) ...[
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Badge
                _buildStatusBadge(status),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(status.color),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(percent * 100).toInt()}%',
                  style: AppTypography.caption.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Quick Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScreenTimeSettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Giới hạn'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.parentPrimary,
                      side: BorderSide(color: AppColors.parentPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UsageReportsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics, size: 18),
                    label: const Text('Báo cáo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get status info based on usage percentage
  StatusInfo _getStatusInfo(double percent) {
    if (percent >= 1.0) {
      return StatusInfo(
        label: 'Vượt giới hạn',
        icon: Icons.lock,
        color: AppColors.danger,
      );
    } else if (percent >= 0.9) {
      return StatusInfo(
        label: 'Cảnh báo',
        icon: Icons.warning,
        color: Colors.orange,
      );
    } else if (percent >= 0.7) {
      return StatusInfo(
        label: 'Gần đạt',
        icon: Icons.warning_amber,
        color: Colors.orange[300]!,
      );
    } else {
      return StatusInfo(
        label: 'Bình thường',
        icon: Icons.check_circle,
        color: AppColors.success,
      );
    }
  }

  /// Build status badge
  Widget _buildStatusBadge(StatusInfo status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: AppTypography.caption.copyWith(
              color: status.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chưa Có Trẻ Em',
              style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Liên kết với thiết bị của trẻ để bắt đầu quản lý thời gian sử dụng',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to link child flow
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chức năng liên kết trẻ em sẽ được thêm sau'),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Liên Kết Trẻ Em'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.parentPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status information for usage badges
class StatusInfo {
  final String label;
  final IconData icon;
  final Color color;

  StatusInfo({required this.label, required this.icon, required this.color});
}
