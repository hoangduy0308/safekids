import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class PendingLinkRequestsDialog extends StatefulWidget {
  final VoidCallback? onRequestsUpdated;

  const PendingLinkRequestsDialog({Key? key, this.onRequestsUpdated})
    : super(key: key);

  @override
  State<PendingLinkRequestsDialog> createState() =>
      _PendingLinkRequestsDialogState();
}

class _PendingLinkRequestsDialogState extends State<PendingLinkRequestsDialog> {
  late Future<List<dynamic>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    _requestsFuture = ApiService().getLinkRequests(status: 'pending');
  }

  Future<void> _handleRequest(Map<String, dynamic> request, bool accept) async {
    try {
      final requestId = request['_id'] ?? request['id'];
      if (accept) {
        await ApiService().acceptLinkRequest(requestId);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã chấp nhận yêu cầu'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await ApiService().rejectLinkRequest(requestId);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã từ chối yêu cầu'),
            backgroundColor: Colors.grey[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      widget.onRequestsUpdated?.call();
      _loadRequests();
      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.childPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    size: 24,
                    color: AppColors.childPrimary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yêu cầu liên kết',
                        style: AppTypography.h3.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Các yêu cầu từ phụ huynh',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Requests list
            FutureBuilder<List<dynamic>>(
              future: _requestsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(
                          AppColors.childPrimary,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      'Lỗi tải yêu cầu',
                      style: AppTypography.label.copyWith(
                        color: Colors.red[700],
                      ),
                    ),
                  );
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: AppColors.success.withOpacity(0.5),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Không có yêu cầu nào',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  height: 300,
                  child: SingleChildScrollView(
                    child: Column(
                      children: List.generate(requests.length, (index) {
                        final request = requests[index] as Map<String, dynamic>;
                        final sender =
                            request['sender'] as Map<String, dynamic>?;
                        final senderName = sender?['name'] ?? 'Unknown';
                        final senderEmail = sender?['email'] ?? '';

                        return Column(
                          children: [
                            if (index > 0) Divider(height: 16, thickness: 1),
                            _buildRequestItem(request, senderName, senderEmail),
                          ],
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestItem(
    Map<String, dynamic> request,
    String senderName,
    String senderEmail,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.childPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.childPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.childPrimary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderName,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      senderEmail,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleRequest(request, false),
                  icon: Icon(Icons.close, size: 16),
                  label: Text('Từ chối'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleRequest(request, true),
                  icon: Icon(Icons.check, size: 16),
                  label: Text('Chấp nhận'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: AppColors.childPrimary,
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
