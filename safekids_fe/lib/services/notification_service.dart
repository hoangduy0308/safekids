import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Stream controllers for handling notification events
  final StreamController<RemoteMessage> _onMessageStream =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<RemoteMessage> _onMessageOpenedAppStream =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<RemoteMessage> _onBackgroundMessageStream =
      StreamController<RemoteMessage>.broadcast();

  // Global navigator key for navigation from notifications
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Error handling flag
  bool _firebaseAvailable = true;

  // Getters for subscribing to notification events
  Stream<RemoteMessage> get onMessage => _onMessageStream.stream;
  Stream<RemoteMessage> get onMessageOpenedApp =>
      _onMessageOpenedAppStream.stream;
  Stream<RemoteMessage> get onBackgroundMessage =>
      _onBackgroundMessageStream.stream;

  Future<void> initialize() async {
    try {
      // Initialize Firebase with fallback options
      try {
        await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
      } catch (e) {
        debugPrint('⚠️ [Notification] Permission request failed: $e');
        _firebaseAvailable = false;
      }

      // Get FCM token with error handling
      try {
        final token = await _firebaseMessaging.getToken();
        debugPrint('🔔 [Notification] FCM Token: $token');
        debugPrint('✅ [Notification] Firebase initialized successfully');
      } catch (e) {
        debugPrint('⚠️ [Notification] FCM token retrieval failed: $e');
        _firebaseAvailable = false;
      }

      // Setup message handlers with error trapping
      try {
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      } catch (e) {
        debugPrint('⚠️ [Notification] Message handlers setup failed: $e');
        _firebaseAvailable = false;
      }

      debugPrint('✅ [Notification] Service initialized');
    } catch (e) {
      debugPrint('❌ [Notification] Initialization error: $e');
      _firebaseAvailable = false;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      '🔔 [Notification] Foreground message: ${message.notification?.title}',
    );
    debugPrint('🔔 [Notification] Data: ${message.data}');

    // Add to stream for listeners
    _onMessageStream.add(message);

    // Handle specific notification types
    _handleNotificationData(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint(
      '🔔 [Notification] Message opened from background: ${message.data}',
    );

    // Add to stream for listeners
    _onMessageOpenedAppStream.add(message);

    // Handle navigation or other actions based on notification data
    _handleNotificationData(message);
  }

  void _handleNotificationData(RemoteMessage message) async {
    final data = message.data;

    if (data['type'] == 'geofence') {
      debugPrint('🔔 [Notification] Geofence alert received');
      _showGeofenceAlertSnackBar(message);
    } else if (data['type'] == 'sos') {
      // AC 4.2.2: Navigate to SOS Alert Screen (Story 4.2)
      debugPrint('🚨 [Notification] SOS alert received');
      _navigateToSOSAlert(data['sosId']);
    } else if (data['type'] == 'screentime_config_update') {
      // AC 5.1.7: Handle screen time config update (Story 5.1)
      debugPrint('⏰ [Notification] Screen time config update received');
      await _handleScreenTimeConfigUpdate(data);
    }
  }

  Future<void> _handleScreenTimeConfigUpdate(Map<String, dynamic> data) async {
    try {
      final dailyLimit = int.tryParse(data['dailyLimit'] ?? '120') ?? 120;
      final bedtimeEnabled = data['bedtimeEnabled'] == 'true';
      final bedtimeStart = data['bedtimeStart'] ?? '21:00';
      final bedtimeEnd = data['bedtimeEnd'] ?? '07:00';

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('screentime_daily_limit', dailyLimit);
      await prefs.setBool('screentime_bedtime_enabled', bedtimeEnabled);
      await prefs.setString('screentime_bedtime_start', bedtimeStart);
      await prefs.setString('screentime_bedtime_end', bedtimeEnd);

      debugPrint(
        '✅ [Notification] Screen time config saved: $dailyLimit minutes/day, bedtime: $bedtimeEnabled',
      );

      // Show silent notification to user (optional)
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cài đặt thời gian màn hình đã được cập nhật: ${dailyLimit ~/ 60}h ${dailyLimit % 60}p/ngày',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue.shade100,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        '❌ [Notification] Failed to handle screen time config update: $e',
      );
    }
  }

  void _showGeofenceAlertSnackBar(RemoteMessage message) {
    // Get current context from navigator key
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(message.notification?.body ?? 'Geofence alert'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade100,
          duration: Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Xem',
            textColor: Colors.orange.shade900,
            onPressed: () {
              _navigateToMap(message.data['geofenceId']);
            },
          ),
        ),
      );
    }
  }

  void _navigateToMap(String? geofenceId) {
    if (geofenceId != null) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.pushNamed(
          context,
          '/parent-dashboard',
          arguments: {'highlightGeofence': geofenceId},
        );
      }
    }
  }

  /// Navigate to SOS Alert Screen (AC 4.2.2) - Story 4.2
  void _navigateToSOSAlert(String? sosId) {
    if (sosId != null) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.pushNamed(context, '/sos-alert', arguments: {'sosId': sosId});
      }
    }
  }

  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('❌ [Notification] Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('🔔 [Notification] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ [Notification] Error subscribing to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('🔔 [Notification] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ [Notification] Error unsubscribing from topic: $e');
    }
  }

  void dispose() {
    _onMessageStream.close();
    _onMessageOpenedAppStream.close();
    _onBackgroundMessageStream.close();
  }
}

// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '🔔 [Notification] Background message: ${message.notification?.title}',
  );

  // Initialize Firebase if needed
  // await Firebase.initializeApp();

  // Handle background message
  final notificationService = NotificationService();
  notificationService._onBackgroundMessageStream.add(message);
}

// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
