import 'package:equatable/equatable.dart';

/// Represents a room member
class RoomMember extends Equatable {
  const RoomMember({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.powerLevel = 0,
    this.membership = 'join',
    this.isPresent = false,
  });

  /// The Matrix user ID (@user:server.com)
  final String userId;

  /// Display name
  final String displayName;

  /// Avatar URL (mxc://)
  final String? avatarUrl;

  /// Power level (0=regular, 50=mod, 100=admin)
  final int powerLevel;

  /// Membership status (join/invite/leave/ban/knock)
  final String membership;

  /// Whether the user is currently present (online)
  final bool isPresent;

  @override
  List<Object?> get props => [
        userId,
        displayName,
        avatarUrl,
        powerLevel,
        membership,
        isPresent,
      ];

  /// Get the user's initials for avatar
  String get initials {
    if (displayName.isEmpty) return '@';
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }

  /// Check if this user is an admin
  bool get isAdmin => powerLevel >= 100;

  /// Check if this user is a moderator
  bool get isModerator => powerLevel >= 50;

  /// Get a color based on user ID (consistent for same user)
  int get colorHash => userId.hashCode & 0xFFFFFF;

  RoomMember copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    int? powerLevel,
    String? membership,
    bool? isPresent,
  }) {
    return RoomMember(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      powerLevel: powerLevel ?? this.powerLevel,
      membership: membership ?? this.membership,
      isPresent: isPresent ?? this.isPresent,
    );
  }
}
