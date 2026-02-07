import 'package:dartz/dartz.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/domain/entities/call.dart';

abstract class CallRepository {
  /// Create a new outgoing call
  Future<Either<Failure, CallEntity>> createCall({
    required String roomId,
    required String calleeId,
    required bool isVideoCall,
  });

  /// Answer an incoming call
  Future<Either<Failure, void>> answerCall({
    required String callId,
    required String roomId,
  });

  /// Reject an incoming call
  Future<Either<Failure, void>> rejectCall({
    required String callId,
    required String roomId,
  });

  /// Hangup an active call
  Future<Either<Failure, void>> hangupCall({
    required String callId,
    required String roomId,
    String? reason,
  });

  /// Send ICE candidates
  Future<Either<Failure, void>> sendIceCandidates({
    required String callId,
    required String roomId,
    required List<IceCandidate> candidates,
  });

  /// Toggle microphone mute state
  Future<Either<Failure, void>> toggleMute({
    required String callId,
    required bool isMuted,
  });

  /// Toggle speaker state
  Future<Either<Failure, void>> toggleSpeaker({
    required String callId,
    required bool isEnabled,
  });

  /// Toggle camera state
  Future<Either<Failure, void>> toggleCamera({
    required String callId,
    required bool isEnabled,
  });

  /// Switch camera direction (front/back)
  Future<Either<Failure, void>> switchCamera({
    required String callId,
  });

  /// Get current call state
  Stream<CallEntity> get callStateStream;

  /// Listen for incoming calls
  Stream<CallEntity> get incomingCallStream;

  /// Get active call
  Future<Either<Failure, CallEntity?>> getActiveCall();

  /// Initialize call subsystem
  Future<Either<Failure, void>> initialize();

  /// Cleanup resources
  Future<Either<Failure, void>> dispose();
}
