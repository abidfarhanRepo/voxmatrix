import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Core entities for Matrix WebRTC calling

/// Represents the current state of a call
enum CallState {
  /// Call is being initiated
  initializing,
  /// Call was invited by remote party
  incoming,
  /// Call is outgoing (we initiated)
  outgoing,
  /// Call is connecting
  connecting,
  /// Call is active
  active,
  /// Call ended successfully
  ended,
  /// Call failed
  failed,
}

enum CallType {
  audio,
  video,
}

enum CallDirection {
  incoming,
  outgoing,
}

/// Simple TURN server configuration
class TurnServer {
  final String url;
  final String username;
  final String password;

  const TurnServer({
    required this.url,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'urls': url,
      'username': username,
      'credential': password,
    };
  }
}

/// Configuration for WebRTC calls
class CallConfig extends Equatable {
  const CallConfig({
    this.turnServers = const [
      TurnServer(
        url: 'turn:100.92.210.91:3478',
        username: 'turnuser',
        password: 'secure_turn_password_change_me',
      ),
    ],
    this.iceTransportPolicy = 'all',
    this.bundlePolicy = 'max-bundle',
    this.rtcpMuxPolicy = 'require',
    this.iceCandidatePoolSize = 10,
  });

  final List<TurnServer> turnServers;
  final String iceTransportPolicy;
  final String bundlePolicy;
  final String rtcpMuxPolicy;
  final int iceCandidatePoolSize;

  Map<String, dynamic> toMap() {
    return {
      'iceServers': turnServers.map((server) => server.toJson()).toList(),
      'sdpSemantics': 'unified-plan',
    };
  }

  @override
  List<Object?> get props => [
    turnServers,
    iceTransportPolicy,
    bundlePolicy,
    rtcpMuxPolicy,
    iceCandidatePoolSize,
  ];
}

/// Represents a Matrix call event
class MatrixCallEvent extends Equatable {
  const MatrixCallEvent({
    required this.type,
    required this.callId,
    required this.roomId,
    required this.senderId,
    this.timeout = 30000,
    this.sdpOffer,
    this.sdpAnswer,
    this.candidates,
    this.isVideoCall,
  });

  final MatrixCallEventType type;
  final String callId;
  final String roomId;
  final String senderId;
  final int timeout;
  final String? sdpOffer;
  final String? sdpAnswer;
  final List<Map<String, dynamic>>? candidates;
  final bool? isVideoCall;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'call_id': callId,
      'room_id': roomId,
      'sender': senderId,
      'timeout': timeout,
    };

    switch (type) {
      case MatrixCallEventType.invite:
        json['offer'] = {'sdp': sdpOffer, 'type': 'offer'};
        break;
      case MatrixCallEventType.answer:
        json['answer'] = {'sdp': sdpAnswer, 'type': 'answer'};
        break;
      case MatrixCallEventType.candidates:
        json['candidates'] = candidates;
        break;
      case MatrixCallEventType.hangup:
        json['reason'] = 'user_hangup';
        break;
    }

    return json;
  }

  @override
  List<Object?> get props => [type, callId, roomId, senderId, isVideoCall];
}

enum MatrixCallEventType {
  invite,
  answer,
  candidates,
  hangup,
}

/// Main call entity
class CallEntity extends Equatable {
  const CallEntity({
    required this.callId,
    required this.roomId,
    required this.callerId,
    required this.callerName,
    required this.isVideoCall,
    required this.state,
    this.callerAvatarUrl,
    this.calleeId,
    this.calleeName,
    this.calleeAvatarUrl,
    this.direction = CallDirection.outgoing,
    this.duration,
    this.config = const CallConfig(),
    this.isMuted = false,
    this.isSpeakerEnabled = false,
    this.isCameraEnabled = true,
    this.localStream,
    this.remoteStream,
  });

  final String callId;
  final String roomId;
  final String callerId;
  final String callerName;
  final String? callerAvatarUrl;
  final String? calleeId;
  final String? calleeName;
  final String? calleeAvatarUrl;
  final bool isVideoCall;
  final CallState state;
  final CallDirection direction;
  final Duration? duration;
  final CallConfig config;
  final bool isMuted;
  final bool isSpeakerEnabled;
  final bool isCameraEnabled;
  final MediaStream? localStream;
  final MediaStream? remoteStream;

