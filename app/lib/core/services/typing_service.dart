import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/services/matrix_client_service.dart';

/// Service for managing typing indicators
@injectable
class TypingService {
  TypingService(
    this._matrixClientService,
    this._logger,
  );

  final MatrixClientService _matrixClientService;
  final Logger _logger;

  final Map<String, Set<String>> _typingUsers = {};
  final Map<String, Timer> _typingTimers = {};
  final _typingController = StreamController<Map<String, Set<String>>>.broadcast();

  /// Stream of typing updates per room
  Stream<Map<String, Set<String>>> get typingStream => _typingController.stream;

  /// Send typing notification
  Future<void> sendTyping(String roomId, bool isTyping, {int timeoutMs = 30000}) async {
    if (!_matrixClientService.isInitialized) {
      _logger.w('Cannot send typing - Matrix client not initialized');
      return;
    }

    try {
      final client = _matrixClientService.client;
      await client.setTyping(client.userID!, roomId, isTyping, timeout: timeoutMs);
      _logger.d('Typing notification sent: $roomId -> $isTyping');
    } catch (e) {
      _logger.e('Failed to send typing notification', error: e);
    }
  }

  /// Start typing (with auto-stop after timeout)
  Future<void> startTyping(String roomId) async {
    await sendTyping(roomId, true);

    // Cancel existing timer
    _typingTimers[roomId]?.cancel();

    // Set new timer to automatically stop typing after 30s
    _typingTimers[roomId] = Timer(const Duration(seconds: 30), () {
      stopTyping(roomId);
    });
  }

  /// Stop typing
  Future<void> stopTyping(String roomId) async {
    _typingTimers[roomId]?.cancel();
    _typingTimers.remove(roomId);
    await sendTyping(roomId, false, timeoutMs: 0);
  }

  /// Add typing user to room (called when receiving typing events)
  void addTypingUser(String roomId, String userId) {
    _typingUsers.putIfAbsent(roomId, () => {});
    _typingUsers[roomId]!.add(userId);
    _notifyUpdate();

    // Auto-remove after 30 seconds
    Timer(const Duration(seconds: 30), () {
      removeTypingUser(roomId, userId);
    });
  }

  /// Remove typing user from room
  void removeTypingUser(String roomId, String userId) {
    _typingUsers[roomId]?.remove(userId);
    if (_typingUsers[roomId]?.isEmpty ?? false) {
      _typingUsers.remove(roomId);
    }
    _notifyUpdate();
  }

  /// Get typing users for a room
  Set<String> getTypingUsers(String roomId) {
    return _typingUsers[roomId] ?? {};
  }

  void _notifyUpdate() {
    _typingController.add(Map.from(_typingUsers));
  }

  /// Dispose resources
  Future<void> dispose() async {
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    await _typingController.close();
  }
}
