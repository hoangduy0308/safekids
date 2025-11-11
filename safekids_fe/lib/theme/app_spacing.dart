/// SafeKids App Spacing System
/// Consistent spacing values across the app
/// Base unit: 4dp
/// Updated: Oct 11, 2025
class AppSpacing {
  // ============================================================
  // CORE SPACING VALUES
  // 4dp base unit system
  // ============================================================

  /// Extra small spacing - 4dp
  /// Use for: tight spacing between related elements
  static const double xs = 4.0;

  /// Extra extra small spacing - 2dp
  /// Use for: minimal gaps, fine-tuning
  static const double xxs = 2.0;

  /// Small spacing - 8dp
  /// Use for: compact layouts, inline elements
  static const double sm = 8.0;

  /// Medium spacing - 16dp
  /// Use for: default spacing, card padding, list items
  static const double md = 16.0;

  /// Large spacing - 24dp
  /// Use for: section spacing, screen padding
  static const double lg = 24.0;

  /// Extra large spacing - 32dp
  /// Use for: major section breaks, prominent spacing
  static const double xl = 32.0;

  /// Double extra large - 48dp
  /// Use for: hero elements, large separations
  static const double xxl = 48.0;

  /// Triple extra large - 64dp
  /// Use for: major layout divisions
  static const double xxxl = 64.0;

  // ============================================================
  // COMPONENT-SPECIFIC SPACING
  // Predefined spacing for common components
  // ============================================================

  /// Default screen horizontal padding
  static const double screenPadding = md; // 16dp

  /// Card padding - internal content spacing
  static const double cardPadding = md; // 16dp

  /// Card margin - spacing between cards
  static const double cardMargin = sm; // 8dp

  /// List item padding
  static const double listItemPadding = md; // 16dp

  /// List item spacing - vertical gap between items
  static const double listItemSpacing = sm; // 8dp

  /// Section spacing - gap between major sections
  static const double sectionSpacing = lg; // 24dp

  /// Button padding - horizontal
  static const double buttonPaddingH = lg; // 24dp

  /// Button padding - vertical
  static const double buttonPaddingV = sm; // 12dp

  /// Input field padding
  static const double inputPadding = md; // 16dp

  /// Dialog padding
  static const double dialogPadding = lg; // 24dp

  /// Bottom sheet padding
  static const double bottomSheetPadding = md; // 16dp

  /// AppBar padding - horizontal
  static const double appBarPadding = md; // 16dp

  /// Bottom navigation padding
  static const double bottomNavPadding = sm; // 8dp

  // ============================================================
  // SPECIFIC COMPONENT SPACING
  // Based on wireframe specifications
  // ============================================================

  /// SOS button margin - vertical spacing
  static const double sosButtonMargin = xl; // 32dp

  /// Child card - spacing between sections
  static const double childCardSectionSpacing = sm; // 12dp

  /// Quick stats card spacing
  static const double quickStatsSpacing = xs; // 10dp (from wireframe)

  /// Quick action button spacing
  static const double quickActionSpacing = sm; // 8dp

  /// Progress ring padding
  static const double progressRingPadding = md; // 16dp

  /// Stat card spacing - between icon and text
  static const double statCardSpacing = xs; // 8dp

  /// Activity list item spacing
  static const double activityItemSpacing = sm; // 12dp

  /// Geofence badge spacing
  static const double geofenceBadgeSpacing = xs; // 4dp

  /// Map control spacing
  static const double mapControlSpacing = md; // 16dp

  // ============================================================
  // BORDER RADIUS
  // Consistent corner rounding
  // ============================================================

  /// Extra small radius - 4dp (subtle rounding)
  static const double radiusXs = 4.0;

  /// Small radius - buttons, chips
  static const double radiusSm = 8.0;

  /// Medium radius - cards, inputs (default)
  static const double radiusMd = 12.0;

  /// Large radius - bottom sheets, dialogs
  static const double radiusLg = 16.0;

  /// Extra large radius - prominent cards
  static const double radiusXl = 20.0;

  /// Circular - SOS button, avatars
  static const double radiusCircular = 999.0; // Effectively circular

  // ============================================================
  // ELEVATION (Shadow Depth)
  // Material Design elevation system
  // ============================================================

  /// No elevation
  static const double elevationNone = 0.0;

  /// Low elevation - cards at rest
  static const double elevationLow = 2.0;

  /// Medium elevation - raised buttons
  static const double elevationMedium = 4.0;

  /// High elevation - dialogs, bottom sheets
  static const double elevationHigh = 8.0;

  /// Very high elevation - modal overlays
  static const double elevationVeryHigh = 16.0;

  // ============================================================
  // ICON SIZES
  // Consistent icon sizing
  // ============================================================

  /// Small icon - inline with text
  static const double iconSm = 16.0;

  /// Medium icon - default
  static const double iconMd = 24.0;

  /// Large icon - prominent actions
  static const double iconLg = 32.0;

  /// Extra large icon - hero elements
  static const double iconXl = 48.0;

  /// SOS icon - emergency button
  static const double iconSos = 64.0;

  // ============================================================
  // AVATAR SIZES
  // ============================================================

  /// Small avatar - list items
  static const double avatarSm = 32.0;

  /// Medium avatar - default
  static const double avatarMd = 40.0;

  /// Large avatar - profile, headers
  static const double avatarLg = 48.0;

  /// Extra large avatar - profile details
  static const double avatarXl = 80.0;

  /// Huge avatar - onboarding, empty states
  static const double avatarHuge = 128.0;

  // ============================================================
  // COMPONENT HEIGHTS
  // ============================================================

  /// Small button height
  static const double buttonHeightSm = 40.0;

  /// Medium button height (default)
  static const double buttonHeightMd = 48.0;

  /// Large button height (primary CTAs)
  static const double buttonHeightLg = 56.0;

  /// Input field height
  static const double inputHeight = 56.0;

  /// AppBar height (default Flutter)
  static const double appBarHeight = 56.0;

  /// AppBar with gradient stats - from wireframe
  static const double appBarHeightExtended = 64.0;

  /// Bottom navigation height
  static const double bottomNavHeight = 56.0;

  /// SOS button size - from wireframe (120dp circle)
  static const double sosButtonSize = 120.0;

  /// Progress ring size - screen time
  static const double progressRingSize = 120.0;

  /// Progress ring stroke width
  static const double progressRingStroke = 12.0;

  /// Child card - collapsed height
  static const double childCardCollapsedHeight = 56.0;

  /// Map bottom sheet - default height
  static const double mapBottomSheetHeight = 180.0;

  /// Map bottom sheet - expanded max height
  static const double mapBottomSheetMaxHeight = 400.0;

  // ============================================================
  // ANIMATION DURATIONS
  // Consistent animation timing (in milliseconds)
  // ============================================================

  /// Fast - micro-interactions (ripple, scale)
  static const int durationFast = 150;

  /// Normal - default transitions
  static const int durationNormal = 300;

  /// Slow - complex animations, screen transitions
  static const int durationSlow = 500;

  /// SOS breathing animation - 2 seconds per cycle
  static const int durationSosBreathing = 2000;

  /// SOS countdown - 3 seconds hold time
  static const int durationSosCountdown = 3000;

  /// Screen time update interval - 1 minute
  static const int durationScreenTimeUpdate = 60000;

  /// Location update interval - 30 seconds
  static const int durationLocationUpdate = 30000;
}
