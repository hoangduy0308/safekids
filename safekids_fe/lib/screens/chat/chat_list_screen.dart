import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late ChatService _chatService;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      setState(() => _isLoading = true);
      final conversations = await _chatService.getConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversations: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Messages',
          style: AppTypography.h2.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: GestureDetector(
              onTap: () => _showNewChatDialog(context),
              child: Icon(
                Icons.add_comment,
                color: AppColors.childPrimary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _conversations.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      'No conversations yet',
                      style: AppTypography.h3.copyWith(color: Colors.grey[600]),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Tap + to start a new chat',
                      style: AppTypography.caption.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  final otherUser = conversation['otherUser'];
                  final lastMessage =
                      conversation['lastMessageText'] as String?;
                  final unreadCount = conversation['unreadCount'] ?? {};
                  final isParent = otherUser?['role'] == 'child' ? true : false;
                  int unread = 0;
                  if (isParent) {
                    unread = unreadCount['parent'] ?? 0;
                  } else {
                    unread = unreadCount['child'] ?? 0;
                  }

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          conversationId: conversation['_id'],
                          otherUser: otherUser,
                        ),
                      ),
                    ).then((_) => _loadConversations()),
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.childPrimary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                otherUser['name']?[0].toUpperCase() ?? 'U',
                                style: AppTypography.h2.copyWith(
                                  color: AppColors.childPrimary,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      otherUser['name'] ?? 'Unknown',
                                      style: AppTypography.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(
                                        conversation['lastMessageTime'],
                                      ),
                                      style: AppTypography.caption.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        lastMessage ?? 'No messages yet',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.caption.copyWith(
                                          color: unread > 0
                                              ? Colors.grey[900]
                                              : Colors.grey[600],
                                          fontWeight: unread > 0
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (unread > 0)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.childPrimary,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          unread.toString(),
                                          style: AppTypography.overline
                                              .copyWith(
                                                color: Colors.white,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final linkedUsers = authProvider.user?.linkedUsersData ?? [];

    if (linkedUsers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No linked contacts available')));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start a new chat',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.builder(
                itemCount: linkedUsers.length,
                itemBuilder: (context, index) {
                  final user = linkedUsers[index];
                  final userId = user['_id'] ?? user['id'];
                  final userName = user['name'] ?? 'Unknown';
                  final userRole = user['role'] ?? 'unknown';

                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await _startChat(userId, userName);
                    },
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.childPrimary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                userName[0].toUpperCase(),
                                style: AppTypography.h2.copyWith(
                                  color: AppColors.childPrimary,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  userRole,
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startChat(String participantId, String participantName) async {
    try {
      final conversation = await _chatService.getOrCreateConversation(
        participantId,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation['_id'],
              otherUser: {'_id': participantId, 'name': participantName},
            ),
          ),
        ).then((_) => _loadConversations());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting chat: $e')));
      }
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return 'now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m';
      if (difference.inHours < 24) return '${difference.inHours}h';

      return '${dateTime.day}/${dateTime.month}';
    } catch (e) {
      return '';
    }
  }
}