  CallEntity copyWith({
    String? callId,
    String? roomId,
    String? callerId,
    String? callerName,
    String? callerAvatarUrl,
    String? calleeId,
    String? calleeName,
    String? calleeAvatarUrl,
    bool? isVideoCall,
    CallState? state,
    CallDirection? direction,
    Duration? duration,
    CallConfig? config,
    bool? isMuted,
    bool? isSpeakerEnabled,
    bool? isCameraEnabled,
    MediaStream? localStream,
    MediaStream? remoteStream,
  }) {
    return CallEntity(
      callId: callId ?? this.callId,
      roomId: roomId ?? this.roomId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerAvatarUrl: callerAvatarUrl ?? this.callerAvatarUrl,
      calleeId: calleeId ?? this.calleeId,
      calleeName: calleeName ?? this.calleeName,
      calleeAvatarUrl: calleeAvatarUrl ?? this.calleeAvatarUrl,
      isVideoCall: isVideoCall ?? this.isVideoCall,
      state: state ?? this.state,
      direction: direction ?? this.direction,
      duration: duration ?? this.duration,
      config: config ?? this.config,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerEnabled: isSpeakerEnabled ?? this.isSpeakerEnabled,
      isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
      localStream: localStream ?? this.localStream,
      remoteStream: remoteStream ?? this.remoteStream,
    );
  }

  @override
  List<Object?> get props => [
    callId,
    roomId,
    callerId,
    callerName,
    isVideoCall,
    state,
    direction,
    duration,
    isMuted,
    isSpeakerEnabled,
    isCameraEnabled,
    localStream,
    remoteStream,
  ];

  bool get isActive => state == CallState.active;
  bool get isEnded => state == CallState.ended;
  bool get isFailed => state == CallState.failed;
  bool get isIncoming => direction == CallDirection.incoming;
  bool get isOutgoing => direction == CallDirection.outgoing;
}

/// ICE candidate for WebRTC
class IceCandidate extends Equatable {
  const IceCandidate({
    required this.candidate,
    required this.sdpMid,
    required this.sdpMlineIndex,
  });

  final String candidate;
  final String sdpMid;
  final int sdpMlineIndex;

  Map<String, dynamic> toJson() {
    return {
      'candidate': candidate,
      'sdpMid': sdpMid,
      'sdpMLineIndex': sdpMlineIndex,
    };
  }

  factory IceCandidate.fromJson(Map<String, dynamic> json) {
    return IceCandidate(
      candidate: json['candidate'] as String,
      sdpMid: json['sdpMid'] as String,
      sdpMlineIndex: json['sdpMLineIndex'] as int,
    );
  }

  @override
  List<Object?> get props => [candidate, sdpMid, sdpMlineIndex];
}

/// Session description for WebRTC
class SessionDescription extends Equatable {
  const SessionDescription({
    required this.sdp,
    required this.type,
  });

  final String sdp;
  final SessionDescriptionType type;

  Map<String, dynamic> toJson() {
    return {
      'sdp': sdp,
      'type': type.name,
    };
  }

  factory SessionDescription.fromJson(Map<String, dynamic> json) {
    return SessionDescription(
      sdp: json['sdp'] as String,
      type: _parseSdpType(json['type'] as String? ?? 'offer'),
    );
  }

  static SessionDescriptionType _parseSdpType(String type) {
    switch (type.toLowerCase()) {
      case 'offer':
        return SessionDescriptionType.offer;
      case 'answer':
        return SessionDescriptionType.answer;
      case 'pranswer':
        return SessionDescriptionType.prAnswer;
      case 'rollback':
        return SessionDescriptionType.rollback;
      default:
        return SessionDescriptionType.offer;
    }
  }

  @override
  List<Object?> get props => [sdp, type];
}

enum SessionDescriptionType {
  offer,
  answer,
  prAnswer,
  rollback,
}
