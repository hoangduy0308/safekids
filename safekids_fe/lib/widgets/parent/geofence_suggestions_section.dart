import 'dart:ui'; // Needed for BackdropFilter
import 'package:flutter/material.dart';
import '../../models/geofence_suggestion.dart';
import '../../services/api_service.dart';
import 'geofence_suggestion_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';

class GeofenceSuggestionsSection extends StatefulWidget {
  final String childId;
  final Function(GeofenceSuggestion)? onCreateGeofence;

  const GeofenceSuggestionsSection({
    Key? key,
    required this.childId,
    this.onCreateGeofence,
  }) : super(key: key);

  @override
  State<GeofenceSuggestionsSection> createState() =>
      _GeofenceSuggestionsSectionState();
}

class _GeofenceSuggestionsSectionState
    extends State<GeofenceSuggestionsSection> {
  late Future<List<GeofenceSuggestion>> _suggestionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void didUpdateWidget(GeofenceSuggestionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId) {
      _loadSuggestions();
    }
  }

  void _loadSuggestions() {
    setState(() {
      _suggestionsFuture = _fetchSuggestions();
    });
  }

  Future<List<GeofenceSuggestion>> _fetchSuggestions() async {
    try {
      final apiService = ApiService();
      final data = await apiService.getGeofenceSuggestions(widget.childId);
      return data.map((json) => GeofenceSuggestion.fromJson(json)).toList();
    } catch (e) {
      // Don't show error in UI, just return empty list
      print('[GeofenceSuggestionsSection] Error loading suggestions: $e');
      return [];
    }
  }

  Future<void> _dismissSuggestion(GeofenceSuggestion suggestion) async {
    try {
      final apiService = ApiService();
      await apiService.dismissSuggestion(
        widget.childId,
        suggestion.center.latitude,
        suggestion.center.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã ẩn gợi ý')));
        _loadSuggestions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GeofenceSuggestion>>(
      future: _suggestionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final suggestions = snapshot.data ?? [];

        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        // New UI with glassmorphic container
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: AppColors.warning, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Gợi Ý Vùng Thông Minh', style: AppTypography.h3),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadSuggestions,
                        tooltip: 'Làm mới',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // List of suggestion cards
                  ...suggestions.map(
                    (suggestion) => GeofenceSuggestionCard(
                      suggestion: suggestion,
                      onCreateTap: () {
                        widget.onCreateGeofence?.call(suggestion);
                      },
                      onDismissTap: () => _dismissSuggestion(suggestion),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
