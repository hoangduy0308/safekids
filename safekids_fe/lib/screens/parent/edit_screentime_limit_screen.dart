import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Edit Screen Time Limit Screen (AC 5.1.2, 5.1.3) - Story 5.1
/// Allows parents to configure daily limits and bedtime mode
class EditScreenTimeLimitScreen extends StatefulWidget {
  final Map<String, dynamic> child;

  const EditScreenTimeLimitScreen({Key? key, required this.child})
    : super(key: key);

  @override
  State<EditScreenTimeLimitScreen> createState() =>
      _EditScreenTimeLimitScreenState();
}

class _EditScreenTimeLimitScreenState extends State<EditScreenTimeLimitScreen> {
  final ApiService _apiService = ApiService();

  late int _dailyLimit; // minutes
  late bool _bedtimeEnabled;
  late TimeOfDay _bedtimeStart;
  late TimeOfDay _bedtimeEnd;
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _apiService.getScreenTimeConfig(widget.child['_id']);
      if (mounted) {
        setState(() {
          _dailyLimit = config['dailyLimit'] ?? 120;
          _bedtimeEnabled = config['bedtimeEnabled'] ?? false;

          // Parse bedtime strings
          final startParts = (config['bedtimeStart'] ?? '21:00').split(':');
          _bedtimeStart = TimeOfDay(
            hour: int.parse(startParts[0]),
            minute: int.parse(startParts[1]),
          );

          final endParts = (config['bedtimeEnd'] ?? '07:00').split(':');
          _bedtimeEnd = TimeOfDay(
            hour: int.parse(endParts[0]),
            minute: int.parse(endParts[1]),
          );

          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Use defaults on error
          _dailyLimit = 120;
          _bedtimeEnabled = false;
          _bedtimeStart = const TimeOfDay(hour: 21, minute: 0);
          _bedtimeEnd = const TimeOfDay(hour: 7, minute: 0);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chỉnh Sửa Giới Hạn'),
          backgroundColor: AppColors.parentPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final hours = _dailyLimit ~/ 60;
    final minutes = _dailyLimit % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh Sửa Giới Hạn'),
        backgroundColor: AppColors.parentPrimary,
        foregroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Child info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.parentPrimary.withOpacity(0.1),
                      child: Text(
                        widget.child['name'][0].toUpperCase(),
                        style: AppTypography.h2.copyWith(
                          color: AppColors.parentPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.child['name'],
                            style: AppTypography.h3.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.child['age'] ?? '?'} tuổi',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Daily limit slider
            Text(
              'Giới Hạn Hằng Ngày',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Text(
                      '$hours giờ $minutes phút',
                      style: AppTypography.h1.copyWith(
                        color: AppColors.parentPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Slider(
                      value: _dailyLimit.toDouble(),
                      min: 0,
                      max: 720, // 12 hours
                      divisions: 48, // 15-minute steps
                      label: '${hours}h ${minutes}p',
                      activeColor: AppColors.parentPrimary,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _dailyLimit = value.toInt());
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Con sẽ được dùng thiết bị tối đa $hours giờ $minutes phút mỗi ngày',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Bedtime mode
            Text(
              'Chế Độ Giờ Ngủ',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Chế Độ Giờ Ngủ',
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Khóa thiết bị vào giờ ngủ (trừ SOS)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _bedtimeEnabled,
                    activeColor: AppColors.parentPrimary,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() => _bedtimeEnabled = value);
                    },
                  ),
                  if (_bedtimeEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.bedtime,
                        color: AppColors.parentPrimary,
                      ),
                      title: const Text('Bắt Đầu'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_bedtimeStart.hour.toString().padLeft(2, '0')}:${_bedtimeStart.minute.toString().padLeft(2, '0')}',
                            style: AppTypography.h3.copyWith(
                              color: AppColors.parentPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit, size: 20),
                        ],
                      ),
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _bedtimeStart,
                        );
                        if (time != null) {
                          setState(() => _bedtimeStart = time);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                      title: const Text('Kết Thúc'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_bedtimeEnd.hour.toString().padLeft(2, '0')}:${_bedtimeEnd.minute.toString().padLeft(2, '0')}',
                            style: AppTypography.h3.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit, size: 20),
                        ],
                      ),
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _bedtimeEnd,
                        );
                        if (time != null) {
                          setState(() => _bedtimeEnd = time);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Thiết bị sẽ bị khóa từ ${_bedtimeStart.format(context)} đến ${_bedtimeEnd.format(context)}',
                                style: AppTypography.captionSmall.copyWith(
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveConfig,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _saving ? 'ĐANG LƯU...' : 'LƯU CÀI ĐẶT',
                  style: AppTypography.button.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.parentPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveConfig() async {
    setState(() => _saving = true);

    try {
      await _apiService.saveScreenTimeConfig(
        childId: widget.child['_id'],
        dailyLimit: _dailyLimit,
        bedtimeEnabled: _bedtimeEnabled,
        bedtimeStart:
            '${_bedtimeStart.hour.toString().padLeft(2, '0')}:${_bedtimeStart.minute.toString().padLeft(2, '0')}',
        bedtimeEnd:
            '${_bedtimeEnd.hour.toString().padLeft(2, '0')}:${_bedtimeEnd.minute.toString().padLeft(2, '0')}',
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lưu cài đặt thành công'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
