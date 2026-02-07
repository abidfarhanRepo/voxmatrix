import 'dart:async';
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/data/datasources/matrix_call_signaling_datasource.dart';
import 'package:voxmatrix/data/datasources/room_members_datasource.dart';
import 'package:voxmatrix/data/datasources/webrtc_datasource.dart';
import 'package:voxmatrix/domain/entities/call.dart';
import 'package:voxmatrix/domain/repositories/call_repository.dart';

/// Call Repository Implementation using Matrix + WebRTC (flutter_webrtc)
///
/// This implementation provides:
/// - 1:1 voice/video calls with Matrix signaling
/// - Standard m.call.* events for SDP/ICE
/// - Media controls (mute, video toggle, etc.)
@LazySingleton(as: CallRepository)
class CallRepositoryImpl implements CallRepository {
  CallRepositoryImpl(
    this._webrtcDataSource,
    this._signalingDataSource,
    this._roomMembersDataSource,
    this._authLocalDataSource,
    this._logger,
  ) {
    _init();
  }

  final WebRTCDataSource _webrtcDataSource;
  final MatrixCallSignalingDataSource _signalingDataSource;
  final RoomMembersDataSource _roomMembersDataSource;
  final AuthLocalDataSource _authLocalDataSource;
  final Logger _logger;

  CallEntity? _activeCall;
  String? _currentUserId;
  String? _currentUserName;
  
  final _callStateController = StreamController<CallEntity?>.broadcast();
  final _incomingCallController = StreamController<CallEntity>.broadcast();

  bool _isInitialized = false;

