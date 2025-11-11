import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Usage Reports Screen (AC 5.4.1-5.4.4) - Story 5.4
/// Displays detailed screen time analytics and usage patterns
class UsageReportsScreen extends StatefulWidget {
  const UsageReportsScreen({Key? key}) : super(key: key);

  @override
  State<UsageReportsScreen> createState() => _UsageReportsScreenState();
}

class _UsageReportsScreenState extends State<UsageReportsScreen> {
  List<Map<String, dynamic>> _children = [];
  String? _selectedChildId;
  String _dateRange = '7days';

  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _loading = true);

    try {
      final profile = await ApiService().getProfile();
      final linkedChildren = profile['linkedUsers'] as List?;
      _children = linkedChildren != null
          ? List<Map<String, dynamic>>.from(
              linkedChildren.where((u) => u['role'] == 'child'),
            )
          : [];

      if (_children.isNotEmpty) {
        _selectedChildId = _children[0]['_id'];
        await _loadUsageData();
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  Future<void> _loadUsageData() async {
    if (_selectedChildId == null) return;

    setState(() => _loading = true);

    try {
      final dateRange = _getDateRange();

      final history = await ApiService().getUsageHistory(
        childId: _selectedChildId!,
        startDate: dateRange['start']!,
        endDate: dateRange['end']!,
      );

      final stats = await ApiService().getUsageStats(
        childId: _selectedChildId!,
        startDate: dateRange['start']!,
        endDate: dateRange['end']!,
      );

      setState(() {
        _history = history;
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  Map<String, String> _getDateRange() {
    final now = DateTime.now();
    String start, end;

    switch (_dateRange) {
      case 'today':
        start = end = _formatDate(now);
        break;
      case '7days':
        start = _formatDate(now.subtract(const Duration(days: 6)));
        end = _formatDate(now);
        break;
      case '30days':
        start = _formatDate(now.subtract(const Duration(days: 29)));
        end = _formatDate(now);
        break;
      default:
        start = _formatDate(now.subtract(const Duration(days: 6)));
        end = _formatDate(now);
    }

    return {'start': start, 'end': end};
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo Sử Dụng'),
        backgroundColor: AppColors.parentPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Child selector
                  if (_children.length > 1)
                    DropdownButtonFormField<String>(
                      value: _selectedChildId,
                      decoration: const InputDecoration(
                        labelText: 'Chọn trẻ em',
                      ),
                      items: _children
                          .map(
                            (child) => DropdownMenuItem<String>(
                              value: child['_id'] as String,
                              child: Text(child['fullName'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedChildId = value);
                        _loadUsageData();
                      },
                    ),

                  const SizedBox(height: AppSpacing.md),

                  // Date range selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _dateRangeChip('Hôm Nay', 'today'),
                        const SizedBox(width: 8),
                        _dateRangeChip('7 Ngày', '7days'),
                        const SizedBox(width: 8),
                        _dateRangeChip('30 Ngày', '30days'),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Summary stats
                  if (_stats != null) _buildSummaryStats(),

                  const SizedBox(height: AppSpacing.xl),

                  // Daily usage chart
                  if (_history.isNotEmpty) _buildDailyChart(),

                  const SizedBox(height: AppSpacing.xl),

                  // Day of week breakdown
                  if (_stats != null && _stats!['usageByDayOfWeek'] != null)
                    _buildDayOfWeekChart(),
                ],
              ),
            ),
    );
  }

  Widget _dateRangeChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _dateRange == value,
      onSelected: (_) {
        setState(() => _dateRange = value);
        _loadUsageData();
      },
    );
  }

  Widget _buildSummaryStats() {
    final totalMinutes = _stats!['totalMinutes'] ?? 0;
    final averageDaily = _stats!['averageDaily'] ?? 0;
    final daysOverLimit = _stats!['daysOverLimit'] ?? 0;
    final totalDays = _stats!['totalDays'] ?? 0;

    final totalHours = totalMinutes ~/ 60;
    final totalMins = totalMinutes % 60;
    final avgHours = averageDaily ~/ 60;
    final avgMins = averageDaily % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tổng Quan', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Tổng Sử Dụng',
                '${totalHours}h ${totalMins}p',
                Icons.access_time,
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _statCard(
                'Trung Bình',
                '${avgHours}h ${avgMins}p/ngày',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Vượt Giới Hạn',
                '$daysOverLimit/$totalDays ngày',
                Icons.warning,
                Colors.orange,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _statCard(
                'Hoạt Động Nhất',
                _formatMostActiveDay(),
                Icons.star,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatMostActiveDay() {
    final mostActive = _stats!['mostActiveDay'];
    if (mostActive == null) return 'N/A';

    final date = DateTime.parse(mostActive['date']);
    final minutes = mostActive['minutes'];
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    return '${date.day}/${date.month}\n${hours}h ${mins}p';
  }

  Widget _buildDailyChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sử Dụng Theo Ngày', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final record = _history[index];
              final date = DateTime.parse(record['date']);
              final minutes = record['totalMinutes'];
              final hours = minutes / 60;

              final barHeight = (hours / 12) * 150;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${hours.toStringAsFixed(1)}h',
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 30,
                      height: barHeight.clamp(10, 150).toDouble(),
                      decoration: BoxDecoration(
                        color: minutes > 120 ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayOfWeekChart() {
    final usageByDay = _stats!['usageByDayOfWeek'];
    final dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sử Dụng Theo Thứ', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final minutes = usageByDay[index.toString()] ?? 0;
              final hours = minutes / 60;
              final barHeight = (hours / 12) * 150;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${hours.toStringAsFixed(1)}h',
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: barHeight.clamp(10, 150).toDouble(),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(dayNames[index], style: const TextStyle(fontSize: 12)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
