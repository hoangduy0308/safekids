import 'package:flutter/material.dart';

/// SafeKids Purple Modern Theme
class AppColors {
  // Purple Modern Primary Colors
  static const Color primaryPurple = Color(0xFF7C3AED); // Violet
  static const Color primaryDark = Color(0xFF6D28D9); // Deep Violet
  static const Color primaryLight = Color(0xFF8B5CF6); // Light Violet

  // Secondary & Accent Colors
  static const Color secondaryPink = Color(0xFFEC4899); // Pink
  static const Color accentGreen = Color(0xFF10B981); // Emerald Green
  static const Color gentleYellow = Color(0xFFFBBF24); // Soft Yellow

  // Modern Neutral Palette
  static const Color bgPrimary = Color(0xFFF9FAFB); // Light Gray
  static const Color bgSecondary = Color(0xFFFFFFFF); // White
  static const Color cardBackground = Color(0xFFFFFFFF); // Card White
  static const Color surface = Color(0xFFFFFFFF); // Surface
  static const Color background = bgPrimary; // Main background

  // Typography Colors
  static const Color textPrimary = Color(0xFF111827); // Gray 900
  static const Color textSecondary = Color(0xFF6B7280); // Gray 500
  static const Color textTertiary = Color(0xFF9CA3AF); // Gray 400
  static const Color placeholder = Color(0xFFD1D5DB); // Gray 300

  // Material 3 Semantic Colors
  static const Color primary = primaryPurple;
  static const Color secondary = secondaryPink;
  static const Color accent = accentGreen;

  // Status Colors - Modern Professional
  static const Color success = accentGreen;
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xFFEF4444); // Red
  static const Color info = primaryPurple;

  // Form & Interactive Colors
  static const Color borderLight = Color(0xFFE5E7EB); // Gray 200
  static const Color divider = Color(0xFFF3F4F6); // Gray 100
  static const Color inputBackground = Color(
    0xFFFFFFFF,
  ); // Pure White (stands out from bgPrimary)

  // Button States - Material 3
  static const Color buttonDisabled = Color(0xFFD1D1D6);
  static const Color buttonPressed = Color(0xFFE0E0E0);
  static const Color ripple = Color(0x42000000); // Material Ripple Color

  // Shadow & Elevation
  static const Color shadowLight = Color(0x21000000); // iOS Shadow Light
  static const Color shadowMedium = Color(0x42000000); // Material Shadow
  static const Color glass = Color(0x88FFFFFF); // iOS Glass Effect

  // Emergency & SOS
  static const Color sos = danger;
  static const Color sosPulse = Color(0xFFFF6961);

  // Status Indicators
  static const Color online = accentGreen;
  static const Color offline = Color(0xFF9CA3AF);
  static const Color busy = secondaryPink;
}

/// App Constants
class AppConstants {
  // User Roles
  static const String roleParent = 'parent';
  static const String roleChild = 'child';

  // Storage Keys
  static const String keyToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyUserData = 'user_data';

  // Map Settings
  static const double defaultLatitude = 10.8231; // Ho Chi Minh City
  static const double defaultLongitude = 106.6297;
  static const double defaultZoom = 15.0;
}
