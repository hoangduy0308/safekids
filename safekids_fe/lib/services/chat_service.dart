import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../constants/app_constants.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyToken);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      final body = jsonDecode(response.body);
      final message = body['message'] ?? body['error'] ?? 'Unknown error';
      throw Exception(message);
    }
  }

  /// Get all conversations
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.conversations),
        headers: headers,
      );

      _handleError(response);
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } catch (e) {
      rethrow;
    }
  }

  /// Get or create conversation with participant
  Future<Map<String, dynamic>> getOrCreateConversation(
    String participantId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.getOrCreateConversation(participantId)),
        headers: headers,
      );

      _handleError(response);
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } catch (e) {
      rethrow;
    }
  }

  /// Get messages in conversation
  Future<Map<String, dynamic>> getMessages(
    String conversationId, {
    int limit = 50,
    int skip = 0,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(ApiConfig.getMessages(conversationId)).replace(
        queryParameters: {'limit': limit.toString(), 'skip': skip.toString()},
      );

      final response = await http.get(uri, headers: headers);

      _handleError(response);
      final data = jsonDecode(response.body);
      return {
        'messages': List<Map<String, dynamic>>.from(data['data'] ?? []),
        'pagination': data['pagination'] ?? {},
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Send message
  Future<Map<String, dynamic>> sendMessage(
    String conversationId, {
    required String content,
    List<Map<String, dynamic>>? images,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.sendMessage(conversationId)),
        headers: headers,
        body: jsonEncode({
          'conversationId': conversationId,
          'content': content,
          'images': images ?? [],
        }),
      );

      _handleError(response);
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } catch (e) {
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.markAsRead(conversationId)),
        headers: headers,
      );

      _handleError(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteMessage(messageId)),
        headers: headers,
      );

      _handleError(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Mute conversation
  Future<void> muteConversation(String conversationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.muteConversation(conversationId)),
        headers: headers,
      );

      _handleError(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Unmute conversation
  Future<void> unmuteConversation(String conversationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.unmuteConversation(conversationId)),
        headers: headers,
      );

      _handleError(response);
    } catch (e) {
      rethrow;
    }
  }
}
