import 'package:equatable/equatable.dart';

/// Represents a reply to another message
class MessageReply extends Equatable {
  const MessageReply({
    required this.messageId,
    required this.content,
    required this.senderName,
    this.senderId,
  });

  /// The ID of the message being replied to
  final String messageId;

  /// The content of the message being replied to
  final String content;

  /// The display name of the sender of the original message
  final String senderName;

  /// Optional: The user ID of the sender
  final String? senderId;

  @override
  List<Object?> get props => [messageId, content, senderName, senderId];

  /// Get a preview of the reply (truncated content)
  String get preview {
    const maxLength = 50;
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  MessageReply copyWith({
    String? messageId,
    String? content,
    String? senderName,
    String? senderId,
  }) {
    return MessageReply(
      messageId: messageId ?? this.messageId,
      content: content ?? this.content,
      senderName: senderName ?? this.senderName,
      senderId: senderId ?? this.senderId,
    );
  }
}
