import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/domain/entities/call.dart';

@injectable
class WebRTCDataSource {
  WebRTCDataSource({
    required Logger logger,
  }) : _logger = logger;

  final Logger _logger;

  webrtc.RTCPeerConnection? _peerConnection;
  webrtc.MediaStream? _localStream;
  webrtc.MediaStream? _remoteStream;
  Timer? _connectionMonitor;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;

  final _iceCandidateController = StreamController<IceCandidate>.broadcast();
  final _remoteStreamController = StreamController<webrtc.MediaStream?>.broadcast();
  final _connectionStateController = StreamController<webrtc.RTCIceConnectionState>.broadcast();

  Stream<IceCandidate> get iceCandidates => _iceCandidateController.stream;
  Stream<webrtc.MediaStream?> get remoteStream => _remoteStreamController.stream;
  Stream<webrtc.RTCIceConnectionState> get connectionState => _connectionStateController.stream;

  webrtc.MediaStream? get localStream => _localStream;

  Future<void> initialize() async {
    _logger.i('WebRTC data source initialized');
  }

  Future<void> createPeerConnection(CallConfig config) async {
    _logger.i('Creating peer connection');

    // Enhanced configuration with TURN/STUN for better connectivity
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
        ...config.toMap()['iceServers'] as List<Map<String, dynamic>>? ?? [],
      ],
      'iceTransportPolicy': 'all', // Use all available transports
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
      'iceCandidatePoolSize': 10, // Pre-generate candidates
    };
    
    _peerConnection = await webrtc.createPeerConnection(configuration);
    _setupPeerConnectionHandlers();
    _startConnectionMonitoring();
    
    _logger.i('Peer connection created with enhanced config');
  }

  void _setupPeerConnectionHandlers() {
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
      _iceCandidateController.add(IceCandidate(
        candidate: candidate.candidate!,
        sdpMid: candidate.sdpMid ?? '',
        sdpMlineIndex: candidate.sdpMLineIndex ?? 0,
      ));
    };

    _peerConnection!.onIceConnectionState = (state) {
      _logger.d('ICE connection state: $state');
      _connectionStateController.add(state);
      _handleConnectionStateChange(state);
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        _remoteStreamController.add(_remoteStream);
      }
    };

    _peerConnection!.onAddStream = (stream) {
      _remoteStream = stream;
      _remoteStreamController.add(stream);
    };
  }

  void _handleConnectionStateChange(webrtc.RTCIceConnectionState state) {
    switch (state) {
      case webrtc.RTCIceConnectionState.RTCIceConnectionStateFailed:
        _logger.w('ICE connection failed, attempting restart');
        _attemptICERestart();
        break;
      case webrtc.RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        _logger.w('ICE connection disconnected');
        // Monitor for reconnection
        break;
      case webrtc.RTCIceConnectionState.RTCIceConnectionStateConnected:
        _logger.i('ICE connection established');
        _reconnectAttempts = 0; // Reset on successful connection
        break;
      default:
        break;
    }
  }

  void _startConnectionMonitoring() {
    _connectionMonitor?.cancel();
    _connectionMonitor = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkConnectionHealth();
    });
  }

  Future<void> _checkConnectionHealth() async {
    if (_peerConnection == null) return;

    try {
      final stats = await _peerConnection!.getStats();
      _logger.d('Connection stats retrieved: ${stats?.length ?? 0} items');
      // Could analyze stats here for quality monitoring
    } catch (e) {
      _logger.e('Failed to get connection stats', error: e);
    }
  }

  Future<void> _attemptICERestart() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.e('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    _logger.i('ICE restart attempt $_reconnectAttempts/$_maxReconnectAttempts');

    try {
      // Trigger ICE restart by creating new offer with iceRestart flag
      if (_peerConnection != null) {
        final constraints = {
          'offerToReceiveAudio': true,
          'offerToReceiveVideo': _localStream?.getVideoTracks().isNotEmpty ?? false,
          'iceRestart': true, // This triggers ICE restart
        };
        
        final offer = await _peerConnection!.createOffer(constraints);
        await _peerConnection!.setLocalDescription(offer);
        _logger.i('ICE restart initiated');
      }
    } catch (e) {
      _logger.e('ICE restart failed', error: e);
    }
  }

  Future<void> closePeerConnection() async {
    _logger.i('Closing peer connection');

    _connectionMonitor?.cancel();
    _connectionMonitor = null;
    
    await _peerConnection?.close();
    _peerConnection = null;

    await _localStream?.dispose();
    _localStream = null;

    _remoteStream = null;
    _remoteStreamController.add(null);
    
    _reconnectAttempts = 0;
  }

  Future<SessionDescription> createOffer({
    bool audio = true,
    bool video = false,
  }) async {
    if (_peerConnection == null) {
      throw WebRTCException(message: 'Peer connection not initialized');
    }

    final constraints = <String, dynamic>{
      'offerToReceiveAudio': audio,
      'offerToReceiveVideo': video,
    };

    final description = await _peerConnection!.createOffer(constraints);
    return SessionDescription(
      sdp: description.sdp ?? '',
      type: SessionDescriptionType.offer,
    );
  }

  Future<SessionDescription> createAnswer() async {
    if (_peerConnection == null) {
      throw WebRTCException(message: 'Peer connection not initialized');
    }

    final description = await _peerConnection!.createAnswer();
    return SessionDescription(
      sdp: description.sdp ?? '',
      type: SessionDescriptionType.answer,
    );
  }

  Future<void> setRemoteDescription(SessionDescription description) async {
    if (_peerConnection == null) {
      throw WebRTCException(message: 'Peer connection not initialized');
    }

    await _peerConnection!.setRemoteDescription(webrtc.RTCSessionDescription(
      description.sdp,
      description.type.name,
    ));
  }

  Future<void> setLocalDescription(SessionDescription description) async {
    if (_peerConnection == null) {
      throw WebRTCException(message: 'Peer connection not initialized');
    }

    await _peerConnection!.setLocalDescription(webrtc.RTCSessionDescription(
      description.sdp,
      description.type.name,
    ));
  }

  Future<void> addIceCandidate({required IceCandidate candidate}) async {
    if (_peerConnection == null) {
      throw WebRTCException(message: 'Peer connection not initialized');
    }

    await _peerConnection!.addCandidate(webrtc.RTCIceCandidate(
      candidate.candidate,
      candidate.sdpMid,
      candidate.sdpMlineIndex,
    ));
  }

  Future<void> getUserMedia({
    bool audio = true,
    bool video = false,
  }) async {
    _logger.i('Getting user media (audio: $audio, video: $video)');

    final constraints = <String, dynamic>{
      'audio': audio,
      'video': video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    };

    _localStream = await webrtc.navigator.mediaDevices.getUserMedia(constraints);

    if (_peerConnection != null && _localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }
  }

  Future<void> stopUserMedia() async {
    if (_localStream == null) return;
    for (final track in _localStream!.getTracks()) {
      await track.stop();
    }
    await _localStream!.dispose();
    _localStream = null;
  }

  Future<void> switchCamera() async {
    if (_localStream == null) {
      throw WebRTCException(message: 'No local stream available');
    }
    final track = _localStream!.getVideoTracks().first;
    await webrtc.Helper.switchCamera(track);
  }

  Future<void> toggleAudio({required bool enabled}) async {
    if (_localStream == null) {
      throw WebRTCException(message: 'No local stream available');
    }
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = enabled;
    }
  }

  Future<void> toggleVideo({required bool enabled}) async {
    if (_localStream == null) {
      throw WebRTCException(message: 'No local stream available');
    }
    for (final track in _localStream!.getVideoTracks()) {
      track.enabled = enabled;
    }
  }

  Future<void> dispose() async {
    _connectionMonitor?.cancel();
    await closePeerConnection();
    await _iceCandidateController.close();
    await _remoteStreamController.close();
    await _connectionStateController.close();
  }
}
