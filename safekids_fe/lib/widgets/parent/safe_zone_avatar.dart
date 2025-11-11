import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';

/// Safe Zone Status for children
enum SafeZoneStatus {
  inSafeZone, // Green ring - child in designated safe zone
  outsideSafeZone, // Gray ring - child outside safe zones
  alert, // Coral/Red ring - child in restricted area
}

/// Instagram-style Avatar with Safe Zone Status Ring
/// Design: Circular avatar with color-coded ring indicator
class SafeZoneAvatar extends StatelessWidget {
  final String childId;
  final String childName;
  final String? avatarUrl;
  final SafeZoneStatus status;
  final String? locationName;
  final String? locationIcon;
  final VoidCallback? onTap;
  final double size;

  const SafeZoneAvatar({
    Key? key,
    required this.childId,
    required this.childName,
    this.avatarUrl,
    required this.status,
    this.locationName,
    this.locationIcon,
    this.onTap,
    this.size = 70.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with status ring
            _buildAvatarWithRing(),

            SizedBox(height: 6),

            // Child name
            Text(
              childName,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 2),

            // Location info
            if (locationIcon != null || locationName != null)
              _buildLocationInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWithRing() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated ring based on status
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _getRingColor(), width: 3),
            boxShadow: status == SafeZoneStatus.inSafeZone
                ? [
                    BoxShadow(
                      color: _getRingColor().withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),

        // Avatar image
        Container(
          width: size - 8,
          height: size - 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceVariant,
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderAvatar();
                    },
                  )
                : _buildPlaceholderAvatar(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: AppColors.parentPrimaryLight,
      child: Center(
        child: Text(
          childName.isNotEmpty ? childName[0].toUpperCase() : '?',
          style: AppTypography.h1.copyWith(
            fontSize: size / 2.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (locationIcon != null)
          Text(locationIcon!, style: AppTypography.overline),
        if (locationIcon != null && locationName != null) SizedBox(width: 2),
        if (locationName != null)
          Flexible(
            child: Text(
              locationName!,
              style: AppTypography.captionSmall.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Color _getRingColor() {
    switch (status) {
      case SafeZoneStatus.inSafeZone:
        return AppColors.success; // Sage green
      case SafeZoneStatus.outsideSafeZone:
        return AppColors.textTertiary; // Soft gray
      case SafeZoneStatus.alert:
        return AppColors.danger; // Muted coral/red
    }
  }
}

/// Add Child Button (Instagram-style)
class AddChildButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const AddChildButton({Key? key, required this.onTap, this.size = 70.0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceVariant,
                border: Border.all(
                  color: AppColors.border,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Icon(
                Icons.add,
                size: size / 2,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Add\nChild',
              style: AppTypography.captionSmall.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scrollable row of Safe Zone Avatars
class SafeZoneAvatarRow extends StatelessWidget {
  final List<ChildAvatarData> children;
  final Function(String childId)? onAvatarTap;
  final VoidCallback? onAddChildTap;

  const SafeZoneAvatarRow({
    Key? key,
    required this.children,
    this.onAvatarTap,
    this.onAddChildTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: children.length + (onAddChildTap != null ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          // Add Child button at the end
          if (index == children.length) {
            return AddChildButton(onTap: onAddChildTap!, size: 70);
          }

          // Child avatar
          final child = children[index];
          return SafeZoneAvatar(
            childId: child.id,
            childName: child.name,
            avatarUrl: child.avatarUrl,
            status: child.status,
            locationName: child.locationName,
            locationIcon: child.locationIcon,
            onTap: () => onAvatarTap?.call(child.id),
            size: 70,
          );
        },
      ),
    );
  }
}

/// Data model for child avatar
class ChildAvatarData {
  final String id;
  final String name;
  final String? avatarUrl;
  final SafeZoneStatus status;
  final String? locationName;
  final String? locationIcon;

  ChildAvatarData({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.status,
    this.locationName,
    this.locationIcon,
  });

  /// Get location icon based on location type
  static String getLocationIcon(String? locationType) {
    if (locationType == null) return '📍';
    switch (locationType.toLowerCase()) {
      case 'home':
        return '🏠';
      case 'school':
        return '🏫';
      case 'grandparents':
        return '👵';
      case 'sports':
      case 'gym':
        return '🏋️';
      case 'music':
        return '🎵';
      case 'medical':
      case 'doctor':
        return '🏥';
      default:
        return '📍';
    }
  }
}
