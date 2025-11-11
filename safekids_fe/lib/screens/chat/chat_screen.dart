import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/socket_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/chat/message_widget.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../widgets/chat/message_input_widget.dart';
import './audio_call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> otherUser;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.otherUser,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatService _chatService;
  late SocketService _socketService;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Set<String> _typingUsers = {};
  Map<String, bool> _readReceipts = {};
  bool _isInCall = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
    _socketService = SocketService();
    _loadMessages();
    _setupSocketListeners();
    _markAsRead();
  }

  void _setupSocketListeners() {
    _socketService.onNewMessage = (data) {
      final conversationId = data['conversationId'];
      if (conversationId == widget.conversationId) {
        _loadMessages();
      }
    };

    _socketService.onUserTyping = (data) {
      final conversationId = data['conversationId'];
      final senderId = data['senderId'];
      final currentUserId = context.read<AuthProvider>().user?.id;

      // Only show typing indicator for other user, not for self
      if (conversationId == widget.conversationId &&
          senderId != currentUserId) {
        setState(() {
          if (data['isTyping'] == true) {
            _typingUsers.add(senderId);
          } else {
            _typingUsers.remove(senderId);
          }
        });
      }
    };

    _socketService.onMessageRead = (data) {
      final conversationId = data['conversationId'];
      if (conversationId == widget.conversationId) {
        setState(() {
          _readReceipts[data['receiverId']] = true;
        });
      }
    };

    _socketService.onMessageDeleted = (data) {
      final conversationId = data['conversationId'];
      if (conversationId == widget.conversationId) {
        _loadMessages();
      }
    };

    // Call events
    _socketService.onIncomingCall = (data) {
      debugPrint('[Chat] Incoming call: $data');
      if (mounted) {
        _showIncomingCallDialog(data);
      }
    };

    _socketService.onCallAccepted = (data) {
      debugPrint('[Chat] Call accepted');
      if (mounted) {
        setState(() => _isInCall = true);

        // Setup callEnded handler BEFORE navigating
        _socketService.onCallEnded = (endData) {
          debugPrint('[ChatScreen] Call ended - closing AudioCallScreen');
          if (mounted) {
            Navigator.of(context).pop();
            setState(() => _isInCall = false);
          }
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioCallScreen(
              conversationId: widget.conversationId,
              otherUser: widget.otherUser,
              callerId: data['callerId'],
            ),
          ),
        );
      }
    };

    _socketService.onCallRejected = (data) {
      debugPrint('[Chat] Call rejected');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call rejected'), backgroundColor: Colors.red),
        );
      }
    };

    _socketService.onCallEnded = (data) {
      debugPrint('[Chat] Call ended');
      if (mounted) {
        setState(() => _isInCall = false);
      }
    };
  }

  Future<void> _loadMessages() async {
    try {
      final result = await _chatService.getMessages(widget.conversationId);
      final messages = result['messages'] as List<Map<String, dynamic>>;

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading messages: $e')));
      }
    }
  }

  Future<void> _markAsRead() async {
    try {
      await _chatService.markAsRead(widget.conversationId);
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        _socketService.emitMessageRead({
          'conversationId': widget.conversationId,
          'senderId': userId,
          'receiverId': widget.otherUser['_id'],
        });
      }
    } catch (e) {
      debugPrint('[Chat] Error marking as read: $e');
    }
  }

  Future<void> _sendMessage(
    String content,
    List<Map<String, dynamic>>? images,
  ) async {
    try {
      setState(() => _isSending = true);

      final message = await _chatService.sendMessage(
        widget.conversationId,
        content: content,
        images: images,
      );

      // Emit socket event
      _socketService.emitChatMessage({
        'conversationId': widget.conversationId,
        'receiverId': widget.otherUser['_id'],
        'message': message,
      });

      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _onTypingChanged(bool isTyping) {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      _socketService.emitUserTyping({
        'conversationId': widget.conversationId,
        'receiverId': widget.otherUser['_id'],
        'senderId': userId,
        'isTyping': isTyping,
      });
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        _socketService.emitMessageDeleted({
          'conversationId': widget.conversationId,
          'messageId': messageId,
          'senderId': userId,
          'receiverId': widget.otherUser['_id'],
        });
      }
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting message: $e')));
      }
    }
  }

  void _initiateCall() {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    debugPrint('[ChatScreen] Initiating call to ${widget.otherUser['_id']}');
    _socketService.emitIncomingCall({
      'callerId': userId.toString(),
      'receiverId': widget.otherUser['_id'].toString(),
      'conversationId': widget.conversationId,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${widget.otherUser['name']}...')),
    );
  }

  void _showIncomingCallDialog(Map<String, dynamic> callData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Incoming Call'),
        content: Text('${widget.otherUser['name']} is calling...'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final userId = context.read<AuthProvider>().user?.id;
              if (userId != null) {
                _socketService.emitCallRejected({
                  'callerId': callData['callerId'].toString(),
                  'receiverId': userId.toString(),
                  'conversationId': widget.conversationId,
                });
              }
            },
            child: Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final userId = context.read<AuthProvider>().user?.id;
              if (userId != null) {
                _socketService.emitCallAccepted({
                  'callerId': callData['callerId'].toString(),
                  'receiverId': userId.toString(),
                  'conversationId': widget.conversationId,
                });
                setState(() => _isInCall = true);

                // Setup callEnded handler BEFORE navigating
                _socketService.onCallEnded = (endData) {
                  debugPrint('[ChatScreen] Call ended by other party');
                  if (mounted) {
                    Navigator.of(context).pop();
                    setState(() => _isInCall = false);
                  }
                };

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AudioCallScreen(
                      conversationId: widget.conversationId,
                      otherUser: widget.otherUser,
                      callerId: callData['callerId'],
                    ),
                  ),
                );
              }
            },
            child: Text('Accept', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.otherUser['name'] ?? 'Chat',
              style: AppTypography.h3.copyWith(fontSize: 16),
            ),
            Text(
              'Online',
              style: AppTypography.caption.copyWith(color: Colors.green),
            ),
          ],
        ),
        actions: [
          if (!_isInCall)
            GestureDetector(
              onTap: _initiateCall,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.childPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.call, color: Colors.white, size: 22),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    itemCount:
                        _messages.length + (_typingUsers.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_typingUsers.isNotEmpty && index == 0) {
                        return TypingIndicator(
                          userName: widget.otherUser['name'] ?? 'User',
                          color: AppColors.childPrimary,
                        );
                      }

                      final messageIndex = _typingUsers.isNotEmpty
                          ? _messages.length - index
                          : _messages.length - 1 - index;
                      final message = _messages[messageIndex];
                      final isOwn = message['senderId']['_id'] == currentUserId;

                      return MessageWidget(
                        message: message,
                        isOwn: isOwn,
                        isRead: _readReceipts[currentUserId] ?? false,
                        onDelete: isOwn
                            ? () => _deleteMessage(message['_id'])
                            : null,
                      );
                    },
                  ),
          ),
          MessageInputWidget(
            onSend: _sendMessage,
            onTypingChanged: _onTypingChanged,
            isLoading: _isSending,
          ),
        ],
      ),
    );
  }
}
