import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import '../../config/environment.dart';

String _buildStaticMapUrl(double latitude, double longitude) {
  final key = EnvironmentConfig.mapTilerApiKey;
  if (key.isEmpty) {
    return 'https://staticmap.openstreetmap.de/staticmap.php?center=$latitude,$longitude&zoom=16&size=600x300&markers=$latitude,$longitude,red';
  }
  return 'https://api.maptiler.com/maps/streets/static/${longitude},${latitude},16/600x300.png?key=$key';
}

/// SOS Alert Screen (AC 4.2.3, 4.2.4) - Story 4.2
/// Full-screen modal displaying SOS emergency details
class SOSAlertScreen extends StatefulWidget {
  final String sosId;

  const SOSAlertScreen({Key? key, required this.sosId}) : super(key: key);

  @override
  State<SOSAlertScreen> createState() => _SOSAlertScreenState();
}

class _SOSAlertScreenState extends State<SOSAlertScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _sosData;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSOSDetails();
  }

  Future<void> _loadSOSDetails() async {
    try {
      final sos = await _apiService.getSOSDetails(widget.sosId);
      if (mounted) {
        setState(() {
          _sosData = sos;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.danger,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.surface),
        ),
      );
    }

    if (_errorMessage != null || _sosData == null) {
      return Scaffold(
        backgroundColor: AppColors.danger,
        appBar: AppBar(
          backgroundColor: AppColors.danger,
          title: const Text('Lỗi'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.surface),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _errorMessage ?? 'Không tìm thấy cảnh báo SOS',
                  style: AppTypography.h3.copyWith(color: AppColors.surface),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final child = _sosData!['child'] as Map<String, dynamic>?;
    final childName = child?['fullName'] ?? child?['name'] ?? 'Trẻ không rõ';
    final location = _sosData!['location'] as Map<String, dynamic>?;
    final timestamp = DateTime.parse(
      _sosData!['timestamp'] ?? _sosData!['createdAt'],
    );
    final batteryLevel = _sosData!['batteryLevel'] as int? ?? 0;
    final status = _sosData!['status'] as String? ?? 'active';
    final resolvedBy = _sosData!['resolvedBy'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.danger,
        title: const Text(
          '🚨 CẢNH BÁO KHẨN CẤP',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Emergency banner
            _buildEmergencyBanner(childName, timestamp),

            // Resolved banner (AC 4.2.7)
            if (status == 'resolved' && resolvedBy != null)
              _buildResolvedBanner(resolvedBy),

            // Details card
            _buildDetailsCard(
              childName,
              timestamp,
              batteryLevel,
              location,
              status,
            ),

            // Map
            if (location != null) _buildMap(location, childName),

            const SizedBox(height: AppSpacing.lg),

            // Action buttons (AC 4.2.4)
            _buildActionButtons(childName, location, status),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyBanner(String childName, DateTime timestamp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.danger,
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.emergency, size: 80, color: AppColors.surface),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$childName ĐÃ GỬI TÍN HIỆU SOS!',
            style: AppTypography.h2.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _formatTimestamp(timestamp),
            style: AppTypography.body.copyWith(
              color: AppColors.surface.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedBanner(Map<String, dynamic> resolvedBy) {
    final resolverName =
        resolvedBy['fullName'] ?? resolvedBy['name'] ?? 'Phụ huynh';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.success.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Đã xử lý bởi $resolverName',
              style: AppTypography.label.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    String childName,
    DateTime timestamp,
    int batteryLevel,
    Map<String, dynamic>? location,
    String status,
  ) {
    return Card(
      margin: const EdgeInsets.all(AppSpacing.lg),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.person, 'Trẻ em', childName),
            _buildDetailRow(
              Icons.access_time,
              'Thời gian',
              '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
            ),
            _buildDetailRow(Icons.battery_std, 'Pin', '$batteryLevel%'),
            if (location != null)
              _buildDetailRow(
                Icons.location_on,
                'Vị trí',
                '${location['latitude']?.toStringAsFixed(6)}, ${location['longitude']?.toStringAsFixed(6)}',
              ),
            _buildDetailRow(
              Icons.info,
              'Trạng thái',
              status == 'active'
                  ? 'ĐANG CHỜ XỬ LÝ'
                  : status == 'resolved'
                  ? 'ĐÃ XỬ LÝ'
                  : 'CẢNH BÁO GIẢ',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(Map<String, dynamic> location, String childName) {
    final lat = (location['latitude'] as num).toDouble();
    final lng = (location['longitude'] as num).toDouble();

    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(_buildStaticMapUrl(lat, lng), fit: BoxFit.cover),
    );
  }

  Widget _buildActionButtons(
    String childName,
    Map<String, dynamic>? location,
    String status,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // XEM BẢN ĐỒ
          _buildActionButton(
            icon: Icons.map,
            label: 'XEM BẢN ĐỒ',
            color: AppColors.info,
            onPressed: _openMap,
          ),
          const SizedBox(height: AppSpacing.md),

          // GỌI
          _buildActionButton(
            icon: Icons.phone,
            label: 'GỌI $childName',
            color: AppColors.success,
            onPressed: _callChild,
          ),
          const SizedBox(height: AppSpacing.md),

          // CHỈ ĐƯỜNG
          if (location != null)
            _buildActionButton(
              icon: Icons.directions,
              label: 'CHỈ ĐƯỜNG',
              color: Colors.orange,
              onPressed: () => _openNavigation(location),
            ),
          if (location != null) const SizedBox(height: AppSpacing.lg),

          // ĐÁNH DẤU BÁO NHẦM (AC 4.4.3)
          if (status == 'active')
            _buildActionButton(
              icon: Icons.warning_amber,
              label: 'ĐÁNH DẤU BÁO NHẦM',
              color: Colors.orange,
              onPressed: _markFalseAlarm,
            ),
          if (status == 'active') const SizedBox(height: AppSpacing.md),

          // ĐÃ XỬ LÝ (only if active)
          if (status == 'active')
            _buildActionButton(
              icon: Icons.check_circle,
              label: 'ĐÃ XỬ LÝ',
              color: Colors.grey[700]!,
              onPressed: _markResolved,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: AppTypography.label.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          elevation: 2,
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  void _openMap() {
    final child = _sosData!['child'] as Map<String, dynamic>?;
    final childId = child?['_id'] ?? '';
    final location = _sosData!['location'];

    if (childId.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/map',
        arguments: {'childId': childId, 'sosLocation': location},
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể mở bản đồ')));
    }
  }

  void _callChild() {
    final child = _sosData!['child'] as Map<String, dynamic>?;
    final phoneNumber = child?['phoneNumber'] as String?;

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final uri = Uri.parse('tel:$phoneNumber');
      launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không có số điện thoại')));
    }
  }

  void _openNavigation(Map<String, dynamic> location) {
    final lat = location['latitude'];
    final lng = location['longitude'];

    if (lat != null && lng != null) {
      final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _markFalseAlarm() async {
    String? selectedReason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Đánh Dấu Báo Nhầm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Đánh dấu SOS này là báo nhầm?'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Lý do (tùy chọn)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'accidental',
                    child: Text('Trẻ nhấn nhầm'),
                  ),
                  DropdownMenuItem(
                    value: 'test',
                    child: Text('Kiểm tra hệ thống'),
                  ),
                  DropdownMenuItem(value: 'other', child: Text('Khác')),
                ],
                onChanged: (value) {
                  setState(() => selectedReason = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Xác Nhận'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.updateSOSStatus(
          widget.sosId,
          'false_alarm',
          reason: selectedReason ?? 'Not specified',
        );
        if (mounted) {
          setState(() {
            _sosData!['status'] = 'false_alarm';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã đánh dấu báo nhầm'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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

  Future<void> _markResolved() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Đánh dấu SOS này là đã xử lý?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.updateSOSStatus(widget.sosId, 'resolved');
        if (mounted) {
          Navigator.pop(context); // Exit SOS alert screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã đánh dấu SOS là đã xử lý'),
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
}
