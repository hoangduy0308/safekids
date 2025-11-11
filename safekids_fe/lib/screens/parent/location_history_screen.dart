import 'package:flutter/material.dart';
import '../../models/location.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class LocationHistoryScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final DateTime? initialDate;

  const LocationHistoryScreen({
    Key? key,
    required this.childId,
    required this.childName,
    this.initialDate,
  }) : super(key: key);

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<Location> _locations = [];
  bool _isLoading = true;
  DateTime? _selectedDate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadLocationHistory();
  }

  Future<void> _loadLocationHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final startDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      final endDate = startDate.add(const Duration(days: 1));

      print('[LocationHistory] Fetching for childId: ${widget.childId}');
      print('[LocationHistory] Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      final locations = await _apiService.getLocationHistory(
        widget.childId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
        limit: 1000,
      );

      print('[LocationHistory] Fetched ${locations.length} locations');
      
      // Sort locations by timestamp (ascending order - oldest first)
      locations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      for (var loc in locations) {
        print('[LocationHistory] Location: (${loc.latitude}, ${loc.longitude}) at ${loc.timestamp}');
      }

      if (mounted) {
        setState(() {
          _locations = locations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[LocationHistory] Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadLocationHistory();
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lịch sử vị trí',
              style: AppTypography.h3.copyWith(fontSize: 16),
            ),
            Text(
              widget.childName,
              style: AppTypography.caption.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _selectDate,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.childPrimary.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDate(_selectedDate ?? DateTime.now()),
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.childPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          'Lỗi tải dữ liệu',
                          style: AppTypography.h3
                              .copyWith(color: Colors.grey[600]),
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          _errorMessage ?? 'Đã xảy ra lỗi',
                          style: AppTypography.caption
                              .copyWith(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : _locations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: AppSpacing.lg),
                            Text(
                              'Không có dữ liệu vị trí',
                              style: AppTypography.h3
                                  .copyWith(color: Colors.grey[600]),
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'Không tìm thấy bản ghi vị trí cho ngày này',
                              style: AppTypography.caption
                                  .copyWith(color: Colors.grey[500]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(AppSpacing.md),
                      itemCount: _locations.length,
                      itemBuilder: (context, index) {
                        final location = _locations[index];
                        final prevLocation =
                            index > 0 ? _locations[index - 1] : null;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.childPrimary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.childPrimary.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.childPrimary
                                          .withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      color: AppColors.childPrimary,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatTime(location.timestamp),
                                              style: AppTypography.body
                                                  .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: AppSpacing.sm,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.info
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '±${location.accuracy.toStringAsFixed(0)}m',
                                                style: AppTypography.overline
                                                    .copyWith(
                                                  color: AppColors.info,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        SelectableText(
                                          '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                                          style: AppTypography.caption
                                              .copyWith(
                                            color: AppColors.textSecondary,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        if (prevLocation != null)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: AppSpacing.sm,
                                            ),
                                            child: Text(
                                              'Thời gian chuyển động: ${_calculateTimeDifference(location.timestamp, prevLocation.timestamp)}',
                                              style: AppTypography.overline
                                                  .copyWith(
                                                color: AppColors.textTertiary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: AppSpacing.md),
                          ],
                        );
                      },
                    ),
    );
  }

  String _calculateTimeDifference(DateTime current, DateTime previous) {
    final difference = current.difference(previous);
    if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    }
  }
}
