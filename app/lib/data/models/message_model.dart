import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/message_entity.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel extends Equatable {
  const MessageModel({
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
  @JsonKey(fromJson: _fromJsonTimestamp, toJson: _toJsonTimestamp)
  final DateTime timestamp;
  final String? senderAvatarUrl;
  @JsonKey(fromJson: _fromJsonTimestamp, toJson: _toJsonTimestampNullable)
  final DateTime? editedTimestamp;
  final String? replyToId;
  final List<AttachmentModel> attachments;
  final bool isLocalOnly;
  final List<String> readReceipts;
  final Map<String, int> reactions;
  final bool isPinned;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: timestamp,
      senderAvatarUrl: senderAvatarUrl,
      editedTimestamp: editedTimestamp,
      replyToId: replyToId,
      attachments: attachments.map((a) => a.toEntity()).toList(),
      isLocalOnly: isLocalOnly,
      readReceipts: readReceipts,
      reactions: reactions,
      isPinned: isPinned,
    );
  }

  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      roomId: entity.roomId,
      senderId: entity.senderId,
      senderName: entity.senderName,
      content: entity.content,
      timestamp: entity.timestamp,
      senderAvatarUrl: entity.senderAvatarUrl,
      editedTimestamp: entity.editedTimestamp,
      replyToId: entity.replyToId,
      attachments: entity.attachments
          .map((a) => AttachmentModel.fromEntity(a))
          .toList(),
      isLocalOnly: entity.isLocalOnly,
      readReceipts: entity.readReceipts,
      reactions: entity.reactions,
      isPinned: entity.isPinned,
    );
  }

  static DateTime _fromJsonTimestamp(int timestamp) =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  static int _toJsonTimestamp(DateTime timestamp) =>
      timestamp.millisecondsSinceEpoch ~/ 1000;

  static int? _toJsonTimestampNullable(DateTime? timestamp) {
    if (timestamp == null) return null;
    return timestamp.millisecondsSinceEpoch ~/ 1000;
  }

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
    ];
  }
}

@JsonSerializable()
class AttachmentModel extends Equatable {
  const AttachmentModel({
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

  factory AttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$AttachmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$AttachmentModelToJson(this);

  Attachment toEntity() {
    return Attachment(
      id: id,
      type: type,
      url: url,
      name: name,
      size: size,
      mimeType: mimeType,
      thumbnailUrl: thumbnailUrl,
    );
  }

  factory AttachmentModel.fromEntity(Attachment entity) {
    return AttachmentModel(
      id: entity.id,
      type: entity.type,
      url: entity.url,
      name: entity.name,
      size: entity.size,
      mimeType: entity.mimeType,
      thumbnailUrl: entity.thumbnailUrl,
    );
  }

  @override
  List<Object?> get props => [id, type, url, name, size, mimeType, thumbnailUrl];
}
