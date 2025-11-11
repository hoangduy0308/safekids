import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../theme/app_typography.dart';

class LinkRequestDialog extends StatefulWidget {
  final String requestId;
  final String senderName;
  final String senderEmail;
  final String senderRole;
  final String? message;

  const LinkRequestDialog({
    Key? key,
    required this.requestId,
    required this.senderName,
    required this.senderEmail,
    required this.senderRole,
    this.message,
  }) : super(key: key);

  @override
  State<LinkRequestDialog> createState() => _LinkRequestDialogState();
}

class _LinkRequestDialogState extends State<LinkRequestDialog> {
  bool _isProcessing = false;

  Future<void> _acceptRequest() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      await ApiService().acceptLinkRequest(widget.requestId);

      if (!mounted) return;

      // Close dialog first
      Navigator.pop(context, true);

      // Then show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã chấp nhận yêu cầu từ ${widget.senderName}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close dialog even on error
      Navigator.pop(context, false);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Không thể chấp nhận: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rejectRequest() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();

    try {
      await ApiService().rejectLinkRequest(widget.requestId);

      if (!mounted) return;

      // Close dialog first
      Navigator.pop(context, false);

      // Then show message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã từ chối yêu cầu'),
          backgroundColor: Colors.grey[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close dialog even on error
      Navigator.pop(context, false);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Không thể từ chối: ${e.toString()}'),
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
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.link, size: 40, color: Colors.blue[700]),
            ),
            SizedBox(height: 20),

            // Title
            Text(
              'Yêu cầu liên kết',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),

            // Sender info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey[700], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.senderName,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.grey[700], size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.senderEmail,
                          style: AppTypography.label.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (widget.message != null && widget.message!.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  widget.message!,
                  style: AppTypography.label.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            SizedBox(height: 24),

            // Buttons
            if (_isProcessing)
              CircularProgressIndicator()
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _rejectRequest,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                      child: Text(
                        'Từ chối',
                        style: AppTypography.button.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _acceptRequest,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.green,
                        elevation: 0,
                      ),
                      child: Text(
                        'Chấp nhận',
                        style: AppTypography.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
