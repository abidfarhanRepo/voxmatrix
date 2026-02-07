import 'package:equatable/equatable.dart';

/// Represents a Matrix Space (group of rooms)
/// See: https://spec.matrix.org/v1.11/client-server-api/#m-space
class SpaceEntity extends Equatable {
  const SpaceEntity({
    required this.id,
    required this.name,
    this.topic,
    this.avatarUrl,
    this.rooms = const [],
    this.memberCount = 0,
  });

  /// The room ID of the space
  final String id;

  /// The name of the space
  final String name;

  /// Optional topic/description
  final String? topic;

  /// Optional avatar URL (mxc://)
  final String? avatarUrl;

  /// List of room IDs that are part of this space
  final List<String> rooms;

  /// Number of members in the space
  final int memberCount;

  @override
  List<Object?> get props => [id, name, topic, avatarUrl, rooms, memberCount];
}
