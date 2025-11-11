import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../chat/chat_list_screen.dart';
import 'geofence_list_screen.dart';
import 'parent_home_screen.dart';
import 'sos_history_screen.dart';
import 'screentime_management_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  int _currentTabIndex = 0;

  final _navItems = [
    {
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home,
      'label': 'Trang chủ',
    },
    {
      'icon': Icons.chat_bubble_outline,
      'activeIcon': Icons.chat_bubble,
      'label': 'Tin nhắn',
    },
    {
      'icon': Icons.settings_outlined,
      'activeIcon': Icons.settings,
      'label': 'Quản lí',
    },
    {
      'icon': Icons.person_outline,
      'activeIcon': Icons.person,
      'label': 'Cá nhân',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _getScreenByTabIndex(_currentTabIndex),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildGlassNavBar()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => Navigator.pushNamed(context, '/map-smoke-test'),
        tooltip: 'Map Smoke Test',
        child: const Icon(Icons.map),
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
                  final isSelected = _currentTabIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTabIndex = index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected
                                ? item['activeIcon'] as IconData
                                : item['icon'] as IconData,
                            color: isSelected
                                ? AppColors.parentPrimary
                                : AppColors.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['label'] as String,
                            style: AppTypography.captionSmall.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.parentPrimary
                                  : AppColors.textPrimary,
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

  Widget _getScreenByTabIndex(int index) {
    switch (index) {
      case 0:
        return const ParentHomeScreen();
      case 1:
        return const ChatListScreen();
      case 2:
        return _buildManagementScreen();
      case 3:
        return _buildProfileScreen();
      default:
        return const ParentHomeScreen();
    }
  }

  Widget _buildManagementScreen() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lí'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppColors.parentPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.parentPrimary,
            tabs: const [
              Tab(icon: Icon(Icons.location_on, size: 20), text: 'Vùng'),
              Tab(icon: Icon(Icons.schedule, size: 20), text: 'Thời gian'),
              Tab(icon: Icon(Icons.emergency, size: 20), text: 'SOS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            GeofenceListScreen(),
            ScreenTimeManagementScreen(),
            SOSHistoryScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá nhân'),
        backgroundColor: AppColors.parentPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Text('Tính năng cá nhân sắp có', style: AppTypography.h3),
      ),
    );
  }
}
