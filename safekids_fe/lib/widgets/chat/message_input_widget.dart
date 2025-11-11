import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class MessageInputWidget extends StatefulWidget {
  final Function(String content, List<Map<String, dynamic>>? images) onSend;
  final Function(bool isTyping) onTypingChanged;
  final bool isLoading;

  const MessageInputWidget({
    Key? key,
    required this.onSend,
    required this.onTypingChanged,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  late TextEditingController _textController;
  List<Map<String, dynamic>> _selectedImages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.isNotEmpty;
    if (hasText != _isTyping) {
      setState(() => _isTyping = hasText);
      widget.onTypingChanged(_isTyping);
    }
  }

  void _sendMessage() {
    final content = _textController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) return;

    widget.onSend(content, _selectedImages.isNotEmpty ? _selectedImages : null);
    _textController.clear();
    _selectedImages.clear();
    setState(() => _isTyping = false);
  }

  void _pickImage() {
    // TODO: Implement image picker
    // For now, this is a placeholder
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Image picker coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImages.isNotEmpty) _buildImagePreview(),
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.childPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.image,
                      color: AppColors.childPrimary,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: widget.isLoading ? null : _sendMessage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.isLoading
                          ? Colors.grey[300]
                          : AppColors.childPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: widget.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Images (${_selectedImages.length})',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          // TODO: Show image preview
                          child: Icon(Icons.image),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
