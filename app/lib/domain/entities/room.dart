import 'package:equatable/equatable.dart';

/// Room entity representing a Matrix room
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

  /// Unique room ID
  final String id;

  /// Display name of the room
  final String name;

  /// Whether this is a direct message (1:1) chat
  final bool isDirect;

  /// Last activity timestamp
  final DateTime timestamp;

  /// Optional room topic/description
  final String? topic;

  /// Room avatar URL (mxc://)
  final String? avatarUrl;

  /// Last message summary
  final MessageSummary? lastMessage;

  /// Number of unread messages
  final int unreadCount;

  /// List of room members
  final List<RoomMember> members;

  /// Whether room is marked as favourite
  final bool isFavourite;

  /// Whether notifications are muted for this room
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

/// Summary of the last message in a room
class MessageSummary extends Equatable {
  const MessageSummary({
    required this.content,
    required this.timestamp,
    required this.senderName,
    this.senderId,
  });

  /// Message content (text or description for media)
  final String content;

  /// When the message was sent
  final DateTime timestamp;

  /// Display name of sender
  final String senderName;

  /// User ID of sender
  final String? senderId;

  @override
  List<Object?> get props => [content, timestamp, senderName, senderId];
}

/// Room member information
class RoomMember extends Equatable {
  const RoomMember({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.role = MemberRole.member,
    this.presence = PresenceState.offline,
  });

  /// Matrix user ID (@user:server.com)
  final String userId;

  /// Display name
  final String displayName;

  /// Avatar URL (mxc://)
  final String? avatarUrl;

  /// Power level/role in the room
  final MemberRole role;

  /// Current presence status
  final PresenceState presence;

  @override
  List<Object?> get props => [userId, displayName, avatarUrl, role, presence];
}

/// Member power levels
enum MemberRole { owner, admin, moderator, member }

/// User presence states
enum PresenceState { online, offline, away, busy }
