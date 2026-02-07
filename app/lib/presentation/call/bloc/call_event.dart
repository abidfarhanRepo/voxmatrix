import 'package:equatable/equatable.dart';
import 'package:voxmatrix/domain/entities/call.dart';

abstract class CallEvent extends Equatable {
  const CallEvent();

  @override
  List<Object?> get props => [];
}

class CallInitEvent extends CallEvent {
  const CallInitEvent();
}

class CreateCallEvent extends CallEvent {
  const CreateCallEvent({
    required this.roomId,
    required this.calleeId,
    required this.isVideoCall,
  });

  final String roomId;
  final String calleeId;
  final bool isVideoCall;

  @override
  List<Object?> get props => [roomId, calleeId, isVideoCall];
}

class AnswerCallEvent extends CallEvent {
  const AnswerCallEvent({
    required this.callId,
    required this.roomId,
  });

  final String callId;
  final String roomId;

  @override
  List<Object?> get props => [callId, roomId];
}

class RejectCallEvent extends CallEvent {
  const RejectCallEvent({
    required this.callId,
    required this.roomId,
  });

  final String callId;
  final String roomId;

  @override
  List<Object?> get props => [callId, roomId];
}

class HangupCallEvent extends CallEvent {
  const HangupCallEvent({
    required this.callId,
    required this.roomId,
    this.reason,
  });

  final String callId;
  final String roomId;
  final String? reason;

  @override
  List<Object?> get props => [callId, roomId, reason];
}

class ToggleMuteEvent extends CallEvent {
  const ToggleMuteEvent({
    required this.callId,
    required this.isMuted,
  });

  final String callId;
  final bool isMuted;

  @override
  List<Object?> get props => [callId, isMuted];
}

class ToggleSpeakerEvent extends CallEvent {
  const ToggleSpeakerEvent({
    required this.callId,
    required this.isEnabled,
  });

  final String callId;
  final bool isEnabled;

  @override
  List<Object?> get props => [callId, isEnabled];
}

class ToggleCameraEvent extends CallEvent {
  const ToggleCameraEvent({
    required this.callId,
    required this.isEnabled,
  });

  final String callId;
  final bool isEnabled;

  @override
  List<Object?> get props => [callId, isEnabled];
}

class SwitchCameraEvent extends CallEvent {
  const SwitchCameraEvent({
    required this.callId,
  });

  final String callId;

  @override
  List<Object?> get props => [callId];
}

class CallStateUpdatedEvent extends CallEvent {
  const CallStateUpdatedEvent(this.call);

  final CallEntity call;

  @override
  List<Object?> get props => [call];
}

class IncomingCallReceivedEvent extends CallEvent {
  const IncomingCallReceivedEvent(this.call);

  final CallEntity call;

  @override
  List<Object?> get props => [call];
}
