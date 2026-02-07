import 'package:equatable/equatable.dart';

class RoomEntity extends Equatable {
  const RoomEntity({
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
  final DateTime timestamp;
  final String? topic;
  final String? avatarUrl;
  final MessageSummary? lastMessage;
  final int unreadCount;
  final List<RoomMember> members;
  final bool isFavourite;
  final bool isMuted;

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

  RoomEntity copyWith({
    String? id,
    String? name,
    bool? isDirect,
    DateTime? timestamp,
    String? topic,
    String? avatarUrl,
    MessageSummary? lastMessage,
    int? unreadCount,
    List<RoomMember>? members,
    bool? isFavourite,
    bool? isMuted,
  }) {
    return RoomEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      isDirect: isDirect ?? this.isDirect,
      timestamp: timestamp ?? this.timestamp,
      topic: topic ?? this.topic,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      members: members ?? this.members,
      isFavourite: isFavourite ?? this.isFavourite,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

class MessageSummary extends Equatable {
  const MessageSummary({
    required this.content,
    required this.timestamp,
    required this.senderName,
  });

  final String content;
  final DateTime timestamp;
  final String senderName;

  @override
  List<Object> get props => [content, timestamp, senderName];
}

class RoomMember extends Equatable {
  const RoomMember({
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

  @override
  List<Object?> get props => [userId, displayName, avatarUrl, role, presence];
}

enum MemberRole { owner, admin, moderator, member }

enum PresenceState { online, offline, away, busy }
