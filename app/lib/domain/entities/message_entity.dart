import 'package:equatable/equatable.dart';

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

  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String? senderAvatarUrl;
  final DateTime? editedTimestamp;
  final String? replyToId;
  final List<Attachment> attachments;
  final bool isLocalOnly;
  final List<String> readReceipts;
  final Map<String, int> reactions;
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
    List<String>? readReceipts,
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

  final String id;
  final AttachmentType type;
  final String url;
  final String name;
  final int? size;
  final String? mimeType;
  final String? thumbnailUrl;

  @override
  List<Object?> get props => [id, type, url, name, size, mimeType, thumbnailUrl];
}

enum AttachmentType { image, video, audio, file }
