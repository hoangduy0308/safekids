import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/auth_provider.dart';
import '../../services/socket_service.dart';
import '../../services/agora_audio_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';

class AudioCallScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> otherUser;
  final String? callerId;

  const AudioCallScreen({
    Key? key,
    required this.conversationId,
    required this.otherUser,
    this.callerId,
  }) : super(key: key);

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  late SocketService _socketService;
  late AgoraAudioService _agoraService;
  bool _isMuted = false;
  bool _useSpeaker = true;
  int _callDuration = 0;
  late DateTime _callStartTime;

  @override
  void initState() {
    super.initState();
    _socketService = SocketService();
    _agoraService = AgoraAudioService();
    _callStartTime = DateTime.now();
    _startCallTimer();

    // Initialize Agora and join call
    _initializeAgoraAndJoinCall();
  }

  Future<void> _initializeAgoraAndJoinCall() async {
    try {
      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      debugPrint('[AudioCallScreen] Microphone permission: $micStatus');

      if (!micStatus.isGranted) {
        throw Exception('Microphone permission denied');
      }

      // Initialize Agora
      await _agoraService.initialize();
      debugPrint('[AudioCallScreen] Agora initialized');

      // Join channel using conversationId as channel name
      final userId = context.read<AuthProvider>().user?.id ?? 'unknown';
      await _agoraService.joinCall(
        channelName: widget.conversationId,
        uid:
            userId.hashCode.abs() %
            2147483647, // Convert string ID to positive int
      );
      debugPrint(
        '[AudioCallScreen] Joined Agora channel: ${widget.conversationId}',
      );
    } catch (e) {
      debugPrint('[AudioCallScreen] Agora initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize audio: $e')),
        );
      }
    }
  }

  void _startCallTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _callDuration = DateTime.now().difference(_callStartTime).inSeconds;
        });
        _startCallTimer();
      }
    });
  }

  Future<void> _endCall() async {
    try {
      // Leave Agora channel
      await _agoraService.leaveCall();
    } catch (e) {
      debugPrint('[AudioCallScreen] Leave call error: $e');
    }

    // Notify other party
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      _socketService.emitCallEnded({
        'senderId': userId.toString(),
        'receiverId': widget.otherUser['_id'].toString(),
        'conversationId': widget.conversationId,
      });
    }

    if (mounted) Navigator.pop(context);
  }

  String _formatCallDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Caller/Receiver Name
                    Text(
                      widget.otherUser['name'] ?? 'User',
                      style: AppTypography.h2.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),

                    // Avatar
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.childPrimary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (widget.otherUser['name'] ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: AppColors.childPrimary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),

                    // Call Duration
                    Text(
                      _formatCallDuration(_callDuration),
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Control Buttons
              Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Button
                    GestureDetector(
                      onTap: () async {
                        setState(() => _isMuted = !_isMuted);
                        if (_isMuted) {
                          await _agoraService.muteAudio();
                        } else {
                          await _agoraService.unmuteAudio();
                        }
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _isMuted ? Colors.red : Colors.grey[800],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),

                    // Speaker Button
                    GestureDetector(
                      onTap: () async {
                        setState(() => _useSpeaker = !_useSpeaker);
                        await _agoraService.switchSpeaker(_useSpeaker);
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _useSpeaker ? Colors.blue : Colors.grey[800],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _useSpeaker ? Icons.volume_up : Icons.volume_off,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),

                    // End Call Button
                    GestureDetector(
                      onTap: _endCall,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Leave call and cleanup Agora (fire and forget)
    Future.microtask(() async {
      try {
        if (_agoraService.isInCall) {
          await _agoraService.leaveCall();
        }
        await _agoraService.dispose();
      } catch (e) {
        debugPrint('[AudioCallScreen] Dispose error: $e');
      }
    });
    super.dispose();
  }
}
