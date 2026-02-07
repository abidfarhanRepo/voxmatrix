import 'package:equatable/equatable.dart';

/// Direct message entity
/// Represents a direct chat between two users
class DirectMessage extends Equatable {
  const DirectMessage({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatarUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  /// Get initials for avatar
  String get initials {
    if (otherUserName.isEmpty) return '?';
    final parts = otherUserName.split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return otherUserName[0].toUpperCase();
  }

  @override
  List<Object?> get props => [
        id,
        otherUserId,
        otherUserName,
        otherUserAvatarUrl,
        lastMessage,
        lastMessageTime,
        unreadCount,
      ];
}
