import 'package:flutter/material.dart';
import '../../models/geofence_suggestion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class GeofenceSuggestionCard extends StatelessWidget {
  final GeofenceSuggestion suggestion;
  final VoidCallback onCreateTap;
  final VoidCallback onDismissTap;

  const GeofenceSuggestionCard({
    Key? key,
    required this.suggestion,
    required this.onCreateTap,
    required this.onDismissTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon, Name, Dismiss button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.warning,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    suggestion.name,
                    style: AppTypography.h3.copyWith(color: AppColors.warning),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onDismissTap,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Details: Location and Visit Count
          _buildDetailRow(
            icon: Icons.location_on_outlined,
            text:
                '${suggestion.center.latitude.toStringAsFixed(4)}, ${suggestion.center.longitude.toStringAsFixed(4)}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildDetailRow(
            icon: Icons.history,
            text: 'Đã đến đây ${suggestion.visitCount} lần',
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action Button: Create Geofence
          GestureDetector(
            onTap: onCreateTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.parentPrimary,
                    AppColors.parentPrimaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.parentPrimary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_location_alt_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Tạo Vùng An Toàn',
                    style: AppTypography.label.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
