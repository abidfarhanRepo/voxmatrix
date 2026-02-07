import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/room.dart';

part 'room_model.g.dart';

@JsonSerializable()
class RoomModel extends Equatable {
  const RoomModel({
    required this.id,
    required this.name,
    required this.isDirect,
    required this.timestamp,
    this.topic,
    this.avatarUrl,
    this.lastMessage,
    this.unreadCount = 0,
    this.members = const [],
    this.isFavourite = false,
    this.isMuted = false,
  });

  final String id;
  final String name;
  final bool isDirect;
  @JsonKey(fromJson: _fromJsonTimestamp, toJson: _toJsonTimestamp)
  final DateTime timestamp;
  final String? topic;
  final String? avatarUrl;
  final MessageSummaryModel? lastMessage;
  final int unreadCount;
  final List<RoomMemberModel> members;
  final bool isFavourite;
  final bool isMuted;

  factory RoomModel.fromJson(Map<String, dynamic> json) =>
      _$RoomModelFromJson(json);

  Map<String, dynamic> toJson() => _$RoomModelToJson(this);

  RoomEntity toEntity() {
    return RoomEntity(
      id: id,
      name: name,
      isDirect: isDirect,
      timestamp: timestamp,
      topic: topic,
      avatarUrl: avatarUrl,
      lastMessage: lastMessage?.toEntity(),
      unreadCount: unreadCount,
      members: members.map((m) => m.toEntity()).toList(),
      isFavourite: isFavourite,
      isMuted: isMuted,
    );
  }

  factory RoomModel.fromEntity(RoomEntity entity) {
    return RoomModel(
      id: entity.id,
      name: entity.name,
      isDirect: entity.isDirect,
      timestamp: entity.timestamp,
      topic: entity.topic,
      avatarUrl: entity.avatarUrl,
      lastMessage: entity.lastMessage != null
          ? MessageSummaryModel.fromEntity(entity.lastMessage!)
          : null,
      unreadCount: entity.unreadCount,
      members: entity.members.map((m) => RoomMemberModel.fromEntity(m)).toList(),
      isFavourite: entity.isFavourite,
      isMuted: entity.isMuted,
    );
  }

  static DateTime _fromJsonTimestamp(int timestamp) =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  static int _toJsonTimestamp(DateTime timestamp) =>
      timestamp.millisecondsSinceEpoch ~/ 1000;

  @override
  List<Object?> get props {
    return [
      id,
      name,
      isDirect,
      timestamp,
      topic,
      avatarUrl,
      lastMessage,
      unreadCount,
      members,
      isFavourite,
      isMuted,
    ];
  }
}

@JsonSerializable()
class MessageSummaryModel extends Equatable {
  const MessageSummaryModel({
    required this.content,
    required this.timestamp,
    required this.senderName,
  });

  final String content;
  @JsonKey(fromJson: _fromJsonTimestamp, toJson: _toJsonTimestamp)
  final DateTime timestamp;
  final String senderName;

  factory MessageSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$MessageSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageSummaryModelToJson(this);

  MessageSummary toEntity() {
    return MessageSummary(
      content: content,
      timestamp: timestamp,
      senderName: senderName,
    );
  }

  factory MessageSummaryModel.fromEntity(MessageSummary entity) {
    return MessageSummaryModel(
      content: entity.content,
      timestamp: entity.timestamp,
      senderName: entity.senderName,
    );
  }

  static DateTime _fromJsonTimestamp(int timestamp) =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  static int _toJsonTimestamp(DateTime timestamp) =>
      timestamp.millisecondsSinceEpoch ~/ 1000;

  @override
  List<Object> get props => [content, timestamp, senderName];
}

@JsonSerializable()
class RoomMemberModel extends Equatable {
  const RoomMemberModel({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.role = MemberRole.member,
    this.presence = PresenceState.offline,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final MemberRole role;
  final PresenceState presence;

  factory RoomMemberModel.fromJson(Map<String, dynamic> json) =>
      _$RoomMemberModelFromJson(json);

  Map<String, dynamic> toJson() => _$RoomMemberModelToJson(this);

  RoomMember toEntity() {
    return RoomMember(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      role: role,
      presence: presence,
    );
  }

  factory RoomMemberModel.fromEntity(RoomMember entity) {
    return RoomMemberModel(
      userId: entity.userId,
      displayName: entity.displayName,
      avatarUrl: entity.avatarUrl,
      role: entity.role,
      presence: entity.presence,
    );
  }

  @override
  List<Object?> get props => [userId, displayName, avatarUrl, role, presence];
}
