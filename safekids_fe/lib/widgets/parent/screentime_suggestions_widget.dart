import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'package:safekids_app/theme/app_typography.dart';

class ScreenTimeSuggestionsWidget extends StatelessWidget {
  final String childId;
  final Map<String, dynamic> suggestions;
  final Function() onApplySuggestion;

  ScreenTimeSuggestionsWidget({
    required this.childId,
    required this.suggestions,
    required this.onApplySuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 Gợi Ý Thông Minh',
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),

        // Suggested limit card
        if (suggestions['suggestedLimit'] != null)
          _buildSuggestionCard(
            context,
            icon: Icons.lightbulb_outline,
            color: Colors.blue,
            title: 'Giới Hạn Đề Xuất',
            message: _formatLimit(suggestions['suggestedLimit']),
            reasoning: suggestions['reasoning'],
            actionLabel: 'Áp Dụng',
            onAction: () =>
                _applySuggestedLimit(context, suggestions['suggestedLimit']),
          ),

        SizedBox(height: 12),

        // Adjustment recommendation
        if (suggestions['adjustmentRecommendation'] != null)
          _buildAdjustmentCard(
            context,
            suggestions['adjustmentRecommendation'],
          ),

        SizedBox(height: 12),

        // Age guideline
        if (suggestions['ageGuideline'] != null)
          _buildAgeGuidelineCard(context, suggestions['ageGuideline']),

        SizedBox(height: 12),

        // Bedtime suggestion
        if (suggestions['bedtimeSuggestion'] != null &&
            suggestions['bedtimeSuggestion']['enabled'] == false)
          _buildBedtimeSuggestionCard(
            context,
            suggestions['bedtimeSuggestion'],
          ),
      ],
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String reasoning,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 8),
            Text(
              reasoning,
              style: AppTypography.label.copyWith(color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel),
                style: ElevatedButton.styleFrom(backgroundColor: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentCard(
    BuildContext context,
    Map<String, dynamic> adjustment,
  ) {
    final type = adjustment['type'];
    final message = adjustment['message'];
    final newLimit = adjustment['newLimit'];

    Color color = type == 'increase' ? Colors.orange : Colors.green;
    IconData icon = type == 'increase'
        ? Icons.trending_up
        : Icons.trending_down;

    return _buildSuggestionCard(
      context,
      icon: icon,
      color: color,
      title: 'Điều Chỉnh Giới Hạn',
      message: _formatLimit(newLimit),
      reasoning: message,
      actionLabel: 'Điều Chỉnh',
      onAction: () => _applySuggestedLimit(context, newLimit),
    );
  }

  Widget _buildAgeGuidelineCard(
    BuildContext context,
    Map<String, dynamic> guideline,
  ) {
    final message = guideline['message'];

    return Card(
      elevation: 2,
      color: Colors.purple[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.child_care, color: Colors.purple, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hướng Dẫn Theo Độ Tuổi',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    message,
                    style: AppTypography.label.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBedtimeSuggestionCard(
    BuildContext context,
    Map<String, dynamic> bedtime,
  ) {
    final suggestedStart = bedtime['suggestedStart'];
    final suggestedEnd = bedtime['suggestedEnd'];
    final reasoning = bedtime['reasoning'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.nightlight_round, color: Colors.indigo, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chế Độ Giờ Ngủ',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              reasoning,
              style: AppTypography.label.copyWith(color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Đề xuất: $suggestedStart - $suggestedEnd',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => _applyBedtimeSuggestion(
                  context,
                  suggestedStart,
                  suggestedEnd,
                ),
                child: Text('Bật Giờ Ngủ'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLimit(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}p/ngày';
  }

  Future<void> _applySuggestedLimit(BuildContext context, int newLimit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Áp Dụng Gợi Ý'),
        content: Text('Áp dụng giới hạn ${_formatLimit(newLimit)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Áp Dụng'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final currentBedtimeEnabled =
            prefs.getBool('screentime_bedtime_enabled') ?? false;
        final currentBedtimeStart =
            prefs.getString('screentime_bedtime_start') ?? '21:00';
        final currentBedtimeEnd =
            prefs.getString('screentime_bedtime_end') ?? '07:00';

        await ApiService().saveScreenTimeConfig(
          childId: childId,
          dailyLimit: newLimit,
          bedtimeEnabled: currentBedtimeEnabled,
          bedtimeStart: currentBedtimeStart,
          bedtimeEnd: currentBedtimeEnd,
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('✅ Đã áp dụng giới hạn mới')));

        onApplySuggestion();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('⚠️ Lỗi: ${e.toString()}')));
      }
    }
  }

  Future<void> _applyBedtimeSuggestion(
    BuildContext context,
    String start,
    String end,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bật Giờ Ngủ'),
        content: Text('Bật chế độ giờ ngủ từ $start đến $end?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Bật'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final currentLimit = prefs.getInt('screentime_daily_limit') ?? 120;

        await ApiService().saveScreenTimeConfig(
          childId: childId,
          dailyLimit: currentLimit,
          bedtimeEnabled: true,
          bedtimeStart: start,
          bedtimeEnd: end,
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('✅ Đã bật chế độ giờ ngủ')));

        onApplySuggestion();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('⚠️ Lỗi: ${e.toString()}')));
      }
    }
  }
}
