/// Matrix Room model
///
/// Represents a Matrix room with its state and member information
/// See: https://spec.matrix.org/v1.11/client-server-api/#room-model

import 'package:voxmatrix/core/matrix/src/models/event.dart';
import 'package:voxmatrix/core/matrix/src/models/user.dart';

/// Matrix Room class
class MatrixRoom {
  /// Create a new Matrix room
  MatrixRoom({
    required this.id,
    required this.name,
    this.topic,
    this.avatarUrl,
    this.isDirect = false,
    this.members = const [],
    this.heroes = const [],
    this.joinedMemberCount = 0,
    this.invitedMemberCount = 0,
    this.lastEvent,
    this.unreadCount = 0,
    this.highlightCount = 0,
    this.notificationCount = 0,
    this.tags = const [],
    this.isEncrypted = false,
    this.currentState = const [],
  });

  /// Create a Matrix room from JSON
  factory MatrixRoom.fromJson(Map<String, dynamic> json) {
    return MatrixRoom(
      id: json['room_id'] as String,
      name: json['name'] as String? ?? json['room_id'] as String,
      topic: json['topic'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isDirect: json['is_direct'] as bool? ?? false,
      members: (json['members'] as List?)
              ?.map((m) => m is Map<String, dynamic>
                  ? MatrixUser.fromJson(m)
                  : null)
              .whereType<MatrixUser>()
              .toList() ??
          [],
      heroes: (json['heroes'] as List?)?.cast<String>() ?? [],
      joinedMemberCount: json['joined_member_count'] as int? ?? 0,
      invitedMemberCount: json['invited_member_count'] as int? ?? 0,
      unreadCount: json['unread_count'] as int? ?? 0,
      highlightCount: json['highlight_count'] as int? ?? 0,
      notificationCount: json['notification_count'] as int? ?? 0,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      isEncrypted: json['is_encrypted'] as bool? ?? false,
    );
  }

  /// The room ID
  final String id;

  /// The room name
  String name;

  /// The room topic
  final String? topic;

  /// The room avatar URL
  final String? avatarUrl;

  /// Whether this is a direct message room
  final bool isDirect;

  /// The room members
  final List<MatrixUser> members;

  /// The heroes (important members for room name calculation)
  final List<String> heroes;

  /// The number of joined members
  final int joinedMemberCount;

  /// The number of invited members
  final int invitedMemberCount;

  /// The last event in the room
  final MatrixEvent? lastEvent;

  /// The number of unread messages
  final int unreadCount;

  /// The number of highlighted messages
  final int highlightCount;

  /// The number of notifications
  final int notificationCount;

  /// The room tags
  final List<String> tags;

  /// Whether the room is encrypted
  final bool isEncrypted;

  /// The current state events
  final List<MatrixEvent> currentState;

  /// Get the room alias (e.g., '#room:server.com')
  String? get alias {
    final aliasEvent = currentState.firstWhere(
      (e) => e.type == 'm.room.canonical_alias',
      orElse: () => MatrixEvent(
        type: 'm.room.canonical_alias',
        roomId: id,
        content: {},
      ),
    );
    return aliasEvent.content['alias'] as String?;
  }

  /// Get the room creator
  String? get creator {
    final createEvent = currentState.firstWhere(
      (e) => e.type == 'm.room.create',
      orElse: () => MatrixEvent(
        type: 'm.room.create',
        roomId: id,
        content: {},
      ),
    );
    return createEvent.content['creator'] as String?;
  }

  /// Get the room version
  String? get roomVersion {
    final createEvent = currentState.firstWhere(
      (e) => e.type == 'm.room.create',
      orElse: () => MatrixEvent(
        type: 'm.room.create',
        roomId: id,
        content: {},
      ),
    );
    return createEvent.content['room_version'] as String?;
  }

  /// Check if the user is a member of this room
  bool isMember(String userId) {
    return members.any((m) => m.id == userId);
  }

  /// Get a member by user ID
  MatrixUser? getMember(String userId) {
    try {
      return members.firstWhere((m) => m.id == userId);
    } catch (e) {
      return null;
    }
  }

  /// Get the display name for a user
  String? getMemberDisplayName(String userId) {
    return getMember(userId)?.displayName;
  }

  /// Get the power level of a user
  int getUserPowerLevel(String userId) {
    final powerEvent = currentState.firstWhere(
      (e) => e.type == 'm.room.power_levels',
      orElse: () => MatrixEvent(
        type: 'm.room.power_levels',
        roomId: id,
        content: {},
      ),
    );
    final users = powerEvent.content['users'] as Map<String, dynamic>? ?? {};
    return users[userId] as int? ?? 0;
  }

  /// Check if a user has permission to send messages
  bool canSendMessage(String userId) {
    final powerLevel = getUserPowerLevel(userId);
    final powerEvent = currentState.firstWhere(
      (e) => e.type == 'm.room.power_levels',
      orElse: () => MatrixEvent(
        type: 'm.room.power_levels',
        roomId: id,
        content: {},
      ),
    );
    final events = powerEvent.content['events'] as Map<String, dynamic>? ?? {};
    final requiredLevel = events['m.room.message'] as int? ?? 0;
    return powerLevel >= requiredLevel;
  }

  /// Get the join rule
  String get joinRule {
    final joinRulesEvent = currentState.firstWhere(
      (e) => e.type == 'm.room.join_rules',
      orElse: () => MatrixEvent(
        type: 'm.room.join_rules',
        roomId: id,
        content: {},
      ),
    );
    return joinRulesEvent.content['join_rule'] as String? ?? 'invite';
  }

  /// Get the history visibility
  String get historyVisibility {
    final historyEvent = currentState.firstWhere(
      (e) => e.type == 'm.room.history_visibility',
      orElse: () => MatrixEvent(
        type: 'm.room.history_visibility',
        roomId: id,
        content: {},
      ),
    );
    return historyEvent.content['history_visibility'] as String? ?? 'shared';
  }

  /// Get the guest access setting
  String get guestAccess {
    final guestEvent = currentState.firstWhere(
      (e) => e.type == 'm.room.guest_access',
      orElse: () => MatrixEvent(
        type: 'm.room.guest_access',
        roomId: id,
        content: {},
      ),
    );
    return guestEvent.content['guest_access'] as String? ?? 'forbidden';
  }

  /// Convert room to JSON
  Map<String, dynamic> toJson() {
    return {
      'room_id': id,
      'name': name,
      if (topic != null) 'topic': topic,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'is_direct': isDirect,
      'members': members.map((m) => m.toJson()).toList(),
      'heroes': heroes,
      'joined_member_count': joinedMemberCount,
      'invited_member_count': invitedMemberCount,
      if (lastEvent != null) 'last_event': lastEvent!.toJson(),
      'unread_count': unreadCount,
      'highlight_count': highlightCount,
      'notification_count': notificationCount,
      'tags': tags,
      'is_encrypted': isEncrypted,
    };
  }

  /// Create a copy of this room with modified fields
  MatrixRoom copyWith({
    String? id,
    String? name,
    String? topic,
    String? avatarUrl,
    bool? isDirect,
    List<MatrixUser>? members,
    List<String>? heroes,
    int? joinedMemberCount,
    int? invitedMemberCount,
    MatrixEvent? lastEvent,
    int? unreadCount,
    int? highlightCount,
    int? notificationCount,
    List<String>? tags,
    bool? isEncrypted,
    List<MatrixEvent>? currentState,
  }) {
    return MatrixRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      topic: topic ?? this.topic,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isDirect: isDirect ?? this.isDirect,
      members: members ?? this.members,
      heroes: heroes ?? this.heroes,
      joinedMemberCount: joinedMemberCount ?? this.joinedMemberCount,
      invitedMemberCount: invitedMemberCount ?? this.invitedMemberCount,
      lastEvent: lastEvent ?? this.lastEvent,
      unreadCount: unreadCount ?? this.unreadCount,
      highlightCount: highlightCount ?? this.highlightCount,
      notificationCount: notificationCount ?? this.notificationCount,
      tags: tags ?? this.tags,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      currentState: currentState ?? this.currentState,
    );
  }

  @override
  String toString() {
    return 'MatrixRoom(id: $id, name: $name, members: ${joinedMemberCount})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatrixRoom && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
