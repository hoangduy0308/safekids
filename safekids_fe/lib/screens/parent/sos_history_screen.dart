import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'sos_alert_screen.dart';

/// SOS History Screen (AC 4.3.1-4.3.7) - Story 4.3
/// Displays past SOS alerts with filtering and pagination
class SOSHistoryScreen extends StatefulWidget {
  const SOSHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SOSHistoryScreen> createState() => _SOSHistoryScreenState();
}

class _SOSHistoryScreenState extends State<SOSHistoryScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _sosList = [];
  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic>? _stats;

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  // Filters
  String? _selectedChildId;
  String? _selectedStatus;
  String _selectedDateRange = 'all';
  String? _startDate;
  String? _endDate;

  // Pagination
  final int _limit = 50;
  int _skip = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadChildren();
    _loadSOSHistory();
    _loadStats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final linkedChildren =
          authProvider.user?.linkedUsersData
              .where((user) => user['role'] == 'child')
              .toList() ??
          [];
      if (mounted) {
        setState(() => _children = linkedChildren);
      }
    } catch (e) {
      print('Load children error: $e');
    }
  }

  Future<void> _loadSOSHistory({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _skip = 0;
        _sosList = [];
        _hasMore = true;
      });
    }

    setState(() => _loading = true);

    try {
      final response = await _apiService.getSOSHistoryFiltered(
        childId: _selectedChildId,
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        limit: _limit,
        skip: _skip,
      );

      final sosList =
          (response['sosList'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final total = response['total'] as int? ?? 0;
      final hasMore = response['hasMore'] as bool? ?? false;

      if (mounted) {
        setState(() {
          if (refresh) {
            _sosList = sosList;
          } else {
            _sosList.addAll(sosList);
          }
          _total = total;
          _hasMore = hasMore;
          _loading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Không thể tải lịch sử SOS';
        if (e.toString().contains('Connection closed')) {
          errorMsg = 'Kết nối bị đóng. Vui lòng thử lại.';
        } else if (e.toString().contains('timed out')) {
          errorMsg = 'Yêu cầu quá lâu. Vui lòng thử lại.';
        } else if (e.toString().contains('Connection refused')) {
          errorMsg = 'Không thể kết nối tới server. Kiểm tra kết nối mạng.';
        }

        setState(() {
          _loading = false;
          _errorMessage = errorMsg;
        });
      }
      print('Load SOS history error: $e');
    }
  }

  Future<void> _loadMoreSOS() async {
    if (_loadingMore || !_hasMore) return;

    setState(() => _loadingMore = true);
    _skip += _limit;

    try {
      final response = await _apiService.getSOSHistoryFiltered(
        childId: _selectedChildId,
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        limit: _limit,
        skip: _skip,
      );

      final sosList =
          (response['sosList'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final hasMore = response['hasMore'] as bool? ?? false;

      if (mounted) {
        setState(() {
          _sosList.addAll(sosList);
          _hasMore = hasMore;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMore = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải thêm: $e')));
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _apiService.getSOSStats(
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted) {
        setState(() => _stats = stats);
      }
    } catch (e) {
      print('Load stats error: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) {
        _loadMoreSOS();
      }
    }
  }

  void _applyDateFilter(String filter) {
    DateTime? startDate;
    final endDate = DateTime.now();

    switch (filter) {
      case 'today':
        startDate = DateTime.now().subtract(const Duration(hours: 24));
        break;
      case '7days':
        startDate = DateTime.now().subtract(const Duration(days: 7));
        break;
      case '30days':
        startDate = DateTime.now().subtract(const Duration(days: 30));
        break;
      case 'all':
        startDate = null;
        break;
    }

    setState(() {
      _selectedDateRange = filter;
      _startDate = startDate?.toIso8601String();
      _endDate = endDate.toIso8601String();
    });

    _loadSOSHistory(refresh: true);
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Lịch Sử SOS'),
        backgroundColor: AppColors.parentPrimary,
        foregroundColor: AppColors.surface,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Stats Summary (AC 4.3.7)
          if (_stats != null) _buildStatsSection(),

          // Filters
          _buildFiltersSection(),

          // SOS List
          Expanded(
            child: _loading && _sosList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorView()
                : _sosList.isEmpty
                ? _buildEmptyView()
                : _buildSOSList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final total = _stats!['total'] as int? ?? 0;
    final active = _stats!['active'] as int? ?? 0;
    final resolved = _stats!['resolved'] as int? ?? 0;
    final avgResponseTime = _stats!['avgResponseTimeMinutes'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: _statCard('Tổng SOS', total.toString(), AppColors.info),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _statCard(
              'Đang hoạt động',
              active.toString(),
              AppColors.danger,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _statCard(
              'Đã xử lý',
              resolved.toString(),
              AppColors.success,
            ),
          ),
          if (avgResponseTime > 0) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _statCard(
                'TB phản hồi',
                '${avgResponseTime}m',
                Colors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.h3.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Child filter (AC 4.3.2)
          _buildChildFilter(),
          const SizedBox(height: AppSpacing.md),

          // Status filter (AC 4.3.3)
          _buildStatusFilter(),
          const SizedBox(height: AppSpacing.md),

          // Date range filter (AC 4.3.4)
          _buildDateRangeFilter(),
        ],
      ),
    );
  }

  Widget _buildChildFilter() {
    return Row(
      children: [
        Text(
          'Trẻ em:',
          style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: DropdownButton<String?>(
            value: _selectedChildId,
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('Tất cả trẻ em')),
              ..._children.map((child) {
                final childId = child['_id'] ?? child['id'] ?? '';
                final childName = child['name'] ?? child['fullName'] ?? 'Trẻ';
                return DropdownMenuItem(value: childId, child: Text(childName));
              }),
            ],
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _selectedChildId = value);
              _loadSOSHistory(refresh: true);
              _loadStats();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trạng thái:',
          style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('Tất cả', null),
              const SizedBox(width: AppSpacing.sm),
              _filterChip('Đang hoạt động', 'active', color: AppColors.danger),
              const SizedBox(width: AppSpacing.sm),
              _filterChip('Đã xử lý', 'resolved', color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              _filterChip('Báo nhầm', 'false_alarm', color: Colors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String? statusValue, {Color? color}) {
    final isSelected = _selectedStatus == statusValue;
    final chipColor = color ?? AppColors.parentPrimary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _selectedStatus = statusValue);
        _loadSOSHistory(refresh: true);
      },
      backgroundColor: isSelected
          ? chipColor.withOpacity(0.1)
          : AppColors.surface,
      selectedColor: chipColor.withOpacity(0.2),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? chipColor : AppColors.divider),
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thời gian:',
          style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _dateChip('Hôm nay', 'today'),
              const SizedBox(width: AppSpacing.sm),
              _dateChip('7 ngày', '7days'),
              const SizedBox(width: AppSpacing.sm),
              _dateChip('30 ngày', '30days'),
              const SizedBox(width: AppSpacing.sm),
              _dateChip('Tất cả', 'all'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateChip(String label, String value) {
    final isSelected = _selectedDateRange == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        _applyDateFilter(value);
      },
      backgroundColor: isSelected
          ? AppColors.parentPrimary.withOpacity(0.1)
          : AppColors.surface,
      selectedColor: AppColors.parentPrimary.withOpacity(0.2),
      checkmarkColor: AppColors.parentPrimary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.parentPrimary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.parentPrimary : AppColors.divider,
      ),
    );
  }

  Widget _buildSOSList() {
    return RefreshIndicator(
      onRefresh: () => _loadSOSHistory(refresh: true),
      color: AppColors.parentPrimary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _sosList.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _sosList.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final sos = _sosList[index];
          return _buildSOSListItem(sos);
        },
      ),
    );
  }

  Widget _buildSOSListItem(Map<String, dynamic> sos) {
    final child = sos['childId'] as Map<String, dynamic>?;
    final childName = child?['fullName'] ?? child?['name'] ?? 'Trẻ không rõ';
    final timestamp = DateTime.parse(sos['timestamp'] ?? sos['createdAt']);
    final status = sos['status'] as String? ?? 'active';
    final location = sos['location'] as Map<String, dynamic>?;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'active':
        statusColor = AppColors.danger;
        statusText = 'Đang hoạt động';
        statusIcon = Icons.emergency;
        break;
      case 'resolved':
        statusColor = AppColors.success;
        statusText = 'Đã xử lý';
        statusIcon = Icons.check_circle;
        break;
      case 'false_alarm':
        statusColor = Colors.orange;
        statusText = 'Báo nhầm';
        statusIcon = Icons.warning_amber;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = 'Không rõ';
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: statusColor.withOpacity(0.2), width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SOSAlertScreen(sosId: sos['_id'] ?? sos['id'] ?? ''),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar with status badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.parentPrimary.withOpacity(0.1),
                    child: Text(
                      childName.isNotEmpty ? childName[0].toUpperCase() : '?',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.parentPrimary,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: Icon(
                        statusIcon,
                        size: 10,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$childName - SOS',
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(timestamp),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (status == 'false_alarm' && sos['markedBy'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.cancel, size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Đã hủy bởi ${sos['markedBy']['fullName'] ?? sos['markedBy']['name'] ?? 'Không rõ'}',
                              style: AppTypography.captionSmall.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${location['latitude']?.toStringAsFixed(4)}, ${location['longitude']?.toStringAsFixed(4)}',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusText,
                  style: AppTypography.captionSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Chưa có SOS nào',
            style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Lịch sử SOS sẽ hiển thị ở đây',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Không thể tải lịch sử',
              style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage ?? '',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _loadSOSHistory(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.parentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
