import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/domain/entities/message_entity.dart';
import 'package:voxmatrix/domain/usecases/chat/add_reaction_usecase.dart';
import 'package:voxmatrix/domain/usecases/chat/delete_message_usecase.dart';
import 'package:voxmatrix/domain/usecases/chat/edit_message_usecase.dart';
import 'package:voxmatrix/domain/usecases/chat/get_messages_usecase.dart';
import 'package:voxmatrix/domain/usecases/chat/mark_as_read_usecase.dart';
import 'package:voxmatrix/domain/usecases/chat/remove_reaction_usecase.dart';
import 'package:voxmatrix/domain/usecases/chat/send_message_usecase.dart';
import 'package:voxmatrix/domain/usecases/chat/subscribe_to_messages_usecase.dart';
import 'package:voxmatrix/domain/usecases/chat/upload_file_usecase.dart';
import 'package:voxmatrix/core/services/matrix_client_service.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'chat_event.dart';
import 'chat_state.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc(
    this._getMessagesUseCase,
    this._sendMessageUseCase,
    this._uploadFileUseCase,
    this._addReactionUseCase,
    this._removeReactionUseCase,
    this._editMessageUseCase,
    this._deleteMessageUseCase,
    this._subscribeToMessagesUseCase,
    this._markAsReadUseCase,
    this._matrixClientService,
    this._authLocalDataSource,
    this._logger,
  ) : super(const ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SubscribeToMessages>(_onSubscribeToMessages);
    on<SendMessage>(_onSendMessage);
    on<EditMessage>(_onEditMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<SendTypingNotification>(_onSendTypingNotification);
    on<MarkAsRead>(_onMarkAsRead);
    on<UploadFile>(_onUploadFile);
    on<SendMediaMessage>(_onSendMediaMessage);
    on<AddReaction>(_onAddReaction);
    on<RemoveReaction>(_onRemoveReaction);
  }

  final GetMessagesUseCase _getMessagesUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final UploadFileUseCase _uploadFileUseCase;
  final AddReactionUseCase _addReactionUseCase;
  final RemoveReactionUseCase _removeReactionUseCase;
  final EditMessageUseCase _editMessageUseCase;
  final DeleteMessageUseCase _deleteMessageUseCase;
  final SubscribeToMessagesUseCase _subscribeToMessagesUseCase;
  final MarkAsReadUseCase _markAsReadUseCase;
  final MatrixClientService _matrixClientService;
  final AuthLocalDataSource _authLocalDataSource;
  final Logger _logger;

  StreamSubscription<Either<Failure, MessageEntity>>? _messageSubscription;
  StreamSubscription? _syncSubscription;
  Timer? _syncDebounce;

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());
    final result = await _getMessagesUseCase(
      roomId: event.roomId,
      limit: event.limit,
      from: event.from,
    );
    result.fold<void>(
      (Failure failure) => emit(ChatError(failure.message)),
      (messages) => emit(ChatLoaded(messages: messages)),
    );
  }

  Future<void> _onSubscribeToMessages(
    SubscribeToMessages event,
    Emitter<ChatState> emit,
  ) async {
    // Load initial messages when subscribing
    add(LoadMessages(roomId: event.roomId));
    
    _logger.d('Subscribing to message stream for room: ${event.roomId}');
    
    // Cancel existing subscription if any
    await _messageSubscription?.cancel();
    
    // Subscribe to real-time stream
    final stream = _subscribeToMessagesUseCase(roomId: event.roomId);
    _messageSubscription = stream.listen(
      (result) {
        result.fold(
          (failure) {
            _logger.e('Error in message stream: ${failure.message}');
            // Don't emit error state for stream errors, just log
          },
          (message) {
            _logger.d('Received new message from stream: ${message.id}');
            
            // Get current messages and add new one
            final currentState = state;
            final List<MessageEntity> currentMessages = currentState is ChatLoaded
                ? currentState.messages
                : [];
            
            // Check if message already exists (avoid duplicates)
            final messageExists = currentMessages.any((m) => m.id == message.id);
            
            if (!messageExists) {
              final updatedMessages = [...currentMessages, message];
              emit(ChatLoaded(messages: updatedMessages));
              _markReadIfNeeded(message, event.roomId);
            }
          },
        );
      },
      onError: (error) {
        _logger.e('Error in message stream subscription', error: error);
      },
    );

    await _subscribeToSync(event.roomId);
  }


  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    _logger.d('SendMessage event received: roomId=${event.roomId}, content="${event.content}"');

    // Get current messages before sending
    final currentState = state;
    final List<MessageEntity> currentMessages = currentState is ChatLoaded
        ? currentState.messages
        : [];

    _logger.d('Current messages count: ${currentMessages.length}');

    // Show sending state with messages preserved
    emit(ChatLoaded(messages: currentMessages));

    final result = await _sendMessageUseCase(
      roomId: event.roomId,
      content: event.content,
      replyToId: event.replyToId,
    );

    result.fold<void>(
      (Failure failure) {
        _logger.e('SendMessage failed: ${failure.message}');
        emit(ChatError(failure.message));
      },
      (message) {
        _logger.d('Message sent successfully: ${message.id}');
        // Add the new message to the list and emit
        emit(ChatLoaded(messages: [...currentMessages, message]));
      },
    );
  }

  Future<void> _onEditMessage(
    EditMessage event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _editMessageUseCase(
      roomId: event.roomId,
      messageId: event.messageId,
      newContent: event.newContent,
    );
    result.fold<void>(
      (Failure failure) => emit(ChatError(failure.message)),
      (message) => emit(ChatMessageEdited(message)),
    );
  }

  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _deleteMessageUseCase(
      roomId: event.roomId,
      messageId: event.messageId,
    );

    result.fold<void>(
      (Failure failure) => emit(ChatError(failure.message)),
      (_) => emit(ChatMessageDeleted(event.messageId)),
    );
  }

  Future<void> _onSendTypingNotification(
    SendTypingNotification event,
    Emitter<ChatState> emit,
  ) async {
    // TODO: Implement typing notification use case
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<ChatState> emit,
  ) async {
    await _markAsReadUseCase(
      roomId: event.roomId,
      messageId: event.messageId,
    );
  }

  Future<void> _subscribeToSync(String roomId) async {
    await _syncSubscription?.cancel();
    _syncDebounce?.cancel();

    if (!_matrixClientService.isInitialized) {
      final accessToken = await _authLocalDataSource.getAccessToken();
      final homeserver = await _authLocalDataSource.getHomeserver();
      final userId = await _authLocalDataSource.getUserId();
      if (accessToken != null && homeserver != null && userId != null && userId.isNotEmpty) {
        try {
          await _matrixClientService.initialize(
            homeserver: homeserver,
            accessToken: accessToken,
            userId: userId,
          );
          await _matrixClientService.startSync();
        } catch (_) {
          return;
        }
      } else {
        return;
      }
    }

    _syncSubscription = _matrixClientService.client.onSync.stream.listen((_) {
      _syncDebounce?.cancel();
      _syncDebounce = Timer(const Duration(milliseconds: 400), () {
        add(LoadMessages(roomId: roomId));
      });
    });
  }

  Future<void> _markReadIfNeeded(MessageEntity message, String roomId) async {
    try {
      final userId = await _authLocalDataSource.getUserId();
      if (userId == null || message.senderId == userId) {
        return;
      }
      add(MarkAsRead(roomId: roomId, messageId: message.id));
    } catch (_) {
      // ignore
    }
  }

  Future<void> _onUploadFile(
    UploadFile event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatUploading());
    final result = await _uploadFileUseCase(
      filePath: event.filePath,
      roomId: event.roomId,
    );
    result.fold<void>(
      (Failure failure) => emit(ChatError(failure.message)),
      (mxcUri) => emit(ChatFileUploaded(mxcUri)),
    );
  }

  Future<void> _onSendMediaMessage(
    SendMediaMessage event,
    Emitter<ChatState> emit,
  ) async {
    // Get current messages before sending
    final currentState = state;
    final List<MessageEntity> currentMessages = currentState is ChatLoaded
        ? currentState.messages
        : [];

    // Show sending state with messages preserved
    emit(ChatLoaded(messages: currentMessages));

    final result = await _sendMessageUseCase(
      roomId: event.roomId,
      content: event.content,
      replyToId: event.replyToId,
      attachments: event.attachments,
    );
    result.fold<void>(
      (Failure failure) => emit(ChatError(failure.message)),
      (message) {
        // Add the new message to the list and emit
        emit(ChatLoaded(messages: [...currentMessages, message]));
      },
    );
  }

  Future<void> _onAddReaction(
    AddReaction event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _addReactionUseCase(
      roomId: event.roomId,
      messageId: event.messageId,
      emoji: event.emoji,
    );
    result.fold<void>(
      (Failure failure) => emit(ChatError(failure.message)),
      (eventId) => emit(ChatReactionAdded(event.messageId, event.emoji)),
    );
  }

  Future<void> _onRemoveReaction(
    RemoveReaction event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _removeReactionUseCase(
      roomId: event.roomId,
      reactionEventId: event.reactionEventId,
    );
    result.fold<void>(
      (Failure failure) => emit(ChatError(failure.message)),
      (_) => emit(ChatReactionRemoved(event.reactionEventId)),
    );
  }

  @override
  Future<void> close() async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    await _syncSubscription?.cancel();
    _syncDebounce?.cancel();
    _logger.d('ChatBloc disposed');
    await super.close();
  }
}
