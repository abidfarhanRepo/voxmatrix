import 'package:equatable/equatable.dart';

/// Base class for all room events
abstract class RoomsEvent extends Equatable {
  const RoomsEvent();

  @override
  List<Object?> get props => [];
}

/// Load all rooms for the current user
class LoadRooms extends RoomsEvent {
  const LoadRooms();
}

/// Refresh the room list
class RefreshRooms extends RoomsEvent {
  const RefreshRooms();
}

/// Subscribe to room updates
class SubscribeToRooms extends RoomsEvent {
  const SubscribeToRooms();
}

/// Filter rooms by search query
class FilterRooms extends RoomsEvent {
  const FilterRooms(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Switch between room tabs (all rooms vs direct messages)
class SwitchRoomTab extends RoomsEvent {
  const SwitchRoomTab(this.showDirectMessagesOnly);

  final bool showDirectMessagesOnly;

  @override
  List<Object?> get props => [showDirectMessagesOnly];
}

/// Mark a room as read
class MarkRoomAsRead extends RoomsEvent {
  const MarkRoomAsRead(this.roomId);

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

/// Mark a room as favourite
class ToggleFavouriteRoom extends RoomsEvent {
  const ToggleFavouriteRoom(this.roomId);

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

/// Mute/unmute a room
class ToggleMuteRoom extends RoomsEvent {
  const ToggleMuteRoom(this.roomId);

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

/// Leave a room
class LeaveRoom extends RoomsEvent {
  const LeaveRoom(this.roomId);

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

/// Create a new room
class CreateRoom extends RoomsEvent {
  const CreateRoom({
    required this.name,
    this.topic,
    this.isPrivate = false,
    this.inviteUserIds,
  });

  final String name;
  final String? topic;
  final bool isPrivate;
  final List<String>? inviteUserIds;

  @override
  List<Object?> get props => [name, topic, isPrivate, inviteUserIds];
}

/// Join a room by ID or alias
class JoinRoom extends RoomsEvent {
  const JoinRoom(this.roomIdOrAlias);

  final String roomIdOrAlias;

  @override
  List<Object?> get props => [roomIdOrAlias];
}
