import 'environment.dart';

/// API Configuration
class ApiConfig {
  // Sử dụng environment config thay vì hardcode
  static String get baseUrl => EnvironmentConfig.apiUrl;

  // Auth Endpoints
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get getMe => '$baseUrl/auth/me';
  static String get getProfile => '$baseUrl/auth/me';
  static String get updateProfile => '$baseUrl/auth/profile';
  static String get linkAccounts => '$baseUrl/auth/link';
  static String get updateFCMToken => '$baseUrl/auth/update-fcm-token';

  // Link Request Endpoints
  static String get linkRequest => '$baseUrl/link/request';
  static String get linkRequests => '$baseUrl/link/requests';
  static String get getMyChildren => '$baseUrl/parent/children';
  static String linkAccept(String requestId) =>
      '$baseUrl/link/accept/$requestId';
  static String linkReject(String requestId) =>
      '$baseUrl/link/reject/$requestId';
  static String linkRemove(String childId) => '$baseUrl/link/remove/$childId';

  // Location Endpoints
  static String get locations => '$baseUrl/location';
  static String get sendLocation => '$baseUrl/location';

  // Geofence Endpoints
  static String get geofences => '$baseUrl/geofence';
  static String get geofenceBulkDelete => '$baseUrl/geofence/bulk-delete';
  static String get geofenceBulkUpdate => '$baseUrl/geofence/bulk-update';

  // SOS Endpoints
  static String get sos => '$baseUrl/sos';

  // Screen Time Endpoints
  static String get screentime => '$baseUrl/screentime';
  static String get screentimeConfig => '$baseUrl/screentime/config';
  static String get screentimeUsage => '$baseUrl/screentime/usage';
  static String get screentimeSuggestions => '$baseUrl/screentime/suggestions';

  // Chat Endpoints
  static String get chat => '$baseUrl/chat';
  static String get conversations => '$baseUrl/chat/conversations';
  static String getOrCreateConversation(String participantId) =>
      '$baseUrl/chat/conversations/$participantId';
  static String getConversation(String conversationId) =>
      '$baseUrl/chat/conversations/$conversationId';
  static String getMessages(String conversationId) =>
      '$baseUrl/chat/conversations/$conversationId/messages';
  static String sendMessage(String conversationId) =>
      '$baseUrl/chat/conversations/$conversationId/messages';
  static String markAsRead(String conversationId) =>
      '$baseUrl/chat/conversations/$conversationId/mark-read';
  static String deleteMessage(String messageId) =>
      '$baseUrl/chat/messages/$messageId';
  static String muteConversation(String conversationId) =>
      '$baseUrl/chat/conversations/$conversationId/mute';
  static String unmuteConversation(String conversationId) =>
      '$baseUrl/chat/conversations/$conversationId/unmute';
}

/// Socket.IO Configuration
class SocketConfig {
  // Sử dụng environment config
  static String get serverUrl => EnvironmentConfig.socketUrl;

  // Events
  static const String eventRegister = 'register';
  static const String eventLocationUpdate = 'locationUpdate';
  static const String eventGeofenceAlert = 'geofenceAlert';
  static const String eventSosAlert = 'sosAlert';
  static const String eventScreentimeWarning = 'screentimeWarning';
  static const String eventLinkRequest = 'linkRequest';
  static const String eventLinkAccepted = 'linkAccepted';
  static const String eventLinkRejected = 'linkRejected';
  static const String eventLinkRemoved = 'linkRemoved';

  // Chat Events
  static const String eventChatMessage = 'chatMessage';
  static const String eventNewMessage = 'newMessage';
  static const String eventUserTyping = 'userTyping';
  static const String eventMessageRead = 'messageRead';
  static const String eventMessageDeleted = 'messageDeleted';
}

/// App Configuration
class AppConfig {
  static const String appName = 'SafeKids';
  static const String appVersion = '1.0.0';

  // Location Settings
  static const int locationUpdateIntervalSeconds = 30;
  static const double defaultGeofenceRadius = 100.0; // meters

  // Screen Time Settings
  static const int screentimeCheckIntervalSeconds = 60;
}
