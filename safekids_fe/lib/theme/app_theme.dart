import 'package:flutter/material.dart';

// Export design system components for easy imports
export 'app_colors.dart';
export 'app_typography.dart';
export 'app_spacing.dart';

// Import them here for use in theme
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// SafeKids Unified Theme System
/// "Misty Morning" / "Smart Guardian" Design
///
/// Usage:
/// ```dart
/// // Get theme for parent mode
/// ThemeData theme = AppTheme.getTheme(isParent: true);
///
/// // Get theme for child mode
/// ThemeData theme = AppTheme.getTheme(isParent: false);
/// ```
///
/// Updated: Oct 12, 2025 - Consolidated from 3 theme files into one

class AppTheme {
  /// Get the appropriate theme based on user role
  ///
  /// [isParent] - true for parent mode (purple), false for child mode (teal)
  static ThemeData getTheme({required bool isParent}) {
    final primaryColor = isParent
        ? AppColors.parentPrimary
        : AppColors.childPrimary;
    final primaryDark = isParent
        ? AppColors.parentPrimaryDark
        : AppColors.childPrimaryDark;
    final primaryLight = isParent
        ? AppColors.parentPrimaryLight
        : AppColors.childPrimaryLight;
    final bgColor = isParent
        ? AppColors.backgroundLight
        : AppColors.backgroundChildLight;

    // Child mode has more rounded corners for friendlier feel
    final cardRadius = isParent ? AppSpacing.radiusMd : AppSpacing.radiusLg;
    final buttonRadius = isParent ? AppSpacing.radiusMd : AppSpacing.radiusLg;
    final inputRadius = isParent ? AppSpacing.radiusMd : AppSpacing.radiusLg;

    return ThemeData(
      // ============================================================
      // COLOR SCHEME
      // ============================================================
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryDark,
        secondary: isParent ? AppColors.parentAccent : AppColors.childAccent,
        secondaryContainer: isParent
            ? AppColors.parentSecondary
            : AppColors.childAccent,
        surface: AppColors.surface,
        background: bgColor,
        error: AppColors.danger,
        onPrimary: AppColors.textWhite,
        onSecondary: AppColors.textWhite,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: AppColors.textWhite,
      ),

      // ============================================================
      // SCAFFOLD
      // ============================================================
      scaffoldBackgroundColor: bgColor,

      // ============================================================
      // APP BAR - Glassmorphism support
      // ============================================================
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.h3.copyWith(color: AppColors.textWhite),
        iconTheme: const IconThemeData(
          color: AppColors.textWhite,
          size: AppSpacing.iconMd,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.textWhite,
          size: AppSpacing.iconMd,
        ),
      ),

      // ============================================================
      // CARD - Clean modern cards
      // ============================================================
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: AppSpacing.elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.cardMargin,
        ),
      ),

      // ============================================================
      // BUTTONS
      // ============================================================

      // Elevated Button (Primary CTAs)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: AppColors.textWhite,
          elevation: AppSpacing.elevationMedium,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingH,
            vertical: AppSpacing.buttonPaddingV,
          ),
          minimumSize: const Size(0, AppSpacing.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // Outlined Button (Secondary actions)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingH,
            vertical: AppSpacing.buttonPaddingV,
          ),
          minimumSize: const Size(0, AppSpacing.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: AppTypography.button.copyWith(color: primaryColor),
        ),
      ),

      // Text Button (Tertiary actions)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingH,
            vertical: AppSpacing.buttonPaddingV,
          ),
          minimumSize: const Size(0, AppSpacing.buttonHeightMd),
          textStyle: AppTypography.button.copyWith(color: primaryColor),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isParent ? AppColors.parentAccent : AppColors.sosRed,
        foregroundColor: AppColors.textWhite,
        elevation: AppSpacing.elevationMedium,
      ),

      // ============================================================
      // INPUT DECORATION
      // ============================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(AppSpacing.inputPadding),

        // Border styles
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(
            color: AppColors.borderFocused,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.borderError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.borderError, width: 2),
        ),

        // Text styles
        labelStyle: AppTypography.label,
        hintStyle: AppTypography.caption.copyWith(
          color: AppColors.textDisabled,
        ),
        errorStyle: AppTypography.captionSmall.copyWith(
          color: AppColors.danger,
        ),

        // Icons
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),

      // ============================================================
      // BOTTOM NAVIGATION BAR
      // ============================================================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: AppSpacing.elevationHigh,
        selectedItemColor: primaryColor,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        unselectedLabelStyle: AppTypography.caption,
        selectedIconTheme: IconThemeData(
          size: isParent ? 24.0 : 28.0, // Larger icons for kids
          color: primaryColor,
        ),
        unselectedIconTheme: IconThemeData(
          size: isParent ? 24.0 : 28.0,
          color: AppColors.textSecondary,
        ),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // ============================================================
      // DIALOG
      // ============================================================
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: AppSpacing.elevationVeryHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isParent ? AppSpacing.radiusLg : AppSpacing.radiusXl,
          ),
        ),
        titleTextStyle: AppTypography.h3,
        contentTextStyle: AppTypography.body,
      ),

      // ============================================================
      // BOTTOM SHEET
      // ============================================================
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: AppSpacing.elevationHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              isParent ? AppSpacing.radiusLg : AppSpacing.radiusXl,
            ),
          ),
        ),
      ),

      // ============================================================
      // DIVIDER
      // ============================================================
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ============================================================
      // ICON THEME
      // ============================================================
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: AppSpacing.iconMd,
      ),

      // ============================================================
      // TEXT THEME - Using new Poppins Typography
      // ============================================================
      textTheme: TextTheme(
        displayLarge: AppTypography.display1,
        displayMedium: AppTypography.display2,
        displaySmall: AppTypography.h1,
        headlineMedium: AppTypography.h2,
        headlineSmall: AppTypography.h3,
        titleLarge: AppTypography.h4,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.button,
        labelMedium: AppTypography.label,
        labelSmall: AppTypography.caption,
      ),

      // ============================================================
      // FONT FAMILY - Poppins from Google Fonts
      // ============================================================
      fontFamily: AppTypography.fontFamily,

      // ============================================================
      // PROGRESS INDICATOR
      // ============================================================
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryColor),

      // ============================================================
      // CHIP
      // ============================================================
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: AppTypography.bodySmall,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),

      // ============================================================
      // LIST TILE
      // ============================================================
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.listItemPadding,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),

      // ============================================================
      // CHECKBOX & SWITCH
      // ============================================================
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return AppColors.border;
        }),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return AppColors.textDisabled;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryLight;
          }
          return AppColors.divider;
        }),
      ),

      // ============================================================
      // SNACKBAR
      // ============================================================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.textWhite,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Light theme for parent mode (purple primary)
  static ThemeData get parentTheme => getTheme(isParent: true);

  /// Light theme for child mode (teal primary)
  static ThemeData get childTheme => getTheme(isParent: false);
}
