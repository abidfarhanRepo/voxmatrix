import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:voxmatrix/core/services/matrix_client_service.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/data/datasources/message_remote_datasource.dart';
import 'package:voxmatrix/data/models/message_model.dart';
import 'package:voxmatrix/domain/entities/message_entity.dart';
import 'package:voxmatrix/domain/entities/room.dart';
import 'package:voxmatrix/domain/repositories/chat_repository.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._matrixClientService,
    this._logger,
  );

  final MessageRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final MatrixClientService _matrixClientService;
  final Logger _logger;

  final _messageStreams = <String, StreamController<Either<Failure, MessageEntity>>>{};
  final _typingStreams = <String, StreamController<Either<Failure, List<String>>>>{};
  final _seenEventIds = <String, Set<String>>{};
  Future<bool>? _initFuture;

  Future<_Credentials?> _getCredentials() async {
    try {
      final token = await _localDataSource.getAccessToken();
      final homeserver = await _localDataSource.getHomeserver();
      final userId = await _localDataSource.getUserId();

      if (token == null || homeserver == null || userId == null) {
        return null;
      }

      return _Credentials(
        accessToken: token,
        homeserver: homeserver,
        userId: userId,
      );
    } catch (e) {
      _logger.e('Error getting credentials', error: e);
      return null;
    }
  }

  Future<bool> _ensureMatrixInitialized() async {
    if (_matrixClientService.isInitialized) {
      return true;
    }
    _initFuture ??= () async {
      final creds = await _getCredentials();
      if (creds == null) {
        return false;
      }
      final ok = await _matrixClientService.initialize(
        homeserver: creds.homeserver,
        accessToken: creds.accessToken,
        userId: creds.userId,
      );
      if (ok) {
        await _matrixClientService.startSync();
      }
      return ok;
    }();
    final result = await _initFuture!;
    _initFuture = null;
    return result;
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessages({
    required String roomId,
    int limit = 50,
    String? from,
  }) async {
    if (!_matrixClientService.isInitialized) {
      final ready = await _ensureMatrixInitialized();
      if (!ready) {
        return const Left(ServerFailure(message: 'Matrix client not initialized'));
      }
    }

    try {
      final client = _matrixClientService.client;
      final room = client.getRoomById(roomId);
      if (room == null) {
        return Left(ServerFailure(message: 'Room not found: $roomId'));
      }

      final timeline = await room.getTimeline();
      final events = timeline.events.toList();

      final messages = <MessageEntity>[];
      for (final event in events) {
        final message = await _parseMatrixSdkEvent(event, roomId, client);
        if (message != null) {
          messages.add(message);
        }
      }

      final ordered = messages.reversed.toList();

      return Right(ordered);
    } catch (e, stackTrace) {
      _logger.e('Error loading messages', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to load messages: $e'));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String roomId,
    required String content,
    String? replyToId,
    List<Attachment>? attachments,
  }) async {
    if (!_matrixClientService.isInitialized) {
      final ready = await _ensureMatrixInitialized();
      if (!ready) {
        return const Left(ServerFailure(message: 'Matrix client not initialized'));
      }
    }

    try {
      final client = _matrixClientService.client;
      final room = client.getRoomById(roomId);
      if (room == null) {
        return Left(ServerFailure(message: 'Room not found: $roomId'));
      }

      matrix.Event? replyEvent;
      if (replyToId != null) {
        replyEvent = await room.getEventById(replyToId);
      }

      final eventId = await room.sendTextEvent(
        content,
        inReplyTo: replyEvent,
      );

      return Right(MessageEntity(
        id: eventId ?? '',
        roomId: roomId,
        senderId: client.userID ?? '',
        senderName: client.userID ?? '',
        content: content,
        timestamp: DateTime.now(),
        attachments: attachments ?? [],
      ));
    } catch (e, stackTrace) {
      _logger.e('Error sending message', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to send message: $e'));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> editMessage({
    required String roomId,
    required String messageId,
    required String newContent,
  }) async {
    if (!_matrixClientService.isInitialized) {
      final ready = await _ensureMatrixInitialized();
      if (!ready) {
        return const Left(ServerFailure(message: 'Matrix client not initialized'));
      }
    }

    try {
      final client = _matrixClientService.client;
      final room = client.getRoomById(roomId);
      if (room == null) {
        return Left(ServerFailure(message: 'Room not found: $roomId'));
      }

      final eventId = await room.sendTextEvent(
        newContent,
        editEventId: messageId,
      );

      return Right(MessageEntity(
        id: eventId ?? messageId,
        roomId: roomId,
        senderId: client.userID ?? '',
        senderName: client.userID ?? '',
        content: newContent,
        timestamp: DateTime.now(),
        editedTimestamp: DateTime.now(),
      ));
    } catch (e, stackTrace) {
      _logger.e('Error editing message', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to edit message: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage({
    required String roomId,
    required String messageId,
  }) async {
    if (!_matrixClientService.isInitialized) {
      final ready = await _ensureMatrixInitialized();
      if (!ready) {
        return const Left(ServerFailure(message: 'Matrix client not initialized'));
      }
    }

    try {
      final client = _matrixClientService.client;
      final room = client.getRoomById(roomId);
      if (room == null) {
        return Left(ServerFailure(message: 'Room not found: $roomId'));
      }
      await room.redactEvent(messageId);
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error deleting message', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to delete message: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> addReaction({
    required String roomId,
    required String messageId,
    required String emoji,
  }) async {
    if (!_matrixClientService.isInitialized) {
      final ready = await _ensureMatrixInitialized();
      if (!ready) {
        return const Left(ServerFailure(message: 'Matrix client not initialized'));
      }
    }

    try {
      final client = _matrixClientService.client;
      final room = client.getRoomById(roomId);
      if (room == null) {
        return Left(ServerFailure(message: 'Room not found: $roomId'));
      }
      final eventId = await room.sendReaction(messageId, emoji);
      return Right(eventId ?? '');
    } catch (e, stackTrace) {
      _logger.e('Error adding reaction', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to add reaction: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeReaction({
    required String roomId,
    required String reactionEventId,
  }) async {
    if (!_matrixClientService.isInitialized) {
      final ready = await _ensureMatrixInitialized();
      if (!ready) {
        return const Left(ServerFailure(message: 'Matrix client not initialized'));
      }
    }

    try {
      final client = _matrixClientService.client;
      final room = client.getRoomById(roomId);
      if (room == null) {
        return Left(ServerFailure(message: 'Room not found: $roomId'));
      }
      await room.redactEvent(reactionEventId);
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error removing reaction', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to remove reaction: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadFile({
    required String filePath,
    required String roomId,
  }) async {
    return Left(UnknownFailure(message: 'File upload not implemented yet'));
  }

  @override
  Future<Either<Failure, void>> sendTypingNotification({
    required String roomId,
    bool isTyping = true,
  }) async {
    if (!_matrixClientService.isInitialized) {
      final ready = await _ensureMatrixInitialized();
      if (!ready) {
        return const Left(ServerFailure(message: 'Matrix client not initialized'));
      }
    }

    try {
      final client = _matrixClientService.client;
      final room = client.getRoomById(roomId);
      if (room == null) {
        return Left(ServerFailure(message: 'Room not found: $roomId'));
      }
      await room.setTyping(isTyping);
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error sending typing', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to send typing: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead({
    required String roomId,
    required String messageId,
  }) async {
    if (!_matrixClientService.isInitialized) {
      final ready = await _ensureMatrixInitialized();
      if (!ready) {
        return const Left(ServerFailure(message: 'Matrix client not initialized'));
      }
    }

    try {
      final client = _matrixClientService.client;
      final room = client.getRoomById(roomId);
      if (room == null) {
        return Left(ServerFailure(message: 'Room not found: $roomId'));
      }
      await room.setReadMarker(messageId, mRead: messageId);
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error marking as read', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to mark as read: $e'));
    }
  }

  @override
  Stream<Either<Failure, MessageEntity>> getMessagesStream(String roomId) {
    _logger.d('Creating message stream for room: $roomId');

    if (_messageStreams.containsKey(roomId)) {
      _logger.d('Returning existing stream for room: $roomId');
      return _messageStreams[roomId]!.stream;
    }

    final controller = StreamController<Either<Failure, MessageEntity>>.broadcast();

    if (_matrixClientService.isInitialized) {
      _attachMessageStream(roomId, controller);
    } else {
      _logger.w('Matrix client not initialized, attempting lazy init for room: $roomId');
      _ensureMatrixInitialized().then((ready) {
        if (!ready) {
          controller.add(Left(ServerFailure(message: 'Matrix client not initialized')));
          return;
        }
        _attachMessageStream(roomId, controller);
      });
    }

    _messageStreams[roomId] = controller;
    return controller.stream;
  }

  @override
  Stream<Either<Failure, List<String>>> getTypingUsers(String roomId) {
    _logger.d('Creating typing stream for room: $roomId');

    if (_typingStreams.containsKey(roomId)) {
      return _typingStreams[roomId]!.stream;
    }

    final controller = StreamController<Either<Failure, List<String>>>.broadcast();

    if (_matrixClientService.isInitialized) {
      _attachTypingStream(roomId, controller);
    } else {
      _logger.w('Matrix client not initialized, attempting lazy init for room: $roomId');
      _ensureMatrixInitialized().then((ready) {
        if (!ready) {
          controller.add(Left(ServerFailure(message: 'Matrix client not initialized')));
          return;
        }
        _attachTypingStream(roomId, controller);
      });
    }

    _typingStreams[roomId] = controller;
    return controller.stream;
  }

  void _attachMessageStream(
    String roomId,
    StreamController<Either<Failure, MessageEntity>> controller,
  ) {
    try {
      final client = _matrixClientService.client;
      final seen = _seenEventIds.putIfAbsent(roomId, () => <String>{});

      final subscription = client.onEvent.stream.listen((update) async {
        if (update.roomID != roomId) return;
        if (update.type != matrix.EventUpdateType.timeline &&
            update.type != matrix.EventUpdateType.decryptedTimelineQueue) {
          return;
        }

        final room = client.getRoomById(roomId);
        if (room == null) return;

        Map<String, dynamic> eventJson = update.content;
        final eventType = eventJson['type'] as String?;
        if (eventType == matrix.EventTypes.Encrypted && client.encryptionEnabled) {
          try {
            final event = matrix.Event.fromJson(eventJson, room);
            final decrypted = await client.encryption!.decryptRoomEvent(roomId, event);
            eventJson = decrypted.toJson();
          } catch (e) {
            _logger.w('Failed to decrypt event in room $roomId', error: e);
          }
        }

        final type = eventJson['type'] as String?;
        if (type != matrix.EventTypes.Message) return;

        final eventId = eventJson['event_id'] as String?;
        if (eventId == null || seen.contains(eventId)) return;
        seen.add(eventId);

        final message = _parseMatrixSdkContent(eventJson, roomId);
        if (message != null) {
          controller.add(Right(message));
        }
      }, onError: (error) {
        _logger.e('Error in message stream for room $roomId', error: error);
        controller.add(Left(ServerFailure(message: error.toString())));
      });

      controller.onCancel = () {
        subscription.cancel();
        _messageStreams.remove(roomId);
        _seenEventIds.remove(roomId);
      };
    } catch (e) {
      _logger.e('Failed to create message stream for room $roomId', error: e);
      controller.add(Left(ServerFailure(message: 'Failed to create stream: $e')));
    }
  }

  void _attachTypingStream(
    String roomId,
    StreamController<Either<Failure, List<String>>> controller,
  ) {
    try {
      final client = _matrixClientService.client;
      final subscription = client.onEvent.stream.listen((update) {
        if (update.roomID != roomId) return;
        if (update.type != matrix.EventUpdateType.ephemeral) return;

        final type = update.content['type'] as String?;
        if (type != 'm.typing') return;

        final content = update.content['content'] as Map<String, dynamic>? ?? {};
        final userIds = (content['user_ids'] as List?)?.cast<String>() ?? [];
        controller.add(Right(userIds));
      }, onError: (error) {
        _logger.e('Error in typing stream for room $roomId', error: error);
        controller.add(Left(ServerFailure(message: error.toString())));
      });

      controller.onCancel = () {
        subscription.cancel();
        _typingStreams.remove(roomId);
      };
    } catch (e) {
      _logger.e('Failed to create typing stream for room $roomId', error: e);
      controller.add(Left(ServerFailure(message: 'Failed to create stream')));
    }
  }

  Future<MessageEntity?> _parseMatrixSdkEvent(
    matrix.Event event,
    String roomId,
    matrix.Client client,
  ) async {
    if (event.type == matrix.EventTypes.Encrypted && client.encryptionEnabled) {
      try {
        final decrypted = await client.encryption!.decryptRoomEvent(roomId, event);
        return _parseMatrixSdkContent(decrypted.toJson(), roomId);
      } catch (e) {
        _logger.w('Failed to decrypt event in room $roomId', error: e);
        return _parseMatrixSdkContent(event.toJson(), roomId);
      }
    }
    return _parseMatrixSdkContent(event.toJson(), roomId);
  }

  MessageEntity? _parseMatrixSdkContent(Map<String, dynamic> event, String roomId) {
    try {
      final content = event['content'] as Map<String, dynamic>?;
      if (content == null) return null;

      final msgType = content['msgtype'] as String?;
      final messageContent = content['body'] as String? ?? '';

      String formattedContent;
      switch (msgType) {
        case 'm.emote':
          formattedContent = '* $messageContent';
          break;
        case 'm.image':
          formattedContent = 'Image';
          break;
        case 'm.video':
          formattedContent = 'Video';
          break;
        case 'm.audio':
          formattedContent = 'Audio';
          break;
        case 'm.file':
          formattedContent = 'File';
          break;
        default:
          formattedContent = messageContent;
      }

      return MessageEntity(
        id: event['event_id'] as String? ?? '',
        roomId: roomId,
        senderId: event['sender'] as String? ?? '',
        senderName: event['sender'] as String? ?? '',
        content: formattedContent,
        timestamp: event['origin_server_ts'] != null
            ? DateTime.fromMillisecondsSinceEpoch(event['origin_server_ts'] as int)
            : DateTime.now(),
        editedTimestamp: null,
        replyToId: null,
        attachments: [],
      );
    } catch (e) {
      _logger.e('Error parsing Matrix SDK event', error: e);
      return null;
    }
  }
}

class _Credentials {
  const _Credentials({
    required this.accessToken,
    required this.homeserver,
    required this.userId,
  });

  final String accessToken;
  final String homeserver;
  final String userId;
}
