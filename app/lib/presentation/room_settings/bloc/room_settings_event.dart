import 'package:equatable/equatable.dart';
import 'package:voxmatrix/domain/entities/room_settings.dart';

/// Base room settings event
abstract class RoomSettingsEvent extends Equatable {
  const RoomSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Load room settings
class LoadRoomSettings extends RoomSettingsEvent {
  const LoadRoomSettings(this.roomId);

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

/// Update room name
class UpdateRoomName extends RoomSettingsEvent {
  const UpdateRoomName({
    required this.roomId,
    required this.name,
  });

  final String roomId;
  final String name;

  @override
  List<Object?> get props => [roomId, name];
}

/// Update room topic
class UpdateRoomTopic extends RoomSettingsEvent {
  const UpdateRoomTopic({
    required this.roomId,
    required this.topic,
  });

  final String roomId;
  final String topic;

  @override
  List<Object?> get props => [roomId, topic];
}

/// Update room avatar
class UpdateRoomAvatar extends RoomSettingsEvent {
  const UpdateRoomAvatar({
    required this.roomId,
    required this.mxcUrl,
  });

  final String roomId;
  final String mxcUrl;

  @override
  List<Object?> get props => [roomId, mxcUrl];
}

/// Update join rule
class UpdateJoinRule extends RoomSettingsEvent {
  const UpdateJoinRule({
    required this.roomId,
    required this.joinRule,
  });

  final String roomId;
  final JoinRule joinRule;

  @override
  List<Object?> get props => [roomId, joinRule];
}

/// Update guest access
class UpdateGuestAccess extends RoomSettingsEvent {
  const UpdateGuestAccess({
    required this.roomId,
    required this.guestAccess,
  });

  final String roomId;
  final GuestAccess guestAccess;

  @override
  List<Object?> get props => [roomId, guestAccess];
}

/// Update history visibility
class UpdateHistoryVisibility extends RoomSettingsEvent {
  const UpdateHistoryVisibility({
    required this.roomId,
    required this.historyVisibility,
  });

  final String roomId;
  final HistoryVisibility historyVisibility;

  @override
  List<Object?> get props => [roomId, historyVisibility];
}

/// Delete room
class DeleteRoom extends RoomSettingsEvent {
  const DeleteRoom(this.roomId);

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

/// Leave room
class LeaveRoom extends RoomSettingsEvent {
  const LeaveRoom(this.roomId);

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}
