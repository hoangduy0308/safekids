import 'package:flutter/material.dart';

/// SafeKids App Color Palette - "Purple Guardian" Design System
/// Inspired by SafeZ - Modern, Clean, High Contrast
/// Updated: Oct 12, 2025
class AppColors {
  // ============================================================
  // PARENT MODE COLORS - "Purple Guardian"
  // Modern, Professional, Protective
  // ============================================================

  /// Primary purple - Modern, Protective, Premium
  static const Color parentPrimary = Color(0xFF8B5CF6);

  /// Darker purple for gradients and pressed states
  static const Color parentPrimaryDark = Color(0xFF7C3AED);

  /// Light purple for backgrounds and highlights
  static const Color parentPrimaryLight = Color(0xFFA78BFA);

  /// Red accent for alerts and important actions
  static const Color parentAccent = Color(0xFFEF4444);

  /// Secondary color for parent mode (coral for warnings)
  static const Color parentSecondary = Color(0xFFFF6B6B);

  // ============================================================
  // CHILD MODE COLORS
  // Friendly, Modern, Approachable, Playful
  // ============================================================

  /// Primary teal - Friendly, Modern, Approachable
  static const Color childPrimary = Color(0xFF14B8A6);

  /// Darker teal for gradients and pressed states
  static const Color childPrimaryDark = Color(0xFF0D9488);

  /// Light teal for backgrounds and highlights
  static const Color childPrimaryLight = Color(0xFF5EEAD4);

  /// Purple accent for gamification and rewards
  static const Color childAccent = Color(0xFF7C3AED);

  // ============================================================
  // SHARED SEMANTIC COLORS
  // Clean, high-contrast colors like SafeZ
  // ============================================================

  /// Success state - bright green for safe zones
  static const Color success = Color(0xFF22C55E);

  /// Light success background
  static const Color successLight = Color(0xFFDCFCE7);

  /// Danger/Error state - bright red for alerts
  static const Color danger = Color(0xFFEF4444);

  /// Warning state - coral/salmon for caution
  static const Color warning = Color(0xFFFF6B6B);

  /// Info state - blue for informational messages
  static const Color info = Color(0xFF3B82F6);

  // ============================================================
  // SOS EMERGENCY COLORS
  // High-contrast, attention-grabbing
  // ============================================================

  /// SOS button background - emergency red
  static const Color sosRed = Color(0xFFEF4444);

  /// SOS glow effect - 40% opacity red
  static const Color sosRedGlow = Color(0x66EF4444);

  /// SOS button pressed state
  static const Color sosRedDark = Color(0xFFDC2626);

  // ============================================================
  // SCREEN TIME COLORS
  // Traffic light system - bright and clear
  // ============================================================

  /// Under 80% usage - bright green
  static const Color screentimeGreen = Color(0xFF22C55E);

  /// 80-100% usage - bright yellow
  static const Color screentimeYellow = Color(0xFFFBBF24);

  /// Over 100% usage - bright red
  static const Color screentimeRed = Color(0xFFEF4444);

  // ============================================================
  // BACKGROUND COLORS - Soft off-white like SafeZ
  // ============================================================

  /// Light mode background - soft off-white
  static const Color backgroundLight = Color(0xFFF5F7FA);

  /// Light mode background - child app (light teal tint)
  static const Color backgroundChildLight = Color(0xFFF0FDFA);

  /// Dark mode background (future support)
  static const Color backgroundDark = Color(0xFF1F2937);

  /// Surface color - pure white for cards
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface variant - light gray for contrast
  static const Color surfaceVariant = Color(0xFFF8FAFC);

  // ============================================================
  // TEXT COLORS - High contrast like SafeZ
  // WCAG AA compliant
  // ============================================================

  /// Primary text - dark charcoal for high readability
  static const Color textPrimary = Color(0xFF2D3748);

  /// Secondary text - medium gray
  static const Color textSecondary = Color(0xFF718096);

  /// Tertiary/Light text - light gray
  static const Color textLight = Color(0xFFA0AEC0);

  /// Tertiary text - alias for textLight (backward compatibility)
  static const Color textTertiary = Color(0xFFA0AEC0);

  /// Disabled text - very light gray
  static const Color textDisabled = Color(0xFFCBD5E0);

