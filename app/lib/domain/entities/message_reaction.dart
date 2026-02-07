import 'package:equatable/equatable.dart';

/// Represents a reaction to a message
/// See: https://spec.matrix.org/v1.11/client-server-api/#mreaction
class MessageReaction extends Equatable {
  const MessageReaction({
    required this.emoji,
    required this.count,
    this.senders = const [],
    this.containsCurrentUser = false,
  });

  /// The emoji character (e.g., "👍", "❤️")
  final String emoji;

  /// Number of users who reacted with this emoji
  final int count;

  /// List of user IDs who reacted
  final List<String> senders;

  /// Whether the current user is part of this reaction
  final bool containsCurrentUser;

  @override
  List<Object?> get props => [emoji, count, senders, containsCurrentUser];

  MessageReaction copyWith({
    String? emoji,
    int? count,
    List<String>? senders,
    bool? containsCurrentUser,
  }) {
    return MessageReaction(
      emoji: emoji ?? this.emoji,
      count: count ?? this.count,
      senders: senders ?? this.senders,
      containsCurrentUser: containsCurrentUser ?? this.containsCurrentUser,
    );
  }
}