  /// Initialize the repository
  Future<void> _init() async {
    try {
      await _webrtcDataSource.initialize();
      await _signalingDataSource.initialize();
      
      // Get current user info
      _currentUserId = await _authLocalDataSource.getUserId();
      _currentUserName = await _authLocalDataSource.getUserId(); // TODO: Get display name
      
      // Listen to incoming calls
      _signalingDataSource.incomingCalls.listen(_handleIncomingCall);
      _signalingDataSource.callAnswers.listen(_handleCallAnswer);
      _signalingDataSource.callHangups.listen(_handleCallHangup);
      _signalingDataSource.iceCandidates.listen(_handleIceCandidates);

      _webrtcDataSource.remoteStream.listen((stream) {
        if (_activeCall == null) return;
        _activeCall = _activeCall!.copyWith(remoteStream: stream);
        _callStateController.add(_activeCall);
      });

      _webrtcDataSource.iceCandidates.listen((candidate) async {
        if (_activeCall == null) return;
        try {
          await sendIceCandidates(
            callId: _activeCall!.callId,
            roomId: _activeCall!.roomId,
            candidates: [candidate],
          );
        } catch (e) {
          _logger.e('Failed to send ICE candidate', error: e);
        }
      });
      
      _isInitialized = true;
      _logger.i('Call repository initialized');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize call repository', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Either<Failure, CallEntity>> createCall({
    required String roomId,
    required String calleeId,
    required bool isVideoCall,
  }) async {
    try {
      _logger.i('Creating call for room: $roomId, callee: $calleeId');

      if (!_isInitialized) {
        return const Left(ServerFailure(message: 'Call repository not initialized'));
      }

      if (_currentUserId == null) {
        return const Left(AuthFailure(message: 'User not authenticated'));
      }

      // Generate call ID
      final callId = _generateCallId();

      await _webrtcDataSource.createPeerConnection(const CallConfig());
      await _webrtcDataSource.getUserMedia(audio: true, video: isVideoCall);
      final offer = await _webrtcDataSource.createOffer(
        audio: true,
        video: isVideoCall,
      );
      await _webrtcDataSource.setLocalDescription(offer);

      // Send Matrix invite
      await _signalingDataSource.sendInvite(
        roomId: roomId,
        callId: callId,
        calleeId: calleeId,
        isVideoCall: isVideoCall,
        sdpOffer: offer.sdp,
      );

      // Create call entity
      final call = CallEntity(
        callId: callId,
        roomId: roomId,
        callerId: _currentUserId!,
        callerName: _currentUserName ?? _currentUserId!,
        calleeId: calleeId,
        calleeName: calleeId,
        isVideoCall: isVideoCall,
        state: CallState.outgoing,
        direction: CallDirection.outgoing,
      );

      _activeCall = call.copyWith(localStream: _webrtcDataSource.localStream);
      _callStateController.add(call);

      _logger.i('Call created successfully: $callId');
      return Right(call);
    } catch (e, stackTrace) {
      _logger.e('Failed to create call', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to create call: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> answerCall({
    required String callId,
    required String roomId,
  }) async {
    try {
      _logger.i('Answering call: $callId');

      if (_activeCall == null || _activeCall!.callId != callId) {
        return const Left(ServerFailure(message: 'No matching active call found'));
      }

      final answer = await _webrtcDataSource.createAnswer();
      await _webrtcDataSource.setLocalDescription(answer);

      await _signalingDataSource.sendAnswer(
        roomId: roomId,
        callId: callId,
        sdpAnswer: answer.sdp,
      );

      // Update call state
      _activeCall = _activeCall!.copyWith(
        state: CallState.active,
        localStream: _webrtcDataSource.localStream,
      );
      _callStateController.add(_activeCall);

      _logger.i('Call answered: $callId');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to answer call', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to answer call: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> rejectCall({
    required String callId,
    required String roomId,
  }) async {
    try {
      _logger.i('Rejecting call: $callId');

      // Send hangup with reject reason
      await _signalingDataSource.sendHangup(
        roomId: roomId,
        callId: callId,
        reason: 'reject',
      );

      // Clear active call
      if (_activeCall?.callId == callId) {
        _activeCall = null;
        _callStateController.add(null);
      }

      _logger.i('Call rejected: $callId');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to reject call', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to reject call: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> hangupCall({
    required String callId,
    required String roomId,
    String? reason,
  }) async {
    try {
      _logger.i('Hanging up call: $callId');

      // Send hangup
      await _signalingDataSource.sendHangup(
        roomId: roomId,
        callId: callId,
        reason: reason ?? 'user_hangup',
      );

      // Close WebRTC
      await _webrtcDataSource.closePeerConnection();

      // Clear active call
      if (_activeCall?.callId == callId) {
        _activeCall = null;
        _callStateController.add(null);
      }

      _logger.i('Call hung up: $callId');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to hangup call', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to hangup call: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendIceCandidates({
    required String callId,
    required String roomId,
    required List<IceCandidate> candidates,
  }) async {
    try {
      _logger.i('Sending ${candidates.length} ICE candidates');

      await _signalingDataSource.sendIceCandidates(
        roomId: roomId,
        callId: callId,
        candidates: candidates,
      );

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to send ICE candidates', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to send ICE candidates: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleMute({
    required String callId,
    required bool isMuted,
  }) async {
    try {
      _logger.i('Toggling mute: $isMuted');

      await _webrtcDataSource.toggleAudio(enabled: !isMuted);

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to toggle mute', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to toggle mute: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleSpeaker({
    required String callId,
    required bool isEnabled,
  }) async {
    try {
      _logger.i('Toggling speaker: $isEnabled');

      // LiveKit handles audio routing through the platform
      // This would need platform-specific implementation
      // For now, just log the action
      _logger.i('Speaker toggled: $isEnabled');

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to toggle speaker', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to toggle speaker: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleCamera({
    required String callId,
    required bool isEnabled,
  }) async {
    try {
      _logger.i('Toggling camera: $isEnabled');

      await _webrtcDataSource.toggleVideo(enabled: isEnabled);

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to toggle camera', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to toggle camera: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> switchCamera({required String callId}) async {
    try {
      _logger.i('Switching camera');

      await _webrtcDataSource.switchCamera();

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to switch camera', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to switch camera: $e'));
    }
  }

  @override
  Stream<CallEntity> get callStateStream {
    return _callStateController.stream.where((call) => call != null).cast<CallEntity>();
  }

  @override
  Stream<CallEntity> get incomingCallStream => _incomingCallController.stream;

  @override
  Future<Either<Failure, CallEntity?>> getActiveCall() async {
    try {
      return Right(_activeCall);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get active call: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> initialize() async {
    try {
      if (!_isInitialized) {
        await _init();
      }
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize', error: e, stackTrace: stackTrace);
      return Left(WebRTCFailure(message: 'Initialization failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> dispose() async {
    try {
      _logger.i('Disposing call repository');

      // Hang up any active call
      if (_activeCall != null) {
        await hangupCall(
          callId: _activeCall!.callId,
          roomId: _activeCall!.roomId,
          reason: 'dispose',
        );
      }

      await _webrtcDataSource.dispose();
      _signalingDataSource.dispose();
      await _callStateController.close();
      await _incomingCallController.close();

      _logger.i('Call repository disposed');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to dispose', error: e, stackTrace: stackTrace);
      return Left(WebRTCFailure(message: 'Dispose failed: $e'));
    }
  }

  /// Handle incoming call from Matrix
  void _handleIncomingCall(MatrixCallEvent event) async {
    try {
      _logger.i('Handling incoming call: ${event.callId}');
      final isVideoCall = event.isVideoCall ?? false;

      // Get caller info
      final callerName = event.senderId; // TODO: Get display name

      await _webrtcDataSource.createPeerConnection(const CallConfig());
      await _webrtcDataSource.getUserMedia(audio: true, video: isVideoCall);

      if (event.sdpOffer != null) {
        await _webrtcDataSource.setRemoteDescription(
          SessionDescription(sdp: event.sdpOffer!, type: SessionDescriptionType.offer),
        );
      }

      final call = CallEntity(
        callId: event.callId,
        roomId: event.roomId,
        callerId: event.senderId,
        callerName: callerName,
        calleeId: _currentUserId!,
        calleeName: _currentUserName ?? _currentUserId!,
        isVideoCall: isVideoCall,
        state: CallState.incoming,
        direction: CallDirection.incoming,
        localStream: _webrtcDataSource.localStream,
      );

      _activeCall = call;
      _incomingCallController.add(call);
    } catch (e, stackTrace) {
      _logger.e('Error handling incoming call', error: e, stackTrace: stackTrace);
    }
  }

  /// Handle call answer from Matrix
  void _handleCallAnswer(MatrixCallEvent event) {
    try {
      _logger.i('Handling call answer: ${event.callId}');

      if (_activeCall?.callId == event.callId) {
        if (event.sdpAnswer != null) {
          _webrtcDataSource.setRemoteDescription(
            SessionDescription(sdp: event.sdpAnswer!, type: SessionDescriptionType.answer),
          );
        }
        _activeCall = _activeCall!.copyWith(state: CallState.active);
        _callStateController.add(_activeCall);
      }
    } catch (e, stackTrace) {
      _logger.e('Error handling call answer', error: e, stackTrace: stackTrace);
    }
  }

  /// Handle call hangup from Matrix
  void _handleCallHangup(MatrixCallEvent event) {
    try {
      _logger.i('Handling call hangup: ${event.callId}');

      if (_activeCall?.callId == event.callId) {
        _webrtcDataSource.closePeerConnection();
        _activeCall = null;
        _callStateController.add(null);
      }
    } catch (e, stackTrace) {
      _logger.e('Error handling call hangup', error: e, stackTrace: stackTrace);
    }
  }

  void _handleIceCandidates(MatrixCallEvent event) {
    try {
      final candidates = event.candidates ?? [];
      for (final candidate in candidates) {
        _webrtcDataSource.addIceCandidate(
          candidate: IceCandidate.fromJson(candidate),
        );
      }
    } catch (e, stackTrace) {
      _logger.e('Error handling ICE candidates', error: e, stackTrace: stackTrace);
    }
  }

  /// Generate a unique call ID
  String _generateCallId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'call_${timestamp}_$random';
  }

  /// Get WebRTC data source for UI
  WebRTCDataSource get webrtcDataSource => _webrtcDataSource;
}
