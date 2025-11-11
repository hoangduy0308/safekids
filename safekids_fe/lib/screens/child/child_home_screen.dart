import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/socket_service.dart';
import '../../services/api_service.dart';
import '../../services/battery_service.dart';
import '../../widgets/child/location_permission_dialog.dart';
import '../../widgets/child/link_request_dialog.dart';
import '../../widgets/child/pending_link_requests_dialog.dart';
import '../../widgets/common/offline_indicator.dart';
import '../../widgets/battery_optimization_guide.dart';
import './location_settings_screen.dart';
import './sos_countdown_dialog.dart';
import './sos_success_screen.dart';
import '../../utils/offline_sos_queue.dart';
import '../../widgets/child/screentime_usage_widget.dart';
import '../../widgets/child/notification_center.dart';
import '../chat/chat_list_screen.dart';
import '../shared/profile_screen.dart';
import './time_management_screen.dart';
import './notifications_screen.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({Key? key}) : super(key: key);

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final _locationService = LocationService();
  final _socketService = SocketService();
  final Set<String> _processedRequests = {};
  int _pendingRequestsCount = 0;
  List<Map<String, dynamic>> _sosSignals = [];

  final _navItems = [
    {'icon': Icons.home_rounded, 'label': 'Trang chủ'},
    {'icon': Icons.access_time_rounded, 'label': 'Thời gian'},
    {'icon': Icons.notifications_rounded, 'label': 'Thông báo'},
    {'icon': Icons.person_rounded, 'label': 'Cá nhân'},
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
    _initLocationTracking();
    _initSocketConnection();
    _loadPendingRequestsCount();
    _loadSOSSignals();
  }

  Future<void> _loadPendingRequestsCount() async {
    try {
      final requests = await ApiService().getLinkRequests(status: 'pending');
      if (mounted) {
        setState(() {
          _pendingRequestsCount = requests.length;
        });
      }
    } catch (e) {
      debugPrint('[ChildHome] Error loading requests: $e');
    }
  }

  Future<void> _loadSOSSignals() async {
    try {
      // TODO: Fetch SOS signals from backend
      // For now, create sample data structure
      if (mounted) {
        setState(() {
          _sosSignals = [
            // Sample SOS signal structure:
            // {
            //   'id': 'sos_1',
            //   'description': 'Tín hiệu SOS đã được gửi đến phụ huynh',
            //   'location': 'Quận 1, Tp.HCM',
            //   'time': '5 phút trước',
            // }
          ];
        });
      }
    } catch (e) {
      debugPrint('[ChildHome] Error loading pending requests: $e');
    }
  }

  List<Map<String, dynamic>> _formatRecentActivities() {
    // TODO: Add recent activities for child (chat, achievements, etc)
    return [];
  }

  Future<void> _initLocationTracking() async {
    await _locationService.initialize();
    await _loadLocationSettings();
    final batteryService = BatteryService();
    await batteryService.startMonitoring();
    if (mounted) {
      BatteryOptimizationGuide.showGuideIfNeeded(context);
    }
    final hasPermission = await _locationService.requestLocationPermission();
    if (!hasPermission && mounted) {
      showDialog(
        context: context,
        builder: (_) => LocationPermissionDialog(
          onGranted: () => _locationService.startTracking(),
        ),
      );
    } else if (hasPermission && mounted) {
      _locationService.startTracking();
    }
    _locationService.addListener(_onLocationServiceChange);
  }

  Future<void> _loadLocationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sharingEnabled = prefs.getBool('sharingEnabled') ?? true;
      final trackingInterval =
          prefs.getString('trackingInterval') ?? 'continuous';
      final pausedStr = prefs.getString('pausedUntil');
      final pausedUntil = pausedStr != null ? DateTime.parse(pausedStr) : null;

      if (!sharingEnabled) return;
      if (pausedUntil != null && pausedUntil.isAfter(DateTime.now())) return;

      await _locationService.updateInterval(trackingInterval);
    } catch (e) {
      debugPrint('[ChildHome] Error loading location settings: $e');
    }
  }

  void _onLocationServiceChange() {}

  void _initSocketConnection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId != null) {
      _socketService.connect(userId);
      _socketService.onLinkRequest = (data) {
        final requestId = data['requestId'] ?? '';
        if (_processedRequests.contains(requestId)) return;

        if (mounted) {
          _processedRequests.add(requestId);
          _loadPendingRequestsCount();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => LinkRequestDialog(
              requestId: requestId,
              senderName: data['sender']?['name'] ?? '',
              senderEmail: data['sender']?['email'] ?? '',
              senderRole: data['sender']?['role'] ?? '',
              message: data['message'],
            ),
          ).then((accepted) {
            if (accepted == true) {
              authProvider.refreshUser();
              _loadPendingRequestsCount();
            }
          });
        }
      };

      _socketService.onLinkRemoved = (data) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${data['parentName']} đã xóa liên kết với bạn'),
              backgroundColor: Colors.orange,
            ),
          );
          authProvider.refreshUser();
        }
      };
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _locationService.removeListener(_onLocationServiceChange);
    _socketService.disconnect();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Chào buổi sáng';
    if (hour >= 11 && hour < 13) return 'Chào buổi trưa';
    if (hour >= 13 && hour < 17) return 'Chào buổi chiều';
    if (hour >= 17 && hour < 21) return 'Chào buổi tối';
    return 'Chúc ngủ ngon';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name ?? 'Bạn';

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: Stack(
        children: [
          if (_currentIndex == 0)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.childPrimary.withOpacity(0.05),
                    Color(0xFFF5F7FA),
                    Color(0xFFF5F7FA),
                  ],
                  stops: [0.0, 0.2, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: CustomScrollView(
                  physics: BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildMinimalHeader(authProvider)),
                    SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
                    SliverToBoxAdapter(
                      child: _buildPersonalizedGreeting(userName),
                    ),
                    SliverToBoxAdapter(
                      child: ChangeNotifierProvider<LocationService>.value(
                        value: _locationService,
                        child: const OfflineIndicator(),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildSOSCard(context),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
                    SliverToBoxAdapter(child: _buildScreenTimeWidget()),
                    SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          'Hoạt động của bạn',
                          style: AppTypography.h3.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildActivityGrid(context),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          if (_currentIndex == 1)
            const TimeManagementScreen(),
          if (_currentIndex == 2)
            const NotificationsScreen(),
          if (_currentIndex == 3)
            const ProfileScreen(),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildGlassNavBar()),
        ],
      ),
    );
  }

  Widget _buildGlassNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.8),
                border: Border.all(color: AppColors.surface.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _navItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = _currentIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: isSelected
                                ? AppColors.childPrimary
                                : AppColors.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.childPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalHeader(AuthProvider authProvider) {
    final linkedParents =
        authProvider.user?.linkedUsersData
            .where((u) => u['role'] == 'parent')
            .toList() ??
        [];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SafeKids',
            style: AppTypography.h3.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              if (linkedParents.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.childPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.childPrimary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.family_restroom,
                        color: AppColors.childPrimary,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${linkedParents.length}',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.childPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(width: AppSpacing.sm),
              _buildNotificationButton(),
              SizedBox(width: AppSpacing.sm),
              _buildSoftIconButton(
                icon: Icons.settings,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationSettingsScreen(),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              _buildSoftIconButton(
                icon: Icons.logout_rounded,
                onTap: () => _showLogoutDialog(context, authProvider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoftIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(0xFFF5F7FA),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: Offset(4, 4),
              blurRadius: 8,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              offset: Offset(-2, -2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => NotificationCenter(
            pendingRequestsCount: _pendingRequestsCount,
            onShowPendingRequests: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => PendingLinkRequestsDialog(
                  onRequestsUpdated: _loadPendingRequestsCount,
                ),
              ).then((_) => _loadPendingRequestsCount());
            },
            recentActivities: _formatRecentActivities(),
            sosSignals: _sosSignals,
          ),
        ).then((_) => _loadPendingRequestsCount());
      },
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFF5F7FA),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: Offset(4, 4),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  offset: Offset(-2, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_rounded,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildPersonalizedGreeting(String userName) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: _getGreeting(),
              style: AppTypography.h1.copyWith(
                fontWeight: FontWeight.w300,
                color: AppColors.textSecondary,
                letterSpacing: -0.5,
              ),
            ),
            TextSpan(
              text: ', ',
              style: AppTypography.h1.copyWith(
                fontWeight: FontWeight.w300,
                color: AppColors.textSecondary,
              ),
            ),
            TextSpan(
              text: userName,
              style: AppTypography.h1.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenTimeWidget() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ScreenTimeUsageWidget(),
    );
  }

  Widget _buildSOSCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF5252), Color(0xFFE91E63)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withOpacity(0.4),
            blurRadius: 24,
            offset: Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.danger.withOpacity(0.2),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleSOSPress(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.emergency,
                    color: Color(0xFFFF5252),
                    size: 44,
                  ),
                ),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'KHẨN CẤP',
                        style: AppTypography.overline.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Nút SOS',
                        style: AppTypography.h2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Nhấn để gửi cảnh báo ngay',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityGrid(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          _buildActivityCard(
            Icons.access_time_rounded,
            'Thời gian sử dụng',
            'Xem thời gian bạn đã dùng thiết bị',
            AppColors.childAccent,
            onTap: () => setState(() => _currentIndex = 1),
          ),
          SizedBox(height: AppSpacing.md),
          _buildChatCard(context),
          SizedBox(height: AppSpacing.md),
          _buildActivityCard(
            Icons.notifications_active_rounded,
            'Thông báo',
            'Xem tất cả thông báo của bạn',
            AppColors.warning,
            onTap: () => setState(() => _currentIndex = 2),
          ),
          SizedBox(height: AppSpacing.md),
          _buildActivityCard(
            Icons.stars_rounded,
            'Phần thưởng',
            'Nhận thưởng khi hoàn thành tốt',
            AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatListScreen()),
      ),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              offset: Offset(4, 4),
              blurRadius: 12,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.9),
              offset: Offset(-3, -3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.childPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.chat_bubble_rounded,
                color: AppColors.childPrimary,
                size: 28,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tin nhắn',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Chat với ba mẹ và gia đình',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.childPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Mở',
                style: AppTypography.overline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.childPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    IconData icon,
    String title,
    String description,
    Color color, {
    VoidCallback? onTap,
  }) {
    final hasAction = onTap != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              offset: Offset(4, 4),
              blurRadius: 12,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.9),
              offset: Offset(-3, -3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasAction ? color.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hasAction ? 'Mở' : 'Sắp có',
                style: AppTypography.overline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: hasAction ? color : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSOSPress(BuildContext context) async {
    print('[SOS] Button pressed');

    // Show countdown dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SOSCountdownDialog(
        duration: Duration(seconds: 3),
        onConfirm: () async {
          print('[SOS] Countdown confirmed, triggering SOS');
          await _triggerSOS(context);
        },
        onCancel: () {
          print('[SOS] Countdown cancelled');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cảnh báo đã bị hủy'),
              backgroundColor: Colors.grey[600],
            ),
          );
        },
      ),
    );
  }

  Future<void> _triggerSOS(BuildContext context) async {
    try {
      print('[SOS] Collecting SOS data...');

      // Get location
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        print('[SOS] ERROR: No location available');
        _showSOSError(context, 'Không thể lấy vị trí. Vui lòng bật định vị.');
        return;
      }

      // Get battery level
      final batteryService = BatteryService();
      final batteryLevel = batteryService.batteryLevel;

      // Prepare SOS data
      final sosData = {
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'accuracy': location.accuracy,
        },
        'batteryLevel': batteryLevel,
        'networkStatus': 'unknown',
      };

      print('[SOS] SOS data: $sosData');

      // Trigger SOS API
      final apiService = ApiService();
      final response = await apiService.triggerSOS(
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
        batteryLevel: batteryLevel,
        networkStatus: 'unknown',
      );

      print('[SOS] API Response: $response');

      // Show success screen
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        final parentNames = (authProvider.user?.linkedUsersData ?? [])
            .where((u) => u['role'] == 'parent')
            .map((u) => u['name']?.toString() ?? 'Phụ huynh')
            .toList();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => SOSSuccessScreen(
              parentNames: parentNames.isNotEmpty ? parentNames : ['Ba mẹ'],
              onDismiss: () {
                print('[SOS] Success screen dismissed');
              },
            ),
          ),
        );

        // Haptic feedback
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      print('[SOS] ERROR: $e');

      // Try to queue for offline
      try {
        final offlineQueue = OfflineSOSQueue();
        await offlineQueue.initialize();

        final location = await _locationService.getCurrentLocation();
        final batteryService = BatteryService();
        final batteryLevel = batteryService.batteryLevel;

        await offlineQueue.addToQueue({
          'location': {
            'latitude': location?.latitude ?? 0,
            'longitude': location?.longitude ?? 0,
            'accuracy': location?.accuracy,
          },
          'batteryLevel': batteryLevel,
          'networkStatus': 'unknown',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📡 Mất kết nối. SOS sẽ gửi khi có mạng'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (queueError) {
        print('[SOS] Queue error: $queueError');
        _showSOSError(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  void _showSOSError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: AppColors.danger,
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đăng xuất'),
        content: Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Đăng xuất',
              style: AppTypography.button.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await authProvider.logout();
    }
  }
}
