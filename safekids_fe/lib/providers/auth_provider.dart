import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SocketService _socketService = SocketService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isParent => _user?.isParent ?? false;
  bool get isChild => _user?.isChild ?? false;

  /// Initialize provider
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _authService.init(); // Load token and user from local storage

    // If a token is loaded, try to verify it with the backend
    // But if offline, trust the cached auth (don't force logout)
    if (_authService.isAuthenticated) {
      debugPrint('[AuthProvider] 📍 Token found, verifying with backend...');
      final result = await _authService.getMe(); // API call to verify user
      debugPrint(
        '[AuthProvider] 🔍 getMe() result: ${result['message']}',
      ); // DEBUG

      if (result['success']) {
        debugPrint('[AuthProvider] ✅ User verified successfully');
        _user = _authService.currentUser;
        if (_user?.id != null) {
          _socketService.connect(_user!.id);
        }
      } else {
        final errorMsg = result['message'] ?? '';
        debugPrint(
          '[AuthProvider] ❓ Error message: "$errorMsg"',
        ); // DEBUG: Show full message

        // Check if error is network-related (offline) or auth-related (invalid token)
        final isNetworkError =
            errorMsg.contains('Network error') ||
            errorMsg.contains('timeout') ||
            errorMsg.contains('TimeoutException') ||
            errorMsg.contains('ClientException') ||
            errorMsg.contains('SocketException') ||
            errorMsg.contains('Connection refused') ||
            errorMsg.contains('Failed host lookup');
        final isConnectionError =
            errorMsg.contains('Không thể kết nối') ||
            errorMsg.contains('connection') ||
            errorMsg.contains('offline');

        debugPrint(
          '[AuthProvider] isNetworkError=$isNetworkError, isConnectionError=$isConnectionError',
        ); // DEBUG

        if (isNetworkError || isConnectionError) {
          // ✅ FIX: Offline - trust cached token and user data
          debugPrint('[AuthProvider] ⚠️ Offline mode: Using cached auth data');
          _user = _authService.currentUser;
          // Don't connect socket offline - will reconnect when online
        } else {
          // ❌ Real auth error (token expired/invalid, user deleted from DB)
          debugPrint(
            '[AuthProvider] ❌ Auth verification failed: $errorMsg - LOGGING OUT',
          );
          await _authService.logout();
          _user = null;
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    int? age,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
      role: role,
      phone: phone,
      age: age,
    );

    _isLoading = false;

    if (result['success']) {
      _user = _authService.currentUser;
      if (_user?.id != null) {
        _socketService.connect(_user!.id);
        // Send FCM token to backend after successful registration
        await _sendFCMToken();
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  /// Login user
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email: email, password: password);

    _isLoading = false;

    if (result['success']) {
      _user = _authService.currentUser;
      if (_user?.id != null) {
        _socketService.connect(_user!.id);
        // Send FCM token to backend after successful login
        await _sendFCMToken();
        // Refresh user data to get linked accounts
        await refreshUser();
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  /// Get and send FCM token to backend
  Future<void> _sendFCMToken() async {
    debugPrint('[AuthProvider] _sendFCMToken() called');
    try {
      debugPrint('[AuthProvider] Getting FCM token...');
      final fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('[AuthProvider] FCM token from Firebase: $fcmToken');

      if (fcmToken != null) {
        debugPrint(
          '[AuthProvider] ✅ FCM token obtained: ${fcmToken.substring(0, 20)}...',
        );
        await ApiService().updateFCMToken(fcmToken);
        debugPrint('[AuthProvider] ✅ FCM token sent to backend successfully');
      } else {
        debugPrint('[AuthProvider] ❌ FCM token is null!');
      }
    } catch (e) {
      debugPrint('[AuthProvider] ❌ Error sending FCM token: $e');
      // Don't fail login if FCM fails
    }
  }

  /// Link parent with child account
  Future<bool> linkChild(String childEmail) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.linkChild(childEmail);

    _isLoading = false;

    if (result['success']) {
      _user = _authService.currentUser;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _socketService.disconnect();
    await _authService.logout();
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    final result = await _authService.getMe();
    if (result['success']) {
      _user = _authService.currentUser;
      notifyListeners();
    }
  }

  /// Update user data (used after profile edit)
  void updateUserData(Map<String, dynamic> userData) {
    _user = User.fromJson(userData);
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Forgot password - request OTP via email or SMS
  Future<Map<String, dynamic>> forgotPassword(
    String contactInfo,
    String method,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService().forgotPassword(
        contactInfo: contactInfo,
        method: method,
      );
      _isLoading = false;
      notifyListeners();
      return {'success': true, 'data': result};
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  /// Reset password with OTP
  Future<Map<String, dynamic>> resetPassword(
    String contactInfo,
    String otp,
    String newPassword,
    String method,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService().resetPassword(
        contactInfo: contactInfo,
        otp: otp,
        newPassword: newPassword,
        method: method,
      );
      _isLoading = false;
      notifyListeners();
      return {'success': true, 'data': result};
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }
}
