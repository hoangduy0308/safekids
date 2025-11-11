import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';

class MessageWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isOwn;
  final VoidCallback? onDelete;
  final bool isRead;

  const MessageWidget({
    Key? key,
    required this.message,
    required this.isOwn,
    this.onDelete,
    this.isRead = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = message['content'] as String? ?? '';
    final images = (message['images'] as List?) ?? [];
    final timestamp = message['createdAt'] as String?;
    final isDeleted = message['isDeleted'] as bool? ?? false;

    return GestureDetector(
      onLongPress: isOwn ? () => _showOptions(context) : null,
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isOwn ? AppColors.childPrimary : Colors.grey[200],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(isOwn ? 16 : 0),
              bottomRight: Radius.circular(isOwn ? 0 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isOwn
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (isDeleted)
                Text(
                  '🗑️ Tin nhắn đã bị xóa',
                  style: AppTypography.caption.copyWith(
                    color: isOwn ? Colors.white70 : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                )
              else ...[
                if (content.isNotEmpty)
                  Text(
                    content,
                    style: AppTypography.body.copyWith(
                      color: isOwn ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                if (images.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.sm),
                  _buildImageGallery(images),
                ],
              ],
              SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(timestamp),
                    style: AppTypography.overline.copyWith(
                      fontSize: 11,
                      color: isOwn ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                  if (isOwn) ...[
                    SizedBox(width: 4),
                    Icon(
                      isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: isRead ? Colors.blue : Colors.white60,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<dynamic> images) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(images.length, (index) {
        final image = images[index] as Map<String, dynamic>;
        final imageUrl = image['url'] as String?;
        final caption = image['caption'] as String? ?? '';

        return GestureDetector(
          onTap: () => _showImageFullscreen(imageUrl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl ?? ''),
                    fit: BoxFit.cover,
                  ),
                ),
                child: imageUrl == null
                    ? Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      )
                    : null,
              ),
              if (caption.isNotEmpty)
                Container(
                  width: 100,
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.overline.copyWith(
                      fontSize: 9,
                      color: isOwn ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.copy, color: AppColors.childPrimary),
              title: Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement copy to clipboard
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: AppColors.danger),
              title: Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImageFullscreen(String? imageUrl) {
    // TODO: Implement fullscreen image viewer
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return 'now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';

      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}
