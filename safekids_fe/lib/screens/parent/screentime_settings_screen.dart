import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/parent/screentime_suggestions_widget.dart';
import 'edit_screentime_limit_screen.dart';

class ScreenTimeSettingsScreen extends StatefulWidget {
  @override
  _ScreenTimeSettingsScreenState createState() =>
      _ScreenTimeSettingsScreenState();
}

class _ScreenTimeSettingsScreenState extends State<ScreenTimeSettingsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _children = [];
  Map<String, Map<String, dynamic>> _childUsage = {};
  String? _error;
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

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        _refreshUsageData();
      }
    });
  }

  Future<void> _refreshUsageData() async {
    print(
      '[ScreenTimeSettings] Refreshing usage data for ${_children.length} children',
    );
    for (var child in _children) {
      final childId = child['_id'] as String?;
      final childName = child['name'] ?? child['fullName'] ?? 'Unknown';

      if (childId == null) {
        print('[ScreenTimeSettings] Skipping child with null ID: $childName');
        continue;
      }

      try {
        final usage = await ApiService().getTodayUsage(childId);
        print(
          '[ScreenTimeSettings] Refreshed usage for $childName: ${usage['totalMinutes']}',
        );
        setState(() {
          _childUsage[childId] = usage;
        });
      } catch (e) {
        print('[ScreenTimeSettings] Error refreshing usage for $childName: $e');
        // Continue on error
      }
    }
  }

  Future<void> _loadChildren() async {
    try {
      // Load children from user profile API
      final profile = await ApiService().getProfile();
      print('[ScreenTimeSettings] Profile loaded: ${profile.keys}');

      final linkedUsers = profile['linkedUsers'] as List?;
      print('[ScreenTimeSettings] Linked users: ${linkedUsers?.length ?? 0}');

      final children = linkedUsers != null
          ? linkedUsers
                .whereType<Map<String, dynamic>>()
                .where((u) => u['role'] == 'child')
                .toList()
          : [];

      print('[ScreenTimeSettings] Found ${children.length} children');

      setState(() {
        _children = List<Map<String, dynamic>>.from(children);
        _loading = false;
      });

      print('[ScreenTimeSettings] Children set, starting to load data');

      // Load config, usage, and suggestions for each child
      for (int i = 0; i < _children.length; i++) {
        try {
          final childId = _children[i]['_id'] as String?;
          if (childId == null) continue;

          // Load today's usage
          final usage = await ApiService().getTodayUsage(childId);
          final childName =
              _children[i]['name'] ?? _children[i]['fullName'] ?? 'Unknown';
          print(
            '[ScreenTimeSettings] Loaded usage for $childName: totalMinutes=${usage['totalMinutes']}',
          );
          _childUsage[childId] = Map<String, dynamic>.from(usage);

          // Load screen time config
          final config = await ApiService().getScreenTimeConfig(childId);
          _children[i]['config'] = Map<String, dynamic>.from(config);

          // Load suggestions
          final suggestions = await ApiService().getScreenTimeSuggestions(
            childId,
          );
          _children[i]['suggestions'] = suggestions;

          setState(() {
            _children = [..._children]; // Trigger rebuild
          });
        } catch (e) {
          final childId = _children[i]['_id'] as String?;
          final childName = _children[i]['name'] ?? 'Unknown';
          print('[ScreenTimeSettings] Failed to load data for $childName: $e');
          if (childId != null) {
            _childUsage[childId] = {'totalMinutes': 0, 'sessions': []};
          }
          // Continue without full data
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Không thể tải dữ liệu: ${e.toString()}';
        _loading = false;
      });
    }
  }

  Future<void> _onApplySuggestion() async {
    // Refresh children data when suggestion applied
    await _loadChildren();
  }

  Widget _buildChildCard(Map<String, dynamic> child) {
    final childId = child['_id'] as String? ?? '';
    final childName =
        child['fullName'] as String? ?? child['name'] as String? ?? 'Unknown';
    final childAge = child['age'] as int?;

    // Safely convert totalMinutes from any type (int, double, string)
    final usage = _childUsage[childId];
    int totalMinutes = 0;
    try {
      final val = usage?['totalMinutes'];
      if (val is int) {
        totalMinutes = val;
      } else if (val is double) {
        totalMinutes = val.toInt();
      } else if (val is String) {
        totalMinutes = int.tryParse(val) ?? 0;
      }
    } catch (e) {
      print('[ScreenTimeCard] Error parsing totalMinutes: $e');
      totalMinutes = 0;
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    // Get daily limit from config - safely convert
    final config = child['config'] as Map<String, dynamic>?;
    int dailyLimit = 120;
    try {
      final val = config?['dailyLimitMinutes'];
      if (val is int) {
        dailyLimit = val;
      } else if (val is double) {
        dailyLimit = val.toInt();
      } else if (val is String) {
        dailyLimit = int.tryParse(val) ?? 120;
      }
    } catch (e) {
      print('[ScreenTimeCard] Error parsing dailyLimit: $e');
      dailyLimit = 120;
    }

    final percent = dailyLimit > 0
        ? (totalMinutes / dailyLimit).clamp(0.0, 1.3)
        : 0.0;

    // Get status color
    Color statusColor = Colors.green;
    if (percent >= 1.0) {
      statusColor = Colors.red;
    } else if (percent >= 0.9) {
      statusColor = Colors.orange;
    } else if (percent >= 0.7) {
      statusColor = Colors.orange[300]!;
    }

    print(
      '[ScreenTimeCard] Card: $childName, usage=$totalMinutes min, limit=$dailyLimit min, percent=${(percent * 100).toInt()}%',
    );

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.childPrimary.withOpacity(0.1),
                  child: Icon(
                    Icons.child_care,
                    color: AppColors.childPrimary,
                    size: 30,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childName,
                        style: AppTypography.h3.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxs),
                      if (childAge != null)
                        Text(
                          '$childAge tuổi',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      SizedBox(height: 4),
                      Text(
                        'Hôm nay: ${hours}h ${minutes}p / ${dailyLimit ~/ 60}h',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Percent display
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(percent * 100).toInt()}%',
                    style: AppTypography.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildQuickButton(
                    icon: Icons.access_time,
                    label: 'Giới hạn',
                    color: AppColors.parentPrimary,
                    onTap: () => _showLimitDialog(child),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildQuickButton(
                    icon: Icons.nightlight_round,
                    label: 'Giờ ngủ',
                    color: AppColors.parentAccent,
                    onTap: () => _showBedtimeDialog(child),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildQuickButton(
                    icon: Icons.analytics,
                    label: 'Báo cáo',
                    color: AppColors.success,
                    onTap: () => _showReportsDialog(child),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppSpacing.iconSm),
            SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.caption
                  .copyWith(color: color)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLimitDialog(Map<String, dynamic> child) async {
    // Navigate to edit screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditScreenTimeLimitScreen(child: child),
      ),
    );

    // Reload if config was saved
    if (result == true) {
      _loadChildren();
    }
  }

  Future<void> _showBedtimeDialog(Map<String, dynamic> child) async {
    // Navigate to edit screen (same as limit, just opens with bedtime section visible)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditScreenTimeLimitScreen(child: child),
      ),
    );

    // Reload if config was saved
    if (result == true) {
      _loadChildren();
    }
  }

  Future<void> _showReportsDialog(Map<String, dynamic> child) async {
    // Implementation for showing reports
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Báo cáo sử dụng'),
        content: Text('Tính năng đang được phát triển'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý Thời gian sử dụng'),
        backgroundColor: AppColors.parentPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.parentPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Đang tải dữ liệu...',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: AppSpacing.iconXl,
                    color: AppColors.danger,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: _loadChildren,
                    icon: Icon(Icons.refresh),
                    label: Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.parentPrimary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : _children.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: AppSpacing.iconXl,
                    color: AppColors.textLight,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Chưa có con nào được liên kết',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadChildren,
              color: AppColors.parentPrimary,
              child: ListView.builder(
                padding: EdgeInsets.all(AppSpacing.md),
                itemCount: _children.length,
                itemBuilder: (context, index) {
                  final child = _children[index];

                  return Column(
                    children: [
                      // Suggestions widget
                      if (child['suggestions'] != null)
                        ScreenTimeSuggestionsWidget(
                          childId: child['_id'],
                          suggestions: child['suggestions'],
                          onApplySuggestion: _onApplySuggestion,
                        ),

                      SizedBox(height: AppSpacing.md),

                      // Existing child card
                      _buildChildCard(child),

                      SizedBox(height: AppSpacing.lg),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
