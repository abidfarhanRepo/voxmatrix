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

    final configuration = config.toMap();
    _peerConnection = await webrtc.createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
      _iceCandidateController.add(IceCandidate(
        candidate: candidate.candidate!,
        sdpMid: candidate.sdpMid ?? '',
        sdpMlineIndex: candidate.sdpMLineIndex ?? 0,
      ));
    };

    _peerConnection!.onIceConnectionState = (state) {
      _connectionStateController.add(state);
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

    _logger.i('Peer connection created');
  }

  Future<void> closePeerConnection() async {
    _logger.i('Closing peer connection');

    await _peerConnection?.close();
    _peerConnection = null;

    await _localStream?.dispose();
    _localStream = null;

    _remoteStream = null;
    _remoteStreamController.add(null);
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
    await closePeerConnection();
    await _iceCandidateController.close();
    await _remoteStreamController.close();
    await _connectionStateController.close();
  }
}
