import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _token;
  User? _currentUser;

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _currentUser != null;

  /// Initialize auth service - load token from storage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.keyToken);

    if (_token != null) {
      final userJson = prefs.getString(AppConstants.keyUserData);
      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
      }
    }
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    int? age,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': name, // Send as fullName to backend
          'email': email,
          'password': password,
          'role': role,
          'phone': phone,
          'age': age,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Save token and user
        await _saveAuthData(data['token'], data['user']);
        return {'success': true, 'data': data};
      } else {
        // Backend returns 'message' field for errors
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.login),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveAuthData(data['token'], data['user']);
        return {'success': true, 'data': data};
      } else {
        // Backend returns 'message' field for errors
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể kết nối. Vui lòng kiểm tra mạng.',
      };
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getMe() async {
    if (_token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.getMe),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
          )
          .timeout(Duration(seconds: 10)); // Add timeout

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(data['user']);
        await _saveUserData(data['user']);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message':
              data['message'] ?? data['error'] ?? 'Failed to fetch profile',
        };
      }
    } on TimeoutException catch (e) {
      // Timeout = network issue, not auth error
      return {'success': false, 'message': 'Network timeout: $e'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Link parent with child account by email
  Future<Map<String, dynamic>> linkChild(String childEmail) async {
    if (_token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.linkAccounts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'childEmail': childEmail}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Refresh profile to get updated linkedUsers
        await getMe();
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Linking failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Logout user
  Future<void> logout() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyToken);
    await prefs.remove(AppConstants.keyUserData);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserRole);
  }

  /// Save auth data to storage
  Future<void> _saveAuthData(
    String token,
    Map<String, dynamic> userData,
  ) async {
    _token = token;
    _currentUser = User.fromJson(userData);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyToken, token);
    await prefs.setString(AppConstants.keyUserData, jsonEncode(userData));
    await prefs.setString(AppConstants.keyUserId, _currentUser!.id);
    await prefs.setString(AppConstants.keyUserRole, _currentUser!.role);
  }

  /// Save user data to storage
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserData, jsonEncode(userData));
  }

  /// Get authorization headers
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }
}
