import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'sos_alert_screen.dart';

import '../../models/child_detail_data.dart';
import '../../models/location.dart' as location_model;
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/api_service.dart';
import '../../services/geocode_service.dart';
import '../../services/socket_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/parent/notification_badge.dart';
import '../../widgets/parent/notification_panel.dart';
import '../../widgets/child/notification_center.dart';
import 'child_map_screen.dart';
import 'link_child_screen.dart';
import '../shared/profile_screen.dart';

class MemberCardWithInteraction extends StatefulWidget {
  final String name;
  final Color color;
  final Color bgColor;
  final String statusText;
  final VoidCallback onTap;

  const MemberCardWithInteraction({
    Key? key,
    required this.name,
    required this.color,
    required this.bgColor,
    required this.statusText,
    required this.onTap,
  }) : super(key: key);

  @override
  State<MemberCardWithInteraction> createState() =>
      _MemberCardWithInteractionState();
}

class _MemberCardWithInteractionState extends State<MemberCardWithInteraction>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovering) {
    setState(() => _isHovering = isHovering);
    if (isHovering) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
        _scaleController.forward().then((_) => _scaleController.reverse());
      },
      child: MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.08).animate(
            CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: widget.bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.color, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(
                            _isHovering ? 0.5 : 0.2,
                          ),
                          blurRadius: _isHovering ? 16 : 8,
                          spreadRadius: _isHovering ? 3 : 1,
                          offset: Offset(0, _isHovering ? 4 : 2),
                        ),
                        BoxShadow(
                          color: widget.color.withOpacity(
                            _isHovering ? 0.2 : 0.05,
                          ),
                          blurRadius: _isHovering ? 24 : 12,
                          spreadRadius: _isHovering ? 6 : 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.name.isNotEmpty
                            ? widget.name[0].toUpperCase()
                            : '👧',
                        style: AppTypography.display2.copyWith(
                          color: widget.color,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity(0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(widget.name, style: AppTypography.label),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: widget.color.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  widget.statusText,
                  style: AppTypography.captionSmall.copyWith(
                    color: widget.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({Key? key}) : super(key: key);

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _recentStatuses = [];
  List<Map<String, dynamic>> _sosSignals = [];
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late ConfettiController _confettiController;
  bool _showNotificationPanel = false;

  DateTime? _normalizeTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  DateTime _statusTimestamp(Map<String, dynamic> status) {
    final direct = _normalizeTimestamp(status['timestamp']);
    if (direct != null) {
      return direct;
    }
    final fallback = _normalizeTimestamp(status['time']);
    return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<Map<String, dynamic>> _sortedStatusesByTime(
    List<Map<String, dynamic>> statuses,
  ) {
    final sorted = statuses
        .map((status) => Map<String, dynamic>.from(status))
        .toList();
    sorted.sort((a, b) => _statusTimestamp(b).compareTo(_statusTimestamp(a)));
    return sorted;
  }

  void _setRecentStatuses(List<Map<String, dynamic>> statuses) {
    setState(() {
      _recentStatuses = _sortedStatusesByTime(statuses).take(10).toList();
    });
  }

  void _addRecentStatus(Map<String, dynamic> status) {
    final updated = [status, ..._recentStatuses];
    setState(() {
      _recentStatuses = _sortedStatusesByTime(updated).take(10).toList();
    });
  }

  Map<String, dynamic> _composeGeofenceStatus({
    required String childName,
    required String geofenceName,
    required String zoneType,
    required String action,
    required DateTime timestamp,
  }) {
    final normalizedZoneType = zoneType.toLowerCase();
    final isSafeZone = normalizedZoneType == 'safe';
    final normalizedAction = action.toLowerCase();
    final isExit = normalizedAction == 'exit' || normalizedAction == 'exited';
    final displayName = geofenceName.isNotEmpty ? geofenceName : 'vùng';

    final bool isWarning = (isExit && isSafeZone) || (!isExit && !isSafeZone);

    final String actionText;
    final Color color;
    final IconData icon;

    if (isExit) {
      actionText =
          'đã rời khỏi ${isSafeZone ? 'vùng an toàn' : 'vùng nguy hiểm'} "$displayName"';
      color = isSafeZone ? AppColors.danger : AppColors.success;
      icon = Icons.location_off;
    } else {
      actionText =
          'đã vào ${isSafeZone ? 'vùng an toàn' : 'vùng nguy hiểm'} "$displayName"';
      color = isSafeZone ? AppColors.success : AppColors.danger;
      icon = isSafeZone ? Icons.location_on : Icons.dangerous;
    }

    return {
      'name': childName,
      'action': actionText,
      'time': timestamp.toIso8601String(),
      'icon': icon,
      'color': color,
      'type': 'geofence',
      'timestamp': timestamp,
      'isWarning': isWarning,
      'zoneType': normalizedZoneType,
      'rawAction': normalizedAction,
    };
  }

  Map<String, dynamic> _composeSosStatus({
    required String childName,
    required DateTime timestamp,
  }) {
    return {
      'name': childName,
      'action': 'đã gửi tín hiệu SOS khẩn cấp 🚨',
      'time': timestamp.toIso8601String(),
      'icon': Icons.emergency,
      'color': AppColors.danger,
      'type': 'sos',
      'timestamp': timestamp,
      'isWarning': true,
    };
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _loadRecentStatuses();
    _setupSocketListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).loadNotifications();
    });
  }

  void _setupSocketListeners() {
    final socketService = SocketService();

    socketService.onSosAlert = (data) {
      if (!mounted) return;
      print('[ParentHome] Received SOS alert: $data');

      final timestamp =
          _normalizeTimestamp(data['timestamp']) ?? DateTime.now();
      final sosAlert = _composeSosStatus(
        childName: data['childName'] ?? 'Trẻ không rõ',
        timestamp: timestamp,
      );
      final sosId = data['sosId']?.toString() ?? '';
      sosAlert['sosId'] = sosId;

      _addRecentStatus(sosAlert);
      print('[ParentHome] Added SOS alert. Total: ${_recentStatuses.length}');

      // Add to SOS signals
      final sosSignal = {
        'id': sosId,
        'description': 'Tín hiệu SOS từ ${data['childName'] ?? "con"}',
        'location': data['location']?.toString() ?? 'Chưa có vị trí',
        'time': _formatTime(timestamp),
        'status': 'sent',
      };
      setState(() {
        _sosSignals.insert(0, sosSignal);
      });

      // AC 4.2.5: Show in-app alert modal immediately (Story 4.2 Task 7)
      if (sosId.isNotEmpty) {
        _showSOSAlertModal(sosId);
      }
    };

    socketService.onGeofenceAlert = (data) {
      if (!mounted) return;
      print('[ParentHome] Received geofence alert: $data');

      final timestamp =
          _normalizeTimestamp(data['timestamp']) ?? DateTime.now();
      final action =
          (data['action'] as String? ?? data['type'] as String? ?? '')
              .toLowerCase();
      final geofenceName = data['geofenceName'] as String? ?? 'vùng';
      final zoneType =
          data['zoneType'] as String? ??
          data['geofenceType'] as String? ??
          'safe';

      final geofenceAlert = _composeGeofenceStatus(
        childName: data['childName'] ?? 'Trẻ không rõ',
        geofenceName: geofenceName,
        zoneType: zoneType,
        action: action,
        timestamp: timestamp,
      );
      geofenceAlert['geofenceId'] = data['geofenceId']?.toString() ?? '';
      geofenceAlert['geofenceName'] = geofenceName;
      geofenceAlert['location'] = data['location'];

      _addRecentStatus(geofenceAlert);
      print('[ParentHome] Updated statuses. Total: ${_recentStatuses.length}');
    };
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m trước';
    if (difference.inHours < 24) return '${difference.inHours}h trước';
    if (difference.inDays < 7) return '${difference.inDays}d trước';

    return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _formatRecentActivities() {
    return _recentStatuses.map((status) {
      final timestamp = _statusTimestamp(status);
      final formattedTime = _formatTime(timestamp);

      return {
        'title': '${status['name'] ?? 'Con em'} ${status['action'] ?? ''}',
        'description': status['action'] ?? '',
        'time': formattedTime,
        'icon': status['icon'] ?? Icons.notifications,
        'color': status['color'] ?? AppColors.childPrimary,
      };
    }).toList();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController.forward();
    _slideController.forward();
  }

  /// Show SOS Alert Modal (AC 4.2.5, Task 7) - Story 4.2
  Future<void> _showSOSAlertModal(String sosId) async {
    // Vibrate device
    HapticFeedback.heavyImpact();

    // Navigate to full-screen SOS alert screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SOSAlertScreen(sosId: sosId),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  void dispose() {
    final socketService = SocketService();
    socketService.onSosAlert = null;
    socketService.onGeofenceAlert = null;

    _fadeController.dispose();
    _slideController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentStatuses() async {
    try {
      final apiService = ApiService();

      final geofenceData = await apiService.getGeofenceAlerts(limit: 10);
      final geofenceAlerts = (geofenceData['alerts'] as List?) ?? [];
      final sosAlerts = await apiService.getActiveSOS();

      if (!mounted) return;

      final allStatuses = <Map<String, dynamic>>[];

      for (final alert in geofenceAlerts) {
        final childData = alert['childId'] ?? alert['child'];
        final childName =
            childData?['name'] ??
            childData?['fullName'] ??
            alert['childName'] ??
            'Trẻ không rõ';

        final geofenceInfo = alert['geofenceId'] ?? alert['geofence'];
        final geofenceMap = geofenceInfo is Map ? geofenceInfo : null;
        final geofenceName =
            geofenceMap?['name'] ?? alert['geofenceName'] ?? 'vùng';
        final zoneType =
            (geofenceMap?['type'] ??
                    alert['zoneType'] ??
                    alert['geofenceType'] ??
                    'safe')
                .toString();

        final actionRaw =
            (alert['action'] as String?) ?? (alert['type'] as String?) ?? '';
        final timestamp =
            _normalizeTimestamp(alert['timestamp']) ??
            _normalizeTimestamp(alert['createdAt']) ??
            DateTime.now();

        final status = _composeGeofenceStatus(
          childName: childName,
          geofenceName: geofenceName,
          zoneType: zoneType,
          action: actionRaw,
          timestamp: timestamp,
        );

        if (geofenceInfo != null) {
          if (geofenceMap != null) {
            status['geofenceId'] =
                geofenceMap['_id']?.toString() ??
                geofenceMap['id']?.toString() ??
                geofenceMap.toString();
          } else {
            status['geofenceId'] = geofenceInfo.toString();
          }
        }
        status['geofenceName'] = geofenceName;
        if (alert['location'] != null) {
          status['location'] = alert['location'];
        }

        allStatuses.add(status);
      }

      for (final sos in sosAlerts) {
        final childData = sos['childId'];
        final childName =
            childData?['name'] ??
            childData?['fullName'] ??
            sos['childName'] ??
            'Trẻ không rõ';

        final timestamp =
            _normalizeTimestamp(sos['timestamp'] ?? sos['createdAt']) ??
            DateTime.now();

        final status = _composeSosStatus(
          childName: childName,
          timestamp: timestamp,
        );

        final sosId = sos['_id'] ?? sos['id'] ?? sos['sosId'];
        if (sosId != null) {
          status['sosId'] = sosId.toString();
        }

        allStatuses.add(status);
      }

      _setRecentStatuses(allStatuses);
    } catch (error) {
      print('Error loading statuses: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải hoạt động gần đây')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name ?? 'Phụ huynh';
    final linkedChildren =
        authProvider.user?.linkedUsersData
            .where((user) => user['role'] == 'child')
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadRecentStatuses,
            color: AppColors.parentPrimary,
            child: SafeArea(
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
                    title: _buildHeaderWithGlass(userName),
                    centerTitle: false,
                    toolbarHeight: 70,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMembersSection(linkedChildren),
                          const SizedBox(height: AppSpacing.xl),
                          _buildRecentStatusSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showNotificationPanel)
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, _) {
                return Positioned(
                  top:
                      AppBar().preferredSize.height +
                      MediaQuery.of(context).padding.top +
                      AppSpacing.md,
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: NotificationPanel(
                    notificationProvider: notificationProvider,
                    onClose: () =>
                        setState(() => _showNotificationPanel = false),
                  ),
                );
              },
            ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                AppColors.parentPrimary,
                AppColors.parentPrimary,
                AppColors.parentPrimary,
                AppColors.parentPrimary,
                AppColors.success,
                AppColors.success,
                AppColors.info,
                AppColors.info,
                AppColors.warning,
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreetingPart() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Chào buổi sáng, ';
    } else if (hour >= 12 && hour < 17) {
      return 'Chào buổi chiều, ';
    } else if (hour >= 17 && hour < 21) {
      return 'Chào buổi tối, ';
    } else {
      return 'Chào bạn, ';
    }
  }

  Widget _buildHeaderWithGlass(String userName) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.8),
                border: Border.all(
                  color: AppColors.parentPrimary.withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor.withOpacity(0.1),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: AppColors.parentPrimary.withOpacity(0.05),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: AppTypography.h2,
                            children: <TextSpan>[
                              TextSpan(
                                text: _getGreetingPart(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              TextSpan(
                                text: userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (notificationProvider.unreadCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Bạn có ${notificationProvider.unreadCount} thông báo mới',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        builder: (_) => NotificationCenter(
                          pendingRequestsCount: 0,
                          recentActivities: _formatRecentActivities(),
                          sosSignals: _sosSignals,
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.parentPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            size: 28,
                            color: notificationProvider.unreadCount > 0
                                ? AppColors.danger
                                : AppColors.textSecondary,
                          ),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: NotificationBadge(
                            count: notificationProvider.unreadCount,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.parentPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 28,
                        color: AppColors.parentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMembersSection(List<Map<String, dynamic>> children) {
    print('[MEMBERS] Total children: ${children.length}');
    for (var i = 0; i < children.length; i++) {
      print(
        '[CHILD_$i] ID: ${children[i]['_id'] ?? children[i]['id']}, Name: ${children[i]['name']}',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trẻ em của bạn', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.lg),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...children.asMap().entries.map((entry) {
                final child = entry.value;
                final childId = child['_id'] ?? child['id'] ?? '';
                final childName = child['name'] ?? 'Trẻ';
                final isSafe = true; // TODO: lấy trạng thái an toàn thực tế
                print(
                  '[BUILD_CARD] Building card for: $childName, ID: $childId',
                );
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: _buildMemberCard(
                    childId: childId,
                    name: childName,
                    isSafe: isSafe,
                  ),
                );
              }),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LinkChildScreen()),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.parentPrimary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.parentPrimary.withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.parentPrimary.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 32,
                        color: AppColors.parentPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Thêm',
                      style: AppTypography.label.copyWith(
                        color: AppColors.parentPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'thành viên',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.parentPrimary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard({
    required String childId,
    required String name,
    required bool isSafe,
  }) {
    final color = isSafe ? AppColors.success : AppColors.danger;
    final bgColor = isSafe
        ? AppColors.success.withOpacity(0.1)
        : AppColors.danger.withOpacity(0.1);
    final statusText = isSafe ? 'An toàn' : 'Không an toàn';

    return MemberCardWithInteraction(
      name: name,
      color: color,
      bgColor: bgColor,
      statusText: statusText,
      onTap: () {
        HapticFeedback.mediumImpact();
        print('[CARD_TAP] Tapped child: $name, ID: $childId');
        _showChildMapScreen(childId, name, isSafe);
      },
    );
  }

  Future<void> _showChildMapScreen(
    String childId,
    String childName,
    bool isSafe,
  ) async {
    print('[SHOW_MAP] START - Child: $childName, ID: $childId');
    final apiService = ApiService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      late Map<String, dynamic> locationData;
      late List<Map<String, dynamic>> screenTimeData;

      try {
        print('[API_CALL] Calling getChildLatestLocation for: $childId');
        locationData = await apiService.getChildLatestLocation(childId);
        print(
          '[API_RESPONSE] Got location data: childId=${locationData['data']?['childId']}, lat=${locationData['data']?['location']?['latitude']}, lon=${locationData['data']?['location']?['longitude']}',
        );
        if (locationData.isEmpty) {
          locationData = {'data': null};
        }
      } catch (error) {
        debugPrint('[ChildDetail] Location API error: $error - Using fallback');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải vị trí: $error')));
        locationData = {'data': null};
      }

      try {
        screenTimeData = await apiService.getScreenTimeUsageHistory(
          childId: childId,
          startDate: DateTime.now().toIso8601String(),
          endDate: DateTime.now().toIso8601String(),
        );
      } catch (error) {
        debugPrint(
          '[ChildDetail] Screen time API error: $error - Using fallback',
        );
        screenTimeData = [];
      }

      if (!mounted) return;

      Navigator.pop(context);

      final location =
          locationData['data']?['location'] as Map<String, dynamic>?;
      print(
        '[LOCATION_DATA] Extracted location for $childName: lat=${location?['latitude']}, lon=${location?['longitude']}',
      );
      final batteryLevel =
          (location?['batteryLevel'] ?? location?['battery'] ?? 75) as int;
      final latitude = (location?['latitude'] as num?)?.toDouble();
      final longitude = (location?['longitude'] as num?)?.toDouble();

      String address = 'Không xác định';
      if (latitude != null && longitude != null) {
        address = await GeocodeService.getAddress(latitude, longitude);
      }
      print('[ADDRESS] For $childName: $address');

      final updatedAt =
          location?['timestamp'] ?? locationData['data']?['timestamp'];
      final inSafeZone = isSafe;

      String lastSeen = 'Chưa cập nhật';
      if (updatedAt is String) {
        try {
          final lastTime = DateTime.parse(updatedAt);
          final diff = DateTime.now().difference(lastTime);
          if (diff.inMinutes < 1) {
            lastSeen = 'Vừa xong';
          } else if (diff.inMinutes < 60) {
            lastSeen = '${diff.inMinutes} phút trước';
          } else if (diff.inHours < 24) {
            lastSeen = '${diff.inHours} giờ trước';
          } else {
            lastSeen = '${diff.inDays} ngày trước';
          }
        } catch (_) {}
      }

      int screenTimeMinutes = 0;
      for (final item in screenTimeData) {
        screenTimeMinutes += (item['totalMinutes'] ?? 0) as int;
      }

      final selectedLocation = location != null
          ? location_model.Location.fromJson(location)
          : null;

      final childDetail = ChildDetailData(
        childId: childId,
        name: childName,
        batteryLevel: batteryLevel,
        lastSeen: lastSeen,
        locationName: address,
        isInSafeZone: inSafeZone,
        screenTimeMinutes: screenTimeMinutes,
        screenTimeLimit: 240,
        selectedLocation: selectedLocation,
      );

      if (!mounted) return;
      print(
        '[NAVIGATE] Opening map for $childName (ID: $childId) with location: ${childDetail.selectedLocation?.latitude}, ${childDetail.selectedLocation?.longitude}',
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChildMapScreen(
            childId: childId,
            childName: childName,
            childDetail: childDetail,
            selectedLocation: childDetail.selectedLocation,
          ),
        ),
      );
    } catch (error) {
      debugPrint('[ChildDetail] Error loading data: $error');
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $error')));
    }
  }

  Widget _buildRecentStatusSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: AppColors.parentPrimary.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withOpacity(0.08),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.parentPrimary.withOpacity(0.03),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _fadeController,
                child: Text('Trạng thái gần đây', style: AppTypography.h3),
              ),
              const SizedBox(height: AppSpacing.md),
              ..._recentStatuses.asMap().entries.map((entry) {
                final index = entry.key;
                final status = entry.value;
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.3, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _slideController,
                          curve: Interval(
                            (index * 0.2).clamp(0.0, 1.0),
                            ((index + 1) * 0.2).clamp(0.0, 1.0),
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildStatusItem(status),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(Map<String, dynamic> status) {
    final bool isWarning = status['isWarning'] == true;
    final Color color =
        status['color'] as Color? ??
        (isWarning ? AppColors.danger : AppColors.success);
    final IconData icon =
        status['icon'] as IconData? ??
        (isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline);

    String formattedTime = 'Vừa xong';
    final timestamp = _statusTimestamp(status);
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) {
      formattedTime = 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      formattedTime = '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      formattedTime = '${diff.inHours} giờ trước';
    } else {
      formattedTime = '${diff.inDays} ngày trước';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isWarning ? color.withOpacity(0.5) : AppColors.divider,
          width: isWarning ? 1.5 : 1,
        ),
        boxShadow: isWarning
            ? [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${status['name']} ',
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: status['action'] as String? ?? '',
                        style: AppTypography.label.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isWarning)
            Icon(Icons.warning_amber_rounded, color: color, size: 24),
        ],
      ),
    );
  }

}
