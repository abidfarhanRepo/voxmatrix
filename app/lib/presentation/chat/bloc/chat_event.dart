import 'package:equatable/equatable.dart';
import 'package:voxmatrix/domain/entities/message_entity.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatEvent {
  const LoadMessages({
    required this.roomId,
    this.limit = 50,
    this.from,
  });

  final String roomId;
  final int limit;
  final String? from;

  @override
  List<Object?> get props => [roomId, limit, from];
}

class SendMessage extends ChatEvent {
  const SendMessage({
    required this.roomId,
    required this.content,
    this.replyToId,
    this.attachments,
    this.messageType,
    this.contentData,
  });

  final String roomId;
  final String content;
  final String? replyToId;
  final List<String>? attachments;
  final String? messageType;
  final Map<String, dynamic>? contentData;

  @override
  List<Object?> get props => [roomId, content, replyToId, attachments, messageType, contentData];
}

class EditMessage extends ChatEvent {
  const EditMessage({
    required this.roomId,
    required this.messageId,
    required this.newContent,
  });

  final String roomId;
  final String messageId;
  final String newContent;

  @override
  List<Object> get props => [roomId, messageId, newContent];
}

class DeleteMessage extends ChatEvent {
  const DeleteMessage({
    required this.roomId,
    required this.messageId,
  });

  final String roomId;
  final String messageId;

  @override
  List<Object> get props => [roomId, messageId];
}

class SendTypingNotification extends ChatEvent {
  const SendTypingNotification({
    required this.roomId,
    this.isTyping = true,
  });

  final String roomId;
  final bool isTyping;

  @override
  List<Object> get props => [roomId, isTyping];
}

class MarkAsRead extends ChatEvent {
  const MarkAsRead({
    required this.roomId,
    required this.messageId,
  });

  final String roomId;
  final String messageId;

  @override
  List<Object> get props => [roomId, messageId];
}

class SubscribeToMessages extends ChatEvent {
  const SubscribeToMessages(this.roomId);

  final String roomId;

  @override
  List<Object> get props => [roomId];
}

class LoadMoreMessages extends ChatEvent {
  const LoadMoreMessages({
    required this.roomId,
    this.limit = 50,
  });

  final String roomId;
  final int limit;

  @override
  List<Object> get props => [roomId, limit];
}

class ProcessOfflineQueue extends ChatEvent {
  const ProcessOfflineQueue();
}

class StartTyping extends ChatEvent {
  const StartTyping(this.roomId);

  final String roomId;

  @override
  List<Object> get props => [roomId];
}

class StopTyping extends ChatEvent {
  const StopTyping(this.roomId);

  final String roomId;

  @override
  List<Object> get props => [roomId];
}

class UploadFile extends ChatEvent {
  const UploadFile({
    required this.roomId,
    required this.filePath,
  });

  final String roomId;
  final String filePath;

  @override
  List<Object?> get props => [roomId, filePath];
}

class SendMediaMessage extends ChatEvent {
  const SendMediaMessage({
    required this.roomId,
    required this.content,
    required this.attachments,
    this.replyToId,
  });

  final String roomId;
  final String content;
  final List<Attachment> attachments;
  final String? replyToId;

  @override
  List<Object?> get props => [roomId, content, attachments, replyToId];
}

class AddReaction extends ChatEvent {
  const AddReaction({
    required this.roomId,
    required this.messageId,
    required this.emoji,
  });

  final String roomId;
  final String messageId;
  final String emoji;

  @override
  List<Object> get props => [roomId, messageId, emoji];
}

class RemoveReaction extends ChatEvent {
  const RemoveReaction({
    required this.roomId,
    required this.reactionEventId,
  });

  final String roomId;
  final String reactionEventId;

  @override
  List<Object> get props => [roomId, reactionEventId];
}
