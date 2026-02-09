import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/core/services/upload_progress_service.dart';
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
import 'package:voxmatrix/core/services/typing_service.dart';
import 'package:voxmatrix/core/services/offline_queue_service.dart';
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
    this._typingService,
    this._offlineQueueService,
    this._uploadProgressService,
    this._logger,
  ) : super(const ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SubscribeToMessages>(_onSubscribeToMessages);
    on<SendMessage>(_onSendMessage);
    on<EditMessage>(_onEditMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<SendTypingNotification>(_onSendTypingNotification);
    on<StartTyping>(_onStartTyping);
    on<StopTyping>(_onStopTyping);
    on<MarkAsRead>(_onMarkAsRead);
    on<UploadFile>(_onUploadFile);
    on<SendMediaMessage>(_onSendMediaMessage);
    on<AddReaction>(_onAddReaction);
    on<RemoveReaction>(_onRemoveReaction);
    on<ProcessOfflineQueue>(_onProcessOfflineQueue);
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
  final TypingService _typingService;
  final OfflineQueueService _offlineQueueService;
  final UploadProgressService _uploadProgressService;
  final Logger _logger;

  StreamSubscription<Either<Failure, MessageEntity>>? _messageSubscription;
  StreamSubscription? _syncSubscription;
  StreamSubscription? _uploadProgressSubscription;
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
    
    // Extract filename from path
    final fileName = event.filePath.split('/').last;
    final uploadId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Start tracking upload (simulated total bytes - would get from file in production)
    _uploadProgressService.startUpload(uploadId, fileName, 1024 * 1024); // Assume 1MB for now
    
    // Listen to progress updates
    _uploadProgressSubscription?.cancel();
    _uploadProgressSubscription = _uploadProgressService.progressStream.listen(
      (uploadsMap) {
        final progress = uploadsMap[uploadId];
        if (progress != null && progress.status == UploadStatus.uploading) {
          emit(ChatUploadProgress(
            uploadId: uploadId,
            fileName: fileName,
            progress: progress.progress,
            bytesUploaded: progress.uploadedBytes,
            totalBytes: progress.totalBytes,
          ));
        }
      },
    );
    
    // Simulate progress updates (since repository doesn't provide callbacks yet)
    _simulateProgress(uploadId);
    
    final result = await _uploadFileUseCase(
      filePath: event.filePath,
      roomId: event.roomId,
    );
    
    _uploadProgressSubscription?.cancel();
    
    result.fold<void>(
      (Failure failure) {
        _uploadProgressService.failUpload(uploadId, failure.message);
        emit(ChatError(failure.message));
      },
      (mxcUri) {
        _uploadProgressService.completeUpload(uploadId, mxcUri);
        emit(ChatFileUploaded(mxcUri));
      },
    );
  }
  
  void _simulateProgress(String uploadId) {
    // Simulate progress updates until completion
    // This is a workaround until we have real progress callbacks from the repository
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      final progress = _uploadProgressService.getProgress(uploadId);
      if (progress == null || progress.status != UploadStatus.uploading) {
        timer.cancel();
        return;
      }
      
      // Simulate incremental progress
      final newBytes = progress.uploadedBytes + 8192; // Simulate 8KB chunks
      if (newBytes < progress.totalBytes) {
        _uploadProgressService.updateProgress(uploadId, newBytes);
      }
      
      if (progress.percentComplete >= 95) {
        timer.cancel();
      }
    });
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
    await _uploadProgressSubscription?.cancel();
    _syncDebounce?.cancel();
    _logger.d('ChatBloc disposed');
    await super.close();
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded || currentState.hasReachedMax) {
      return;
    }

    final oldestMessage = currentState.messages.firstOrNull;
    if (oldestMessage == null) return;

    final result = await _getMessagesUseCase(
      roomId: event.roomId,
      limit: event.limit,
      from: oldestMessage.id,
    );

    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (newMessages) {
        if (newMessages.isEmpty) {
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          emit(ChatLoaded(
            messages: [...newMessages, ...currentState.messages],
            hasReachedMax: newMessages.length < event.limit,
          ));
        }
      },
    );
  }

  Future<void> _onStartTyping(
    StartTyping event,
    Emitter<ChatState> emit,
  ) async {
    await _typingService.startTyping(event.roomId);
  }

  Future<void> _onStopTyping(
    StopTyping event,
    Emitter<ChatState> emit,
  ) async {
    await _typingService.stopTyping(event.roomId);
  }

  Future<void> _onProcessOfflineQueue(
    ProcessOfflineQueue event,
    Emitter<ChatState> emit,
  ) async {
    if (!_matrixClientService.isInitialized) {
      _logger.w('Cannot process offline queue - Matrix client not initialized');
      return;
    }

    final queuedMessages = await _offlineQueueService.getQueuedMessages();
    _logger.i('Processing ${queuedMessages.length} queued messages');

    for (final messageData in queuedMessages) {
      try {
        final result = await _sendMessageUseCase(
          roomId: messageData['roomId'] as String,
          content: messageData['content'] as String,
          replyToId: messageData['replyToId'] as String?,
        );

        result.fold(
          (failure) {
            _logger.e('Failed to send queued message: ${failure.message}');
          },
          (message) {
            _offlineQueueService.removeMessage(messageData['id'] as String);
            _logger.i('Queued message sent successfully');
          },
        );
      } catch (e) {
        _logger.e('Error processing queued message', error: e);
      }
    }
  }
}
