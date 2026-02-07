import 'package:equatable/equatable.dart';
import 'package:voxmatrix/domain/entities/room_member.dart';

/// Base room members state
abstract class RoomMembersState extends Equatable {
  const RoomMembersState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class RoomMembersInitial extends RoomMembersState {
  const RoomMembersInitial();
}

/// Loading state
class RoomMembersLoading extends RoomMembersState {
  const RoomMembersLoading();
}

/// Members loaded successfully
class RoomMembersLoaded extends RoomMembersState {
  const RoomMembersLoaded(this.members);

  final List<RoomMember> members;

  @override
  List<Object?> get props => [members];
}

/// Error state
class RoomMembersError extends RoomMembersState {
  const RoomMembersError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Action in progress (kick/ban/invite/leave)
class RoomMembersActionInProgress extends RoomMembersState {
  const RoomMembersActionInProgress(this.members, this.action);

  final List<RoomMember> members;
  final String action;

  @override
  List<Object?> get props => [members, action];
}
