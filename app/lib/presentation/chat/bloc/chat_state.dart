import 'package:equatable/equatable.dart';
import 'package:voxmatrix/domain/entities/message_entity.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  const ChatLoaded({
    required this.messages,
    this.hasReachedMax = false,
  });

  final List<MessageEntity> messages;
  final bool hasReachedMax;

  @override
  List<Object> get props => [messages, hasReachedMax];

  ChatLoaded copyWith({
    List<MessageEntity>? messages,
    bool? hasReachedMax,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class ChatSending extends ChatState {
  const ChatSending();
}

class ChatMessageSent extends ChatState {
  const ChatMessageSent(this.message);

  final MessageEntity message;

  @override
  List<Object> get props => [message];
}

class ChatError extends ChatState {
  const ChatError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}

class ChatTypingUsersUpdated extends ChatState {
  const ChatTypingUsersUpdated(this.userIds);

  final List<String> userIds;

  @override
  List<Object> get props => [userIds];
}

class ChatUploading extends ChatState {
  const ChatUploading();
}

class ChatFileUploaded extends ChatState {
  const ChatFileUploaded(this.mxcUri);

  final String mxcUri;

  @override
  List<Object> get props => [mxcUri];
}

class ChatReactionAdded extends ChatState {
  const ChatReactionAdded(this.messageId, this.emoji);

  final String messageId;
  final String emoji;

  @override
  List<Object> get props => [messageId, emoji];
}

class ChatReactionRemoved extends ChatState {
  const ChatReactionRemoved(this.reactionEventId);

  final String reactionEventId;

  @override
  List<Object> get props => [reactionEventId];
}

class ChatMessageEdited extends ChatState {
  const ChatMessageEdited(this.message);

  final MessageEntity message;

  @override
  List<Object> get props => [message];
}

class ChatMessageDeleted extends ChatState {
  const ChatMessageDeleted(this.messageId);

  final String messageId;

  @override
  List<Object> get props => [messageId];
}
