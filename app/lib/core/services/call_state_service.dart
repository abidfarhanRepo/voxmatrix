import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:hive/hive.dart';
import 'package:voxmatrix/domain/entities/call.dart';

/// Service for call state persistence and recovery
@injectable
class CallStateService {
  CallStateService(this._logger);

  final Logger _logger;
  static const String _callStateBoxName = 'call_state';
  Box<String>? _stateBox;

  /// Initialize call state persistence
  Future<void> initialize() async {
    try {
      _stateBox = await Hive.openBox<String>(_callStateBoxName);
      _logger.i('Call state service initialized');
    } catch (e) {
      _logger.e('Failed to initialize call state service', error: e);
    }
  }

  /// Save current call state
  Future<void> saveCallState(CallEntity call) async {
    if (_stateBox == null) await initialize();

    try {
      final stateData = {
        'callId': call.callId,
        'roomId': call.roomId,
        'callerId': call.callerId,
        'callerName': call.callerName,
        'calleeId': call.calleeId,
        'calleeName': call.calleeName,
        'isVideoCall': call.isVideoCall,
        'state': call.state.toString(),
        'duration': call.duration?.inMilliseconds,
        'isMuted': call.isMuted,
        'isCameraEnabled': call.isCameraEnabled,
        'isSpeakerEnabled': call.isSpeakerEnabled,
        'direction': call.direction.toString(),
      };

      await _stateBox!.put('current_call', jsonEncode(stateData));
      _logger.d('Call state saved: ${call.callId}');
    } catch (e) {
      _logger.e('Failed to save call state', error: e);
    }
  }

  /// Restore call state
  Future<CallEntity?> restoreCallState() async {
    if (_stateBox == null) await initialize();

    try {
      final stateJson = _stateBox!.get('current_call');
      if (stateJson == null) return null;

      final stateData = jsonDecode(stateJson) as Map<String, dynamic>;
      
      final call = CallEntity(
        callId: stateData['callId'] as String,
        roomId: stateData['roomId'] as String,
        callerId: stateData['callerId'] as String,
        callerName: stateData['callerName'] as String? ?? '',
        calleeId: stateData['calleeId'] as String?,
        calleeName: stateData['calleeName'] as String?,
        isVideoCall: stateData['isVideoCall'] as bool,
        state: _parseCallState(stateData['state'] as String),
        duration: stateData['duration'] != null
            ? Duration(milliseconds: stateData['duration'] as int)
            : null,
        isMuted: stateData['isMuted'] as bool? ?? false,
        isCameraEnabled: stateData['isCameraEnabled'] as bool? ?? true,
        isSpeakerEnabled: stateData['isSpeakerEnabled'] as bool? ?? false,
        direction: _parseDirection(stateData['direction'] as String?),
      );

      _logger.i('Call state restored: ${call.callId}');
      return call;
    } catch (e) {
      _logger.e('Failed to restore call state', error: e);
      return null;
    }
  }

  /// Clear saved call state
  Future<void> clearCallState() async {
    if (_stateBox == null) return;

    try {
      await _stateBox!.delete('current_call');
      _logger.d('Call state cleared');
    } catch (e) {
      _logger.e('Failed to clear call state', error: e);
    }
  }

  /// Check if there's a saved call state
  bool get hasSavedCallState => _stateBox?.containsKey('current_call') ?? false;

  CallState _parseCallState(String stateString) {
    switch (stateString) {
      case 'CallState.initializing':
        return CallState.initializing;
      case 'CallState.incoming':
        return CallState.incoming;
      case 'CallState.outgoing':
        return CallState.outgoing;
      case 'CallState.connecting':
        return CallState.connecting;
      case 'CallState.active':
        return CallState.active;
      case 'CallState.ended':
        return CallState.ended;
      case 'CallState.failed':
        return CallState.failed;
      default:
        return CallState.ended;
    }
  }

  CallDirection _parseDirection(String? directionString) {
    if (directionString == null) return CallDirection.outgoing;
    
    switch (directionString) {
      case 'CallDirection.incoming':
        return CallDirection.incoming;
      case 'CallDirection.outgoing':
        return CallDirection.outgoing;
      default:
        return CallDirection.outgoing;
    }
  }

  Future<void> dispose() async {
    await _stateBox?.close();
  }
}
