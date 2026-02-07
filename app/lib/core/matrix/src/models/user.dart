/// Matrix User model
///
/// Represents a Matrix user with their profile information
/// See: https://spec.matrix.org/v1.11/client-server-api/#user-management

/// Matrix User class
class MatrixUser {
  /// Create a new Matrix user
  MatrixUser({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.membership = 'unknown',
  });

  /// Create a Matrix user from JSON
  factory MatrixUser.fromJson(Map<String, dynamic> json) {
    return MatrixUser(
      id: json['user_id'] as String? ?? json['id'] as String,
      displayName: json['displayname'] as String? ?? json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      membership: json['membership'] as String? ?? 'unknown',
    );
  }

  /// The user's Matrix ID (e.g., '@user:server.com')
  final String id;

  /// The user's display name
  final String? displayName;

  /// The user's avatar URL
  final String? avatarUrl;

  /// The user's membership state in a room
  final String membership;

  /// Get the username part of the Matrix ID
  String get username {
    return id.split(':')[0].replaceAll('@', '');
  }

  /// Get the homeserver part of the Matrix ID
  String get homeserver {
    final parts = id.split(':');
    return parts.length > 1 ? parts[1] : '';
  }

  /// Check if the user is currently in a room (membership is 'join')
  bool get isJoined => membership == 'join';

  /// Check if the user has been invited to a room (membership is 'invite')
  bool get isInvited => membership == 'invite';

  /// Check if the user has left a room (membership is 'leave' or 'ban')
  bool get hasLeft => membership == 'leave' || membership == 'ban';

  /// Convert user to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      if (displayName != null) 'displayname': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'membership': membership,
    };
  }

  /// Create a copy of this user with modified fields
  MatrixUser copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    String? membership,
  }) {
    return MatrixUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      membership: membership ?? this.membership,
    );
  }

  @override
  String toString() {
    return 'MatrixUser(id: $id, displayName: $displayName, membership: $membership)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatrixUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
