import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/location.dart' as location_model;
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/parent/child_location_map.dart';
import '../../models/child_detail_data.dart';
import '../../widgets/parent/geofence_suggestions_section.dart';
import '../../widgets/geofence_map_view.dart';
import '../chat/chat_list_screen.dart';
import './location_history_screen.dart';
import 'dart:ui';
import '../../theme/app_typography.dart';
import 'package:latlong2/latlong.dart';

/// Dedicated map screen with sliding detail panel
class ChildMapScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final ChildDetailData childDetail; // Pass the whole data object
  final location_model.Location? selectedLocation;
  final location_model.Location? previousLocation;

  const ChildMapScreen({
    Key? key,
    required this.childId,
    required this.childName,
    required this.childDetail,
    this.selectedLocation,
    this.previousLocation,
  }) : super(key: key);

  @override
  State<ChildMapScreen> createState() => _ChildMapScreenState();
}

class _ChildMapScreenState extends State<ChildMapScreen> {
  final ApiService _apiService = ApiService();
  List<User> _linkedChildren = [];

  @override
  void initState() {
    super.initState();
    _loadLinkedChildren();
  }

  Future<void> _loadLinkedChildren() async {
    try {
      final children = await _apiService.getMyChildren();
      setState(() {
        _linkedChildren = children.map((child) {
          final id = child['childId'] ?? child['_id'] ?? child['id'] ?? '';
          final name =
              child['childName'] ??
              child['name'] ??
              child['fullName'] ??
              'Unknown';
          return User(
            id: id,
            name: name,
            fullName: name,
            email: child['email'] ?? '',
            phone: child['phone'],
            role: 'child',
            age: child['age'],
            createdAt: child['createdAt'] != null
                ? DateTime.parse(child['createdAt'])
                : DateTime.now(),
          );
        }).toList();
      });
    } catch (e) {
      print('[ChildMapScreen] Error loading children: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      '[ChildMapScreen] Building for child: ${widget.childName}, ID: ${widget.childId}, location: ${widget.selectedLocation?.latitude}, ${widget.selectedLocation?.longitude}',
    );
    return Scaffold(
      // Using a Stack to layer the map and the sliding panel
      body: Stack(
        children: [
          // The map is the background
          ChildLocationMap(
            focusedChildId: widget.childId,
            selectedLocation: widget.selectedLocation,
            previousLocation: widget.previousLocation,
            // Path visualization can be controlled from the panel
            // showPath: _showPath,
            // pathLocations: _showPath ? _pathLocations : null,
          ),

          // The sliding panel for details
          DraggableScrollableSheet(
            initialChildSize: 0.17, // Fine-tuned "peek" state
            minChildSize: 0.17, // Fine-tuned "peek" state
            maxChildSize: 0.9, // Can be expanded to 90%
            builder: (BuildContext context, ScrollController scrollController) {
              return ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.8),
                    ),
                    child: _buildDetailContent(scrollController),
                  ),
                ),
              );
            },
          ),

