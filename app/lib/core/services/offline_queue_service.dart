import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:hive/hive.dart';
import 'package:voxmatrix/domain/entities/message_entity.dart';

/// Service for offline message queue
@injectable
class OfflineQueueService {
  OfflineQueueService(this._logger);

  final Logger _logger;
  static const String _queueBoxName = 'offline_message_queue';
  Box<String>? _queueBox;

  /// Initialize the offline queue
  Future<void> initialize() async {
    try {
      _queueBox = await Hive.openBox<String>(_queueBoxName);
      _logger.i('Offline queue initialized with ${_queueBox!.length} pending messages');
    } catch (e) {
      _logger.e('Failed to initialize offline queue', error: e);
    }
  }

  /// Queue a message for sending when online
  Future<void> queueMessage({
    required String roomId,
    required String content,
    String? replyToId,
    String? messageType,
    Map<String, dynamic>? contentData,
  }) async {
    if (_queueBox == null) {
      await initialize();
    }

    try {
      final messageData = {
        'roomId': roomId,
        'content': content,
        'replyToId': replyToId,
        'messageType': messageType ?? 'm.text',
        'contentData': contentData,
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      await _queueBox!.add(jsonEncode(messageData));
      _logger.i('Message queued for offline delivery: $roomId');
    } catch (e) {
      _logger.e('Failed to queue message', error: e);
    }
  }

  /// Get all queued messages
  Future<List<Map<String, dynamic>>> getQueuedMessages() async {
    if (_queueBox == null) {
      await initialize();
    }

    final messages = <Map<String, dynamic>>[];
    for (var i = 0; i < _queueBox!.length; i++) {
      try {
        final data = _queueBox!.getAt(i);
        if (data != null) {
          messages.add(jsonDecode(data) as Map<String, dynamic>);
        }
      } catch (e) {
        _logger.e('Failed to decode queued message', error: e);
      }
    }
    return messages;
  }

  /// Remove a message from the queue
  Future<void> removeMessage(String messageId) async {
    if (_queueBox == null) return;

    try {
      for (var i = 0; i < _queueBox!.length; i++) {
        final data = _queueBox!.getAt(i);
        if (data != null) {
          final message = jsonDecode(data) as Map<String, dynamic>;
          if (message['id'] == messageId) {
            await _queueBox!.deleteAt(i);
            _logger.d('Removed message from queue: $messageId');
            break;
          }
        }
      }
    } catch (e) {
      _logger.e('Failed to remove queued message', error: e);
    }
  }

  /// Clear all queued messages
  Future<void> clearQueue() async {
    if (_queueBox == null) return;

    try {
      await _queueBox!.clear();
      _logger.i('Offline queue cleared');
    } catch (e) {
      _logger.e('Failed to clear queue', error: e);
    }
  }

  /// Check if there are queued messages
  bool get hasQueuedMessages => _queueBox?.isNotEmpty ?? false;

  /// Get number of queued messages
  int get queuedMessageCount => _queueBox?.length ?? 0;

  /// Dispose resources
  Future<void> dispose() async {
    await _queueBox?.close();
  }
}
