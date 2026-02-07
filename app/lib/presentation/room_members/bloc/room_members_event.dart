import 'package:equatable/equatable.dart';

/// Base room members event
abstract class RoomMembersEvent extends Equatable {
  const RoomMembersEvent();

  @override
  List<Object?> get props => [];
}

/// Load room members
class LoadRoomMembers extends RoomMembersEvent {
  const LoadRoomMembers(this.roomId);

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

/// Refresh room members
class RefreshRoomMembers extends RoomMembersEvent {
  const RefreshRoomMembers(this.roomId);

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

/// Kick user from room
class KickUser extends RoomMembersEvent {
  const KickUser({
    required this.roomId,
    required this.userId,
    this.reason,
  });

  final String roomId;
  final String userId;
  final String? reason;

  @override
  List<Object?> get props => [roomId, userId, reason];
}

/// Ban user from room
class BanUser extends RoomMembersEvent {
  const BanUser({
    required this.roomId,
    required this.userId,
    this.reason,
  });

  final String roomId;
  final String userId;
  final String? reason;

  @override
  List<Object?> get props => [roomId, userId, reason];
}

/// Unban user from room
class UnbanUser extends RoomMembersEvent {
  const UnbanUser({
    required this.roomId,
    required this.userId,
  });

  final String roomId;
  final String userId;

  @override
  List<Object?> get props => [roomId, userId];
}

/// Invite user to room
class InviteUser extends RoomMembersEvent {
  const InviteUser({
    required this.roomId,
    required this.userId,
  });

  final String roomId;
  final String userId;

  @override
  List<Object?> get props => [roomId, userId];
}

/// Leave room
class LeaveRoom extends RoomMembersEvent {
  const LeaveRoom(this.roomId);

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}