          // Floating AppBar
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: AppBar(
              title: Text(widget.childName),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: CircleAvatar(
                  backgroundColor: AppColors.surface.withOpacity(0.8),
                  child: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // This method builds the content inside the draggable sheet
  Widget _buildDetailContent(ScrollController scrollController) {
    // Re-using the widgets from the original ChildDetailSheet
    final child = widget.childDetail;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      children: [
        // Handle bar
        Center(
          child: Container(
            margin: EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Action Buttons are now at the top
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _buildActionButtons(context),
        ),

        SizedBox(height: AppSpacing.lg),

        // The rest of the details
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              // Row 1: Battery + Screen Time
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      icon: Icons.battery_charging_full_rounded,
                      iconColor: _getBatteryColor(),
                      title: 'Pin',
                      value: '${child.batteryLevel ?? 0}%',
                      subtitle: _getBatteryStatus(),
                      backgroundColor: _getBatteryColor().withOpacity(0.1),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildInfoCard(
                      icon: Icons.phone_android_rounded,
                      iconColor: AppColors.info,
                      title: 'Thời gian sử dụng',
                      value:
                          '${child.screenTimeMinutes ~/ 60}h ${child.screenTimeMinutes % 60}m',
                      subtitle: 'Giới hạn: ${child.screenTimeLimit}h',
                      backgroundColor: AppColors.info.withOpacity(0.1),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.md),

              // Row 2: Location info card (full width)
              _buildLocationCard(),

              SizedBox(height: AppSpacing.lg),

              // Geofence Suggestions Section (Story 3.5)
              GeofenceSuggestionsSection(
                key: ValueKey(child.childId),
                childId: child.childId,
                onCreateGeofence: (suggestion) {
                  if (_linkedChildren.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đang tải danh sách trẻ em...'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context); // Close map screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GeofenceMapView(
                        linkedChildren: _linkedChildren,
                        focusedChildId: child.childId,
                        initialCenter: LatLng(
                          suggestion.center.latitude,
                          suggestion.center.longitude,
                        ),
                        startInDrawMode: false,
                        showDrawControls: true,
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: AppSpacing.xl), // More space at the bottom
            ],
          ),
        ),
      ],
    );
  }

  // --- Helper methods copied from ChildDetailSheet ---

  void _openChatScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatListScreen(),
      ),
    );
  }

  Future<void> _openNavigation() async {
    try {
      if (widget.selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có vị trí để chỉ đường'),
          ),
        );
        return;
      }

      final lat = widget.selectedLocation!.latitude;
      final lng = widget.selectedLocation!.longitude;
      final childName = Uri.encodeComponent(widget.childName);

      final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_name=$childName',
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể mở ứng dụng bản đồ'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
          ),
        );
      }
    }
  }

  void _openLocationHistory() {
    print('[ChildMapScreen] Opening history - childId: ${widget.childDetail.childId}, name: ${widget.childName}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationHistoryScreen(
          childId: widget.childDetail.childId,
          childName: widget.childName,
          initialDate: DateTime.now(),
        ),
      ),
    );
  }

  void _lockDevicePrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Khóa thiết bị'),
        content: Text('Bạn có chắc chắn muốn khóa thiết bị của ${widget.childName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _lockDevice();
            },
            child: Text(
              'Khóa ngay',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _lockDevice() async {
    try {
      await _apiService.lockDevice(widget.childDetail.childId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gửi lệnh khóa thiết bị ${widget.childName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: Icons.call_rounded,
            label: 'Gọi',
            color: Colors.green,
          ),
          _buildActionButton(
            icon: Icons.message_rounded,
            label: 'Nhắn tin',
            color: Colors.blue,
            onTap: _openChatScreen,
          ),
          _buildActionButton(
            icon: Icons.navigation_rounded,
            label: 'Chỉ đường',
            color: Colors.purple,
            onTap: _openNavigation,
          ),
          _buildActionButton(
            icon: Icons.history_rounded,
            label: 'Lịch sử',
            color: Colors.orange,
            onTap: _openLocationHistory,
          ),
          _buildActionButton(
            icon: Icons.lock_rounded,
            label: 'Khóa',
            color: Colors.red,
            onTap: _lockDevicePrompt,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required Color backgroundColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.captionSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.overline.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withOpacity(0.2), width: 1),
      ),
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: AppColors.info,
              size: 20,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: SelectableText(
              widget.childDetail.locationName,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBatteryColor() {
    final level = widget.childDetail.batteryLevel;
    if (level == null) return AppColors.textSecondary;
    if (level > 50) return AppColors.success;
    if (level > 20) return AppColors.warning;
    return AppColors.danger;
  }

  String _getBatteryStatus() {
    final level = widget.childDetail.batteryLevel;
    if (level == null) return 'Chưa cập nhật';
    if (level > 50) return 'Bình thường';
    if (level > 20) return 'Tiết kiệm';
    if (level > 10) return 'Siêu tiết kiệm';
    return 'Khẩn cấp';
  }
}
