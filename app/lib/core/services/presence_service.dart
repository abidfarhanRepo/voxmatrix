import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/services/matrix_client_service.dart';
import 'package:matrix/matrix.dart' as matrix;

/// Service for managing user presence status
@injectable
class PresenceService {
  PresenceService(
    this._matrixClientService,
    this._logger,
  );

  final MatrixClientService _matrixClientService;
  final Logger _logger;

  final Map<String, matrix.PresenceType> _presenceCache = {};
  final _presenceController = StreamController<Map<String, matrix.PresenceType>>.broadcast();
  StreamSubscription? _presenceSubscription;

  /// Stream of presence updates
  Stream<Map<String, matrix.PresenceType>> get presenceStream => _presenceController.stream;

  /// Initialize presence tracking
  Future<void> initialize() async {
    if (!_matrixClientService.isInitialized) {
      _logger.w('Cannot initialize presence - Matrix client not initialized');
      return;
    }

    final client = _matrixClientService.client;

    // Subscribe to presence events
    _presenceSubscription = client.onPresence.stream.listen((presence) {
      _handlePresenceUpdate(presence);
    });

    _logger.i('Presence service initialized');
  }

  /// Get presence for a user
  matrix.PresenceType? getPresence(String userId) {
    if (!_matrixClientService.isInitialized) return null;

    // Return from cache
    return _presenceCache[userId];
  }

  /// Set own presence
  Future<void> setPresence(matrix.PresenceType presence, {String? statusMsg}) async {
    if (!_matrixClientService.isInitialized) {
      _logger.w('Cannot set presence - Matrix client not initialized');
      return;
    }

    try {
      final client = _matrixClientService.client;
      await client.setPresence(
        client.userID!,
        presence,
        statusMsg: statusMsg,
      );
      _logger.d('Presence set to: $presence');
    } catch (e) {
      _logger.e('Failed to set presence', error: e);
    }
  }

  /// Set user as online
  Future<void> setOnline() => setPresence(matrix.PresenceType.online);

  /// Set user as unavailable
  Future<void> setUnavailable() => setPresence(matrix.PresenceType.unavailable);

  /// Set user as offline
  Future<void> setOffline() => setPresence(matrix.PresenceType.offline);

  void _handlePresenceUpdate(matrix.Presence presence) {
    _presenceCache[presence.senderId] = presence.presence.presence;
    _presenceController.add(Map.from(_presenceCache));
    _logger.d('Presence update: ${presence.senderId} -> ${presence.presence.presence}');
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _presenceSubscription?.cancel();
    await _presenceController.close();
  }
}
