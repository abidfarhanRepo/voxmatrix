import 'package:equatable/equatable.dart';

/// Room settings entity
/// Represents configurable settings for a Matrix room
class RoomSettings extends Equatable {
  const RoomSettings({
    required this.roomId,
    this.name,
    this.topic,
    this.avatarUrl,
    this.joinRule = JoinRule.invite,
    this.guestAccess = GuestAccess.forbidden,
    this.historyVisibility = HistoryVisibility.shared,
    this.canModify = false,
  });

  final String roomId;
  final String? name;
  final String? topic;
  final String? avatarUrl;
  final JoinRule joinRule;
  final GuestAccess guestAccess;
  final HistoryVisibility historyVisibility;
  final bool canModify;

  RoomSettings copyWith({
    String? roomId,
    String? name,
    String? topic,
    String? avatarUrl,
    JoinRule? joinRule,
    GuestAccess? guestAccess,
    HistoryVisibility? historyVisibility,
    bool? canModify,
  }) {
    return RoomSettings(
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      topic: topic ?? this.topic,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinRule: joinRule ?? this.joinRule,
      guestAccess: guestAccess ?? this.guestAccess,
      historyVisibility: historyVisibility ?? this.historyVisibility,
      canModify: canModify ?? this.canModify,
    );
  }

  @override
  List<Object?> get props => [
        roomId,
        name,
        topic,
        avatarUrl,
        joinRule,
        guestAccess,
        historyVisibility,
        canModify,
      ];
}

/// Join rule for a room
enum JoinRule {
  /// Anyone can join without invite
  public,

  /// Users must be invited
  invite,

  /// Users must be invited and know the room ID
  knock,

  /// Only members of a specific space can join
  restricted,

  /// Only via a direct invite URL
  private;
}

extension JoinRuleExtension on JoinRule {
  String get value {
    switch (this) {
      case JoinRule.public:
        return 'public';
      case JoinRule.invite:
        return 'invite';
      case JoinRule.knock:
        return 'knock';
      case JoinRule.restricted:
        return 'restricted';
      case JoinRule.private:
        return 'private';
    }
  }

  String get displayName {
    switch (this) {
      case JoinRule.public:
        return 'Public (Anyone can join)';
      case JoinRule.invite:
        return 'Invite Only';
      case JoinRule.knock:
        return 'Knock (Request to join)';
      case JoinRule.restricted:
        return 'Restricted';
      case JoinRule.private:
        return 'Private';
    }
  }

  static JoinRule? fromValue(String value) {
    switch (value) {
      case 'public':
        return JoinRule.public;
      case 'invite':
        return JoinRule.invite;
      case 'knock':
        return JoinRule.knock;
      case 'restricted':
        return JoinRule.restricted;
      case 'private':
        return JoinRule.private;
      default:
        return null;
    }
  }
}

/// Guest access setting
enum GuestAccess {
  /// Guests can join the room
  canJoin,

  /// Guests cannot join the room
  forbidden,
}

extension GuestAccessExtension on GuestAccess {
  String get value {
    switch (this) {
      case GuestAccess.canJoin:
        return 'can_join';
      case GuestAccess.forbidden:
        return 'forbidden';
    }
  }

  String get displayName {
    switch (this) {
      case GuestAccess.canJoin:
        return 'Allowed';
      case GuestAccess.forbidden:
        return 'Not Allowed';
    }
  }

  static GuestAccess? fromValue(String value) {
    switch (value) {
      case 'can_join':
        return GuestAccess.canJoin;
      case 'forbidden':
        return GuestAccess.forbidden;
      default:
        return null;
    }
  }
}

/// History visibility setting
enum HistoryVisibility {
  /// Anyone can see history (including non-members)
  worldReadable,

  /// Members can see history from when they joined
  joined,

  /// Members can see all history
  shared,

  /// Members can see history only after invite
  invited,
}

extension HistoryVisibilityExtension on HistoryVisibility {
  String get value {
    switch (this) {
      case HistoryVisibility.worldReadable:
        return 'world_readable';
      case HistoryVisibility.joined:
        return 'joined';
      case HistoryVisibility.shared:
        return 'shared';
      case HistoryVisibility.invited:
        return 'invited';
    }
  }

  String get displayName {
    switch (this) {
      case HistoryVisibility.worldReadable:
        return 'Anyone (including non-members)';
      case HistoryVisibility.joined:
        return 'From when they joined';
      case HistoryVisibility.shared:
        return 'All members (all history)';
      case HistoryVisibility.invited:
        return 'From when invited';
    }
  }

  String get description {
    switch (this) {
      case HistoryVisibility.worldReadable:
        return 'Room history is publicly visible';
      case HistoryVisibility.joined:
        return 'Users can only see messages sent after they joined';
      case HistoryVisibility.shared:
        return 'All members can see all room history';
      case HistoryVisibility.invited:
        return 'Users can see messages from when they were invited';
    }
  }

  static HistoryVisibility? fromValue(String value) {
    switch (value) {
      case 'world_readable':
        return HistoryVisibility.worldReadable;
      case 'joined':
        return HistoryVisibility.joined;
      case 'shared':
        return HistoryVisibility.shared;
      case 'invited':
        return HistoryVisibility.invited;
      default:
        return null;
    }
  }
}
