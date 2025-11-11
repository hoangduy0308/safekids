import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/battery_service.dart';
import '../../theme/app_typography.dart';

/// Location Settings Screen (Task 2.5)
/// Allows child to control location sharing, tracking interval, and pause tracking
class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  bool _sharingEnabled = true;
  String _trackingInterval = 'continuous';
  DateTime? _pausedUntil;
  Timer? _countdownTimer;
  bool _isLoading = true;
  String? _error;
  int _currentBatteryLevel = 100; // Task 2.6.5: Battery stats

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeBattery();
  }

  void _initializeBattery() {
    // Task 2.6.5: Get current battery level
    BatteryService.instance.getCurrentBatteryLevel().then((level) {
      if (mounted) {
        setState(() => _currentBatteryLevel = level);
      }
    });

    // Listen to battery changes
    BatteryService.instance.onBatteryChanged = (level) {
      if (mounted) {
        setState(() => _currentBatteryLevel = level);
      }
    };
  }

  /// Load settings from SharedPreferences and sync with backend
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _sharingEnabled = prefs.getBool('sharingEnabled') ?? true;
        _trackingInterval = prefs.getString('trackingInterval') ?? 'continuous';
        final pausedStr = prefs.getString('pausedUntil');
        _pausedUntil = pausedStr != null ? DateTime.parse(pausedStr) : null;
      });

      // Check if pause expired
      if (_pausedUntil != null && _pausedUntil!.isBefore(DateTime.now())) {
        setState(() => _pausedUntil = null);
        await _saveSettings();
      }

      // Start countdown if paused
      if (_pausedUntil != null && _pausedUntil!.isAfter(DateTime.now())) {
        _startCountdown();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải cài đặt: $e';
        _isLoading = false;
      });
    }
  }

  /// Update sharing toggle and sync
  Future<void> _updateSharing(bool enabled) async {
    setState(() => _sharingEnabled = enabled);
    await _saveSettings();

    if (enabled) {
      LocationService().startTracking();
    } else {
      LocationService().stopTracking();
    }
  }

  /// Update tracking interval and sync
  Future<void> _updateInterval(String interval) async {
    setState(() => _trackingInterval = interval);
    await _saveSettings();
    LocationService().updateInterval(interval);
  }

  /// Pause tracking for 30 minutes
  Future<void> _pauseFor30Minutes() async {
    final pausedUntil = DateTime.now().add(const Duration(minutes: 30));
    setState(() => _pausedUntil = pausedUntil);
    await _saveSettings();

    LocationService().stopTracking();
    _startCountdown();
  }

  /// Resume tracking immediately
  Future<void> _resumeNow() async {
    setState(() => _pausedUntil = null);
    await _saveSettings();

    LocationService().startTracking();
    _countdownTimer?.cancel();
  }

  /// Start countdown timer for pause expiry
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pausedUntil != null && _pausedUntil!.isBefore(DateTime.now())) {
        _resumeNow();
        timer.cancel();
      } else if (mounted) {
        setState(() {}); // Update countdown display
      }
    });
  }

  /// Save settings to SharedPreferences and backend
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sharingEnabled', _sharingEnabled);
      await prefs.setString('trackingInterval', _trackingInterval);
      if (_pausedUntil != null) {
        await prefs.setString('pausedUntil', _pausedUntil!.toIso8601String());
      } else {
        await prefs.remove('pausedUntil');
      }

      // Sync to backend
      try {
        await ApiService().updateLocationSettings(
          _sharingEnabled,
          _trackingInterval,
          _pausedUntil?.toIso8601String(),
        );
      } catch (e) {
        debugPrint('Error syncing settings to backend: $e');
        // Don't fail if sync fails - local settings still saved
      }
    } catch (e) {
      setState(() => _error = 'Lỗi lưu cài đặt: $e');
    }
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Get remaining time string
  String _getRemainingTime() {
    if (_pausedUntil == null) return '';
    final remaining = _pausedUntil!.difference(DateTime.now());
    if (remaining.isNegative) return '';
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '(còn $minutes phút $seconds giây)';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cài Đặt Vị Trí')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cài Đặt Vị Trí')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Error message
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: AppTypography.bodySmall.copyWith(color: Colors.red),
              ),
            ),

          const SizedBox(height: 16),

          // Sharing toggle
          SwitchListTile(
            title: const Text('Chia sẻ vị trí'),
            subtitle: Text(
              _sharingEnabled
                  ? 'Phụ huynh có thể xem vị trí của bạn'
                  : 'Vị trí không được chia sẻ',
            ),
            value: _sharingEnabled,
            onChanged: _updateSharing,
            secondary: Icon(
              Icons.location_on,
              color: _sharingEnabled ? Colors.green : Colors.grey,
            ),
          ),

          // Warning if disabled
          if (!_sharingEnabled)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tắt chia sẻ có thể ảnh hưởng đến an toàn của bạn',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Tracking interval section
          Text(
            'Tần suất cập nhật',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          RadioListTile<String>(
            title: const Text('Liên tục (30 giây)'),
            subtitle: const Text('Chính xác nhất, tốn pin nhiều'),
            value: 'continuous',
            groupValue: _trackingInterval,
            onChanged: (val) => _updateInterval(val!),
          ),

          RadioListTile<String>(
            title: const Text('Bình thường (2 phút)'),
            subtitle: const Text('Cân bằng giữa chính xác và tiết kiệm pin'),
            value: 'normal',
            groupValue: _trackingInterval,
            onChanged: (val) => _updateInterval(val!),
          ),

          RadioListTile<String>(
            title: const Text('Tiết kiệm pin (5 phút)'),
            subtitle: const Text('Tiết kiệm pin, ít chính xác hơn'),
            value: 'battery-saver',
            groupValue: _trackingInterval,
            onChanged: (val) => _updateInterval(val!),
          ),

          const SizedBox(height: 24),

          // Pause section
          Text(
            'Tạm dừng',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (_pausedUntil != null && _pausedUntil!.isAfter(DateTime.now()))
            Card(
              margin: EdgeInsets.zero,
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.pause_circle, size: 48, color: Colors.blue[600]),
                    const SizedBox(height: 12),
                    Text(
                      'Đã tạm dừng cho đến',
                      style: AppTypography.caption.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(_pausedUntil!),
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getRemainingTime(),
                      style: AppTypography.captionSmall.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _resumeNow,
                      child: const Text('Tiếp tục ngay'),
                    ),
                  ],
                ),
              ),
            )
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.pause),
              label: const Text('Tạm dừng 30 phút'),
              onPressed: _pauseFor30Minutes,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

          // Battery Stats Section (Task 2.6.5)
          const SizedBox(height: 24),
          _buildBatteryStats(),
        ],
      ),
    );
  }

  /// Build battery stats card (Task 2.6.5)
  Widget _buildBatteryStats() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.battery_charging_full,
                  color: _getBatteryColor(_currentBatteryLevel),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mức Pin Hiện Tại',
                      style: AppTypography.captionSmall.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '$_currentBatteryLevel%',
                      style: AppTypography.h2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Ước Tính Tiêu Thụ',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '~${_getEstimatedDrain()}% mỗi giờ',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              'Chế độ: ${_getTrackingModeName()}',
              style: AppTypography.captionSmall.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              '💡 Mẹo Tiết Kiệm Pin:',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildTip('Giảm tần suất cập nhật xuống "Bình thường"'),
            _buildTip('Tắt chia sẻ vị trí khi ở nhà'),
            _buildTip('Sạc điện thoại khi có thể'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(text, style: AppTypography.captionSmall)),
        ],
      ),
    );
  }

  String _getTrackingModeName() {
    if (_currentBatteryLevel > 50) return 'Bình thường';
    if (_currentBatteryLevel > 20) return 'Tiết kiệm';
    if (_currentBatteryLevel > 10) return 'Siêu tiết kiệm';
    return 'Khẩn cấp';
  }

  int _getEstimatedDrain() {
    if (_currentBatteryLevel > 50) return 2;
    if (_currentBatteryLevel > 20) return 1;
    if (_currentBatteryLevel > 10) return 0;
    return 0;
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    if (level > 10) return Colors.red;
    return Colors.deepOrange;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
