import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';

class SocketService extends ChangeNotifier {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Event callbacks
  Function(Map<String, dynamic>)? onLinkRequest;
  Function(Map<String, dynamic>)? onLinkAccepted;
  Function(Map<String, dynamic>)? onLinkRejected;
  Function(Map<String, dynamic>)? onLinkRemoved;
  Function(Map<String, dynamic>)? onLocationUpdate;
  Function(Map<String, dynamic>)? onGeofenceAlert;
  Function(Map<String, dynamic>)? onSosAlert;
  Function(Map<String, dynamic>)? onScreentimeWarning;
  Function(Map<String, dynamic>)? onNewMessage;
  Function(Map<String, dynamic>)? onUserTyping;
  Function(Map<String, dynamic>)? onMessageRead;
  Function(Map<String, dynamic>)? onMessageDeleted;
  Function(Map<String, dynamic>)? onIncomingCall;
  Function(Map<String, dynamic>)? onCallAccepted;
  Function(Map<String, dynamic>)? onCallRejected;
  Function(Map<String, dynamic>)? onCallEnded;

  /// Connect to Socket.IO server
  void connect(String userId) {
    if (_socket != null && _isConnected) {
      debugPrint('[Socket] Already connected');
      return;
    }

    debugPrint('[Socket] Connecting to ${SocketConfig.serverUrl}...');

    _socket = IO.io(
      SocketConfig.serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(5)
          .setAuth({'userId': userId})
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('[Socket] Connected');

      // Register user
      _socket!.emit(SocketConfig.eventRegister, userId);
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('[Socket] Disconnected');
      notifyListeners();
    });

    _socket!.onConnectError((error) {
      debugPrint('[Socket] Connect error: $error');
    });

    _socket!.onError((error) {
      debugPrint('[Socket] Error: $error');
    });

    // Link request events
    _socket!.on(SocketConfig.eventLinkRequest, (data) {
      debugPrint('[Socket] Link request received: $data');
      if (onLinkRequest != null) {
        onLinkRequest!(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on(SocketConfig.eventLinkAccepted, (data) {
      debugPrint('[Socket] Link accepted: $data');
      if (onLinkAccepted != null) {
        onLinkAccepted!(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on(SocketConfig.eventLinkRejected, (data) {
      debugPrint('[Socket] Link rejected: $data');
      if (onLinkRejected != null) {
        onLinkRejected!(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on(SocketConfig.eventLinkRemoved, (data) {
      debugPrint('[Socket] Link removed: $data');
      if (onLinkRemoved != null) {
        onLinkRemoved!(Map<String, dynamic>.from(data));
      }
    });

    // Location events
    _socket!.on(SocketConfig.eventLocationUpdate, (data) {
      if (onLocationUpdate != null) {
        onLocationUpdate!(Map<String, dynamic>.from(data));
      }
    });

    // Geofence alert events (Story 3.2)
    _socket!.on(SocketConfig.eventGeofenceAlert, (data) {
      debugPrint('[Socket] Geofence alert received: $data');
      if (onGeofenceAlert != null) {
        onGeofenceAlert!(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on(SocketConfig.eventSosAlert, (data) {
      if (onSosAlert != null) {
        onSosAlert!(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on(SocketConfig.eventScreentimeWarning, (data) {
      if (onScreentimeWarning != null) {
        onScreentimeWarning!(Map<String, dynamic>.from(data));
      }
    });

    // Chat events
    _socket!.on(SocketConfig.eventNewMessage, (data) {
      debugPrint('[Socket] New message received: $data');
      if (onNewMessage != null) {
        onNewMessage!(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on(SocketConfig.eventUserTyping, (data) {
      if (onUserTyping != null) {
        onUserTyping!(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on(SocketConfig.eventMessageRead, (data) {
      if (onMessageRead != null) {
        onMessageRead!(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on(SocketConfig.eventMessageDeleted, (data) {
      if (onMessageDeleted != null) {
        onMessageDeleted!(Map<String, dynamic>.from(data));
      }
    });

    // Call events
    _socket!.on('incomingCall', (data) {
      debugPrint('[Socket] Incoming call: $data');
      if (onIncomingCall != null) {
        onIncomingCall!(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('callAccepted', (data) {
      debugPrint('[Socket] Call accepted');
      if (onCallAccepted != null) {
        onCallAccepted!(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('callRejected', (data) {
      debugPrint('[Socket] Call rejected');
      if (onCallRejected != null) {
        onCallRejected!(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('callEnded', (data) {
      debugPrint('[Socket] Call ended');
      if (onCallEnded != null) {
        onCallEnded!(Map<String, dynamic>.from(data));
      }
    });

    _socket!.connect();
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    if (_socket != null) {
      debugPrint('[Socket] Disconnecting...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Emit location update (legacy - for direct emit)
  void emitLocationUpdate(Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(SocketConfig.eventLocationUpdate, data);
    }
  }

  /// Emit SOS alert
  void emitSosAlert(Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(SocketConfig.eventSosAlert, data);
    }
  }

  /// Emit chat message
  void emitChatMessage(Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(SocketConfig.eventChatMessage, data);
    }
  }

  /// Emit typing indicator
  void emitUserTyping(Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(SocketConfig.eventUserTyping, data);
    }
  }

  /// Emit message read receipt
  void emitMessageRead(Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(SocketConfig.eventMessageRead, data);
    }
  }

  /// Emit message deleted
  void emitMessageDeleted(Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(SocketConfig.eventMessageDeleted, data);
    }
  }

  /// Emit incoming call
  void emitIncomingCall(Map<String, dynamic> data) {
    debugPrint('[SocketService] emitIncomingCall: $_isConnected, data: $data');
    if (_socket != null && _isConnected) {
      _socket!.emit('incomingCall', data);
      debugPrint('[SocketService] incomingCall emitted');
    } else {
      debugPrint('[SocketService] Socket not connected or null');
    }
  }

  /// Emit call accepted
  void emitCallAccepted(Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      _socket!.emit('callAccepted', data);
    }
  }

  /// Emit call rejected
  void emitCallRejected(Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      _socket!.emit('callRejected', data);
    }
  }

  /// Emit call ended
  void emitCallEnded(Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      _socket!.emit('callEnded', data);
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
