import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

class AgoraAudioService extends ChangeNotifier {
  static const String agoraAppId = 'c1f5593f44cc4e1092509377b1fdaa25';

  late RtcEngine _engine;
  bool _isInitialized = false;
  bool _isInCall = false;
  int? _remoteUserUid;

  bool get isInCall => _isInCall;
  bool get isInitialized => _isInitialized;
  int? get remoteUserUid => _remoteUserUid;

  Future<void> initialize() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(const RtcEngineContext(appId: agoraAppId));

      // Audio-only mode
      await _engine.enableAudio();
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Register event handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onUserJoined: (connection, remoteUid, elapsed) {
            debugPrint('[Agora] User $remoteUid joined');
            _remoteUserUid = remoteUid;
            notifyListeners();
          },
          onUserOffline: (connection, remoteUid, reason) {
            debugPrint('[Agora] User $remoteUid left');
            _remoteUserUid = null;
            notifyListeners();
          },
          onError: (err, msg) {
            debugPrint('[Agora] Error: $err - $msg');
          },
        ),
      );

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[Agora] Initialization error: $e');
      rethrow;
    }
  }

  Future<void> joinCall({
    required String channelName,
    required int uid,
    String? token,
  }) async {
    try {
      await _engine.joinChannel(
        token: token ?? '',
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(),
      );

      _isInCall = true;
      notifyListeners();
      debugPrint('[Agora] Joined channel: $channelName');
    } catch (e) {
      debugPrint('[Agora] Join error: $e');
      rethrow;
    }
  }

  Future<void> leaveCall() async {
    try {
      await _engine.leaveChannel();
      _isInCall = false;
      _remoteUserUid = null;
      notifyListeners();
      debugPrint('[Agora] Left channel');
    } catch (e) {
      debugPrint('[Agora] Leave error: $e');
      rethrow;
    }
  }

  Future<void> muteAudio() async {
    try {
      await _engine.muteLocalAudioStream(true);
    } catch (e) {
      debugPrint('[Agora] Mute error: $e');
    }
  }

  Future<void> unmuteAudio() async {
    try {
      await _engine.muteLocalAudioStream(false);
    } catch (e) {
      debugPrint('[Agora] Unmute error: $e');
    }
  }

  Future<void> switchSpeaker(bool useSpeaker) async {
    try {
      await _engine.setDefaultAudioRouteToSpeakerphone(useSpeaker);
    } catch (e) {
      debugPrint('[Agora] Speaker switch error: $e');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      if (_isInCall) {
        await leaveCall();
      }
      await _engine.release();
      _isInitialized = false;
    } catch (e) {
      debugPrint('[Agora] Dispose error: $e');
    } finally {
      super.dispose();
    }
  }
}
