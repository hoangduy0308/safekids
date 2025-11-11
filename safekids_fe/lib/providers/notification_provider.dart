import 'package:flutter/foundation.dart';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount {
    return _notifications.where((n) => !n.isRead).length;
  }

  List<NotificationItem> get sortedNotifications {
    final sorted = List<NotificationItem>.from(_notifications);
    sorted.sort((a, b) {
      if (a.isRead != b.isRead) {
        return a.isRead ? 1 : -1;
      }
      return b.timestamp.compareTo(a.timestamp);
    });
    return sorted;
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load notifications from local storage or in-memory (simulating Firebase)
      await Future.delayed(const Duration(milliseconds: 300));

      // In a real app, this would fetch from:
      // 1. Firebase Firestore/Realtime Database
      // 2. Backend API endpoint
      // 3. Local SQLite database

      // For now, keeping empty list for real data to be populated
      // by Firebase onMessage listeners
      if (_notifications.isEmpty) {
        _notifications = [];
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Lỗi tải thông báo: $e';
      debugPrint('[NotificationProvider] Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> dismissNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
  }

  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}
