import 'package:equatable/equatable.dart';

/// Message entity representing a Matrix message event
class MessageEntity extends Equatable {
  const MessageEntity({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.senderAvatarUrl,
    this.editedTimestamp,
    this.replyToId,
    this.attachments = const [],
    this.isLocalOnly = false,
    this.readReceipts = const [],
    this.reactions = const {},
    this.isPinned = false,
  });

  /// Unique event ID
  final String id;

  /// Room ID this message belongs to
  final String roomId;

  /// Sender's Matrix user ID (@user:server.com)
  final String senderId;

  /// Sender's display name
  final String senderName;

  /// Message text content
  final String content;

  /// When the message was sent
  final DateTime timestamp;

  /// Sender's avatar URL (mxc://)
  final String? senderAvatarUrl;

  /// When the message was edited (null if never edited)
  final DateTime? editedTimestamp;

  /// ID of the message being replied to
  final String? replyToId;

  /// File/media attachments
  final List<Attachment> attachments;

  /// Whether message is only stored locally (not sent to server)
  final bool isLocalOnly;

  /// Users who have read this message
  final List<ReadReceipt> readReceipts;

  /// Reactions on this message (emoji -> count)
  final Map<String, int> reactions;

  /// Whether this message is pinned
  final bool isPinned;

  @override
  List<Object?> get props {
    return [
      id,
      roomId,
      senderId,
      senderName,
      content,
      timestamp,
      senderAvatarUrl,
      editedTimestamp,
      replyToId,
      attachments,
      isLocalOnly,
      readReceipts,
      reactions,
      isPinned,
    ];
  }

  MessageEntity copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    String? senderAvatarUrl,
    DateTime? editedTimestamp,
    String? replyToId,
    List<Attachment>? attachments,
    bool? isLocalOnly,
    List<ReadReceipt>? readReceipts,
    Map<String, int>? reactions,
    bool? isPinned,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      editedTimestamp: editedTimestamp ?? this.editedTimestamp,
      replyToId: replyToId ?? this.replyToId,
      attachments: attachments ?? this.attachments,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
      readReceipts: readReceipts ?? this.readReceipts,
      reactions: reactions ?? this.reactions,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

/// File/media attachment
class Attachment extends Equatable {
  const Attachment({
    required this.id,
    required this.type,
    required this.url,
    required this.name,
    this.size,
    this.mimeType,
    this.thumbnailUrl,
  });

  /// Unique attachment ID
  final String id;

  /// Type of attachment
  final AttachmentType type;

  /// Download URL (mxc:// or HTTP)
  final String url;

  /// File name
  final String name;

  /// File size in bytes
  final int? size;

  /// MIME type
  final String? mimeType;

  /// Thumbnail URL for images/videos
  final String? thumbnailUrl;

  @override
  List<Object?> get props => [id, type, url, name, size, mimeType, thumbnailUrl];
}

/// Attachment types
enum AttachmentType { image, video, audio, file }

/// Read receipt for a message
class ReadReceipt extends Equatable {
  const ReadReceipt({
    required this.userId,
    required this.timestamp,
  });

  /// User ID who read the message
  final String userId;

  /// When the user read the message
  final DateTime timestamp;

  @override
  List<Object> get props => [userId, timestamp];
}

/// Message sending status for local messages
enum MessageStatus {
  /// Message is being sent
  sending,

  /// Message was sent successfully
  sent,

  /// Message failed to send
  failed,

  /// Message has been delivered to server
  delivered,
}
