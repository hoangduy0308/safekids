import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class TimeManagementScreen extends StatefulWidget {
  const TimeManagementScreen({Key? key}) : super(key: key);

  @override
  State<TimeManagementScreen> createState() => _TimeManagementScreenState();
}

class _TimeManagementScreenState extends State<TimeManagementScreen> {
  final _apiService = ApiService();
  
  late Future<void> _loadDataFuture;

  @override
  void initState() {
    super.initState();
    _loadDataFuture = _loadUsageData();
  }

  Future<void> _loadUsageData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final childId = authProvider.user?.id;
      
      if (childId != null) {
        await _apiService.getTodayUsage(childId);
        await _getWeeklyUsageData();
        await _getMonthlyUsageData();
      }
    } catch (e) {
      print('Error loading usage data: $e');
    }
  }

  Future<Map<String, dynamic>> _getWeeklyUsageData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final childId = authProvider.user?.id;
      
      if (childId == null) return {};

      final now = DateTime.now();
      final weekAgo = now.subtract(Duration(days: 7));
      
      final startDate = _formatDate(weekAgo);
      final endDate = _formatDate(now);
      
      final data = await _apiService.getUsageStats(
        childId: childId,
        startDate: startDate,
        endDate: endDate,
      );
      return data;
    } catch (e) {
      print('Error getting weekly usage: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getMonthlyUsageData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final childId = authProvider.user?.id;
      
      if (childId == null) return {};

      final now = DateTime.now();
      final monthAgo = DateTime(now.year, now.month - 1, now.day);
      
      final startDate = _formatDate(monthAgo);
      final endDate = _formatDate(now);
      
      final data = await _apiService.getUsageStats(
        childId: childId,
        startDate: startDate,
        endDate: endDate,
      );
      return data;
    } catch (e) {
      print('Error getting monthly usage: $e');
      return {};
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              expandedHeight: 0,
              flexibleSpace: const FlexibleSpaceBar(
                background: SizedBox.shrink(),
              ),
              title: Text(
                'Thời gian sử dụng',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: false,
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<void>(
                future: _loadDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(AppColors.childPrimary),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Lỗi tải dữ liệu: ${snapshot.error}',
                        style: AppTypography.caption.copyWith(color: AppColors.danger),
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: Future.wait([
                        _getTodayUsageData(),
                        _getWeeklyUsageData(),
                        _getMonthlyUsageData(),
                      ]),
                      builder: (context, dataSnapshot) {
                        if (dataSnapshot.hasData) {
                          final results = dataSnapshot.data!;
                          final todayData = results[0];
                          final weeklyData = results[1];
                          final monthlyData = results[2];

                          final todayMinutes = todayData['totalMinutes'] as int? ?? 0;
                          final weeklyMinutes = _getTotalMinutes(weeklyData);
                          final monthlyMinutes = _getTotalMinutes(monthlyData);

                          final todayAppUsages = (todayData['appUsages'] as List?) ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTimeCard(
                                title: 'Hôm nay',
                                time: _formatMinutes(todayMinutes),
                                limit: 'Giới hạn: 4h',
                                progress: (todayMinutes / 240).clamp(0.0, 1.0),
                              ),
                              SizedBox(height: AppSpacing.lg),
                              _buildTimeCard(
                                title: 'Tuần này',
                                time: _formatMinutes(weeklyMinutes),
                                limit: 'Giới hạn: 28h',
                                progress: (weeklyMinutes / 1680).clamp(0.0, 1.0),
                              ),
                              SizedBox(height: AppSpacing.lg),
                              _buildTimeCard(
                                title: 'Tháng này',
                                time: _formatMinutes(monthlyMinutes),
                                limit: 'Giới hạn: 120h',
                                progress: (monthlyMinutes / 7200).clamp(0.0, 1.0),
                              ),
                              SizedBox(height: AppSpacing.xl),
                              _buildDetailedBreakdown(todayAppUsages),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTimeCard(
                              title: 'Hôm nay',
                              time: '2h 30m',
                              limit: 'Giới hạn: 4h',
                              progress: 0.625,
                            ),
                            SizedBox(height: AppSpacing.lg),
                            _buildTimeCard(
                              title: 'Tuần này',
                              time: '14h 15m',
                              limit: 'Giới hạn: 28h',
                              progress: 0.508,
                            ),
                            SizedBox(height: AppSpacing.lg),
                            _buildTimeCard(
                              title: 'Tháng này',
                              time: '58h 45m',
                              limit: 'Giới hạn: 120h',
                              progress: 0.489,
                            ),
                            SizedBox(height: AppSpacing.xl),
                            _buildDetailedBreakdown([]),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard({
    required String title,
    required String time,
    required String limit,
    required double progress,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.childPrimary,
                ),
              ),
              Text(
                limit,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.childPrimary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(AppColors.childPrimary),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% sử dụng',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedBreakdown(List<dynamic> appUsages) {
    final mockColors = {
      'youtube': Colors.red,
      'tiktok': Color(0xFF000000),
      'instagram': Colors.purple,
      'facebook': Colors.blue,
      'games': Colors.orange,
    };

    List<Map<String, dynamic>> apps = appUsages.isEmpty
        ? [
            {'name': 'YouTube', 'time': '45m', 'color': Colors.red},
            {'name': 'TikTok', 'time': '38m', 'color': Color(0xFF000000)},
            {'name': 'Instagram', 'time': '27m', 'color': Colors.purple},
            {'name': 'Games', 'time': '40m', 'color': Colors.blue},
          ]
        : appUsages.take(5).map((app) {
            final appName = app['appName'] as String? ?? 'Unknown';
            final minutes = (app['minutes'] as num?)?.toInt() ?? 0;
            final appKey = appName.toLowerCase();
            final color = mockColors[appKey] ?? Colors.grey;
            
            return {
              'name': appName,
              'time': _formatMinutes(minutes),
              'color': color,
            };
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ứng dụng được sử dụng nhiều nhất',
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.md),
        ...apps.map((app) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: app['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    app['name'] as String,
                    style: AppTypography.body,
                  ),
                ),
                Text(
                  app['time'] as String,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.childPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<Map<String, dynamic>> _getTodayUsageData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final childId = authProvider.user?.id;

      if (childId == null) {
        return {};
      }

      final data = await _apiService.getTodayUsage(childId);
      return data;
    } catch (e) {
      print('Error getting today usage: $e');
      return {};
    }
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  int _getTotalMinutes(Map<String, dynamic> data) {
    final sessions = data['sessions'] as List?;
    if (sessions == null || sessions.isEmpty) {
      return data['totalMinutes'] as int? ?? 0;
    }

    int total = 0;
    for (final session in sessions) {
      total += (session['duration'] as int? ?? 0);
    }
    return total;
  }
}