  /// White text - on dark backgrounds
  static const Color textWhite = Color(0xFFFFFFFF);

  /// Text on primary color backgrounds
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ============================================================
  // BORDER & DIVIDER COLORS
  // ============================================================

  /// Default border color
  static const Color border = Color(0xFFE5E7EB);

  /// Divider lines
  static const Color divider = Color(0xFFE5E7EB);

  /// Focused border (input fields)
  static const Color borderFocused = Color(0xFF2196F3);

  /// Error border
  static const Color borderError = Color(0xFFEF4444);

  /// Border light - for input fields
  static const Color borderLight = Color(0xFFE5E7EB);

  // ============================================================
  // INPUT & FORM COLORS
  // ============================================================

  /// Input background - light gray for form fields
  static const Color inputBackground = Color(0xFFF9FAFB);

  /// Button disabled - gray for disabled buttons
  static const Color buttonDisabled = Color(0xFFD1D5DB);

  // ============================================================
  // SHADOW COLORS
  // ============================================================

  /// Shadow base color - for custom shadows
  static const Color shadowColor = Color(0xFF000000);

  // ============================================================
  // GEOFENCE COLORS
  // ============================================================

  /// Safe zone - green
  static const Color geofenceSafe = Color(0xFF10B981);

  /// Danger zone - red
  static const Color geofenceDanger = Color(0xFFEF4444);

  /// Alert zone - orange
  static const Color geofenceAlert = Color(0xFFFF6F00);

  // ============================================================
  // BATTERY LEVEL COLORS
  // Bright, clear indicators
  // ============================================================

  /// Battery >50% - bright green
  static const Color batteryGreen = Color(0xFF22C55E);

  /// Battery 21-50% - bright yellow
  static const Color batteryYellow = Color(0xFFFBBF24);

  /// Battery ≤20% - bright red
  static const Color batteryRed = Color(0xFFEF4444);

  // ============================================================
  // OVERLAY COLORS
  // Semi-transparent overlays
  // ============================================================

  /// Dark overlay for modals and dialogs
  static const Color overlayDark = Color(0x80000000); // 50% black

  /// Light overlay for loading states
  static const Color overlayLight = Color(0x40FFFFFF); // 25% white

  // ============================================================
  // GRADIENT DEFINITIONS
  // For AppBar, Cards, Buttons
  // ============================================================

  /// Parent AppBar gradient
  static const LinearGradient parentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [parentPrimary, parentPrimaryDark],
  );

  /// Child AppBar gradient
  static const LinearGradient childGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [childPrimary, childPrimaryDark],
  );

  /// SOS button gradient
  static const LinearGradient sosGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sosRed, sosRedDark],
  );

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Get primary color based on user role
  static Color getPrimaryColor(bool isParent) {
    return isParent ? parentPrimary : childPrimary;
  }

  /// Get primary dark color based on user role
  static Color getPrimaryDarkColor(bool isParent) {
    return isParent ? parentPrimaryDark : childPrimaryDark;
  }

  /// Get background color based on user role
  static Color getBackgroundColor(bool isParent) {
    return isParent ? backgroundLight : backgroundChildLight;
  }

  /// Get gradient based on user role
  static LinearGradient getPrimaryGradient(bool isParent) {
    return isParent ? parentGradient : childGradient;
  }

  /// Get screen time color based on percentage
  /// <80%: bright green, 80-100%: yellow, >100%: red
  static Color getScreenTimeColor(double percentage) {
    if (percentage < 0.8) {
      return screentimeGreen;
    } else if (percentage <= 1.0) {
      return screentimeYellow;
    } else {
      return screentimeRed;
    }
  }

  /// Get battery color based on percentage
  /// >50%: bright green, 21-50%: yellow, ≤20%: red
  static Color getBatteryColor(int percentage) {
    if (percentage > 50) {
      return batteryGreen;
    } else if (percentage > 20) {
      return batteryYellow;
    } else {
      return batteryRed;
    }
  }

  /// Get geofence color based on type
  static Color getGeofenceColor(String type) {
    switch (type.toLowerCase()) {
      case 'safe':
        return geofenceSafe;
      case 'danger':
        return geofenceDanger;
      case 'alert':
        return geofenceAlert;
      default:
        return info;
    }
  }
}
