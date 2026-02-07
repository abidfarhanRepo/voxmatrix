import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/config/injection_container.dart';
import 'package:voxmatrix/core/services/matrix_client_service.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/domain/entities/call.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart' as matrix;

/// Matrix Call Signaling DataSource
/// 
/// Handles the Matrix signaling protocol for WebRTC calls:
/// - Sending call invites via Matrix events
/// - Receiving call events from sync
/// - Exchanging SDP offers/answers
/// - ICE candidate handling
@injectable
class MatrixCallSignalingDataSource {
  MatrixCallSignalingDataSource(
    this._authLocalDataSource,
    this._logger,
  );

  final AuthLocalDataSource _authLocalDataSource;
  final Logger _logger;

  String? _homeserver;
  String? _accessToken;

  // Stream controllers for incoming call events
  final _incomingCallController = StreamController<MatrixCallEvent>.broadcast();
  final _callAnswerController = StreamController<MatrixCallEvent>.broadcast();
  final _callHangupController = StreamController<MatrixCallEvent>.broadcast();
  final _iceCandidatesController = StreamController<MatrixCallEvent>.broadcast();
  StreamSubscription<matrix.EventUpdate>? _eventSubscription;

  /// Get incoming call stream
  Stream<MatrixCallEvent> get incomingCalls => _incomingCallController.stream;

  /// Get call answer stream
  Stream<MatrixCallEvent> get callAnswers => _callAnswerController.stream;

  /// Get call hangup stream
  Stream<MatrixCallEvent> get callHangups => _callHangupController.stream;

  /// Get ICE candidates stream
  Stream<MatrixCallEvent> get iceCandidates => _iceCandidatesController.stream;

  /// Initialize the signaling
  Future<void> initialize() async {
    _logger.i('Initializing Matrix call signaling');
    
    // Get credentials
    final serverUrl = await _authLocalDataSource.getHomeserver();
    final token = await _authLocalDataSource.getAccessToken();
    
    if (serverUrl == null || token == null) {
      throw AuthException(message: 'Not authenticated');
    }
    
    _homeserver = serverUrl;
    _accessToken = token;
    
    _attachToMatrixClient();

    _logger.i('Matrix call signaling initialized');
  }

  void _attachToMatrixClient() {
    try {
      final matrixService = sl<MatrixClientService>();
      if (!matrixService.isInitialized) {
        _logger.w('Matrix client not initialized yet; call events will not be received');
        return;
      }

      _eventSubscription = matrixService.client.onEvent.stream.listen((update) {
        final type = update.content['type'] as String?;
        if (type == null || !type.startsWith('m.call.')) return;
        processCallEvent(update.roomID, update.content);
      });
    } catch (e, stackTrace) {
      _logger.e('Failed to attach to Matrix client events', error: e, stackTrace: stackTrace);
    }
  }

  /// Send a call invite
  /// 
  /// [roomId] - The Matrix room ID
  /// [callId] - Unique call identifier
  /// [calleeId] - The user ID of the callee
  /// [isVideoCall] - Whether this is a video call
  /// [sdpOffer] - WebRTC SDP offer
  Future<void> sendInvite({
    required String roomId,
    required String callId,
    required String calleeId,
    required bool isVideoCall,
    required String sdpOffer,
  }) async {
    try {
      _logger.i('Sending call invite to room: $roomId, call: $callId');

      final url = Uri.parse(
        '$_homeserver/_matrix/client/v3/rooms/$roomId/send/m.call.invite/${DateTime.now().millisecondsSinceEpoch}'
      );

      final content = {
        'call_id': callId,
        'version': '1',
        'lifetime': 60000, // 60 seconds timeout
        'offer': {
          'type': 'offer',
          'sdp': sdpOffer,
        },
        'call_type': isVideoCall ? 'video' : 'audio',
        'invitee': calleeId,
      };

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode(content),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to send call invite: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      _logger.i('Call invite sent successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to send call invite', error: e, stackTrace: stackTrace);
      throw WebRTCException(message: 'Failed to send invite: $e');
    }
  }

  /// Send a call answer
  Future<void> sendAnswer({
    required String roomId,
    required String callId,
    required String sdpAnswer,
  }) async {
    try {
      _logger.i('Sending call answer for call: $callId');

      final url = Uri.parse(
        '$_homeserver/_matrix/client/v3/rooms/$roomId/send/m.call.answer/${DateTime.now().millisecondsSinceEpoch}'
      );

      final content = {
        'call_id': callId,
        'version': '1',
        'answer': {
          'type': 'answer',
          'sdp': sdpAnswer,
        },
      };

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode(content),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to send call answer: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      _logger.i('Call answer sent successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to send call answer', error: e, stackTrace: stackTrace);
      throw WebRTCException(message: 'Failed to send answer: $e');
    }
  }

  /// Send call hangup
  Future<void> sendHangup({
    required String roomId,
    required String callId,
    String reason = 'user_hangup',
  }) async {
    try {
      _logger.i('Sending call hangup for call: $callId');

      final url = Uri.parse(
        '$_homeserver/_matrix/client/v3/rooms/$roomId/send/m.call.hangup/${DateTime.now().millisecondsSinceEpoch}'
      );

      final content = {
        'call_id': callId,
        'version': '1',
        'reason': reason,
      };

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode(content),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to send hangup: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      _logger.i('Call hangup sent successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to send hangup', error: e, stackTrace: stackTrace);
      throw WebRTCException(message: 'Failed to send hangup: $e');
    }
  }

  /// Send ICE candidates
  Future<void> sendIceCandidates({
    required String roomId,
    required String callId,
    required List<IceCandidate> candidates,
  }) async {
    try {
      _logger.i('Sending ${candidates.length} ICE candidates');

      final url = Uri.parse(
        '$_homeserver/_matrix/client/v3/rooms/$roomId/send/m.call.candidates/${DateTime.now().millisecondsSinceEpoch}'
      );

      final content = {
        'call_id': callId,
        'version': '1',
        'candidates': candidates.map((c) => c.toJson()).toList(),
      };

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode(content),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to send ICE candidates: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      _logger.d('ICE candidates sent successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to send ICE candidates', error: e, stackTrace: stackTrace);
      throw WebRTCException(message: 'Failed to send ICE candidates: $e');
    }
  }

  /// Process an incoming Matrix call event
  void processCallEvent(String roomId, Map<String, dynamic> event) {
    try {
      final eventType = event['type'] as String?;
      final content = event['content'] as Map<String, dynamic>?;
      
      if (content == null) return;

      final callId = content['call_id'] as String?;
      final sender = event['sender'] as String?;

      if (callId == null || sender == null) {
        _logger.w('Invalid call event: missing call_id or sender');
        return;
      }

      _logger.d('Processing call event: $eventType from $sender');

      switch (eventType) {
        case 'm.call.invite':
          _handleInviteEvent(roomId, sender, callId, content);
          break;
        case 'm.call.answer':
          _handleAnswerEvent(roomId, sender, callId, content);
          break;
        case 'm.call.hangup':
          _handleHangupEvent(roomId, sender, callId, content);
          break;
        case 'm.call.candidates':
          _handleCandidatesEvent(roomId, sender, callId, content);
          break;
        default:
          _logger.d('Unknown call event type: $eventType');
      }
    } catch (e, stackTrace) {
      _logger.e('Error processing call event', error: e, stackTrace: stackTrace);
    }
  }

  void _handleInviteEvent(String roomId, String sender, String callId, Map<String, dynamic> content) {
    try {
      final offer = content['offer'] as Map<String, dynamic>?;
      final sdp = offer?['sdp'] as String?;
      
      if (sdp == null) {
        _logger.w('Call invite missing SDP');
        return;
      }

      final callType = content['call_type'] as String? ?? 'audio';

      final callEvent = MatrixCallEvent(
        type: MatrixCallEventType.invite,
        callId: callId,
        roomId: roomId,
        senderId: sender,
        sdpOffer: sdp,
        isVideoCall: callType == 'video',
        timeout: content['lifetime'] as int? ?? 60000,
      );

      _logger.i('Incoming call from $sender: $callId');
      _incomingCallController.add(callEvent);
    } catch (e) {
      _logger.e('Error handling invite event', error: e);
    }
  }

  void _handleAnswerEvent(String roomId, String sender, String callId, Map<String, dynamic> content) {
    try {
      final answer = content['answer'] as Map<String, dynamic>?;
      final sdp = answer?['sdp'] as String?;

      final callEvent = MatrixCallEvent(
        type: MatrixCallEventType.answer,
        callId: callId,
        roomId: roomId,
        senderId: sender,
        sdpAnswer: sdp,
      );

      _logger.i('Call answered by $sender: $callId');
      _callAnswerController.add(callEvent);
    } catch (e) {
      _logger.e('Error handling answer event', error: e);
    }
  }

  void _handleHangupEvent(String roomId, String sender, String callId, Map<String, dynamic> content) {
    try {
      final callEvent = MatrixCallEvent(
        type: MatrixCallEventType.hangup,
        callId: callId,
        roomId: roomId,
        senderId: sender,
      );

      _logger.i('Call hung up by $sender: $callId');
      _callHangupController.add(callEvent);
    } catch (e) {
      _logger.e('Error handling hangup event', error: e);
    }
  }

  void _handleCandidatesEvent(String roomId, String sender, String callId, Map<String, dynamic> content) {
    try {
      final candidatesData = content['candidates'] as List? ?? [];
      final candidates = candidatesData
          .map((c) => IceCandidate.fromJson(c as Map<String, dynamic>))
          .toList();

      final callEvent = MatrixCallEvent(
        type: MatrixCallEventType.candidates,
        callId: callId,
        roomId: roomId,
        senderId: sender,
        candidates: candidatesData.cast<Map<String, dynamic>>(),
      );

      _logger.d('Received ${candidates.length} ICE candidates from $sender');
      _iceCandidatesController.add(callEvent);
    } catch (e) {
      _logger.e('Error handling candidates event', error: e);
    }
  }

  /// Dispose and cleanup
  void dispose() {
    _logger.i('Disposing Matrix call signaling');
    _eventSubscription?.cancel();
    _incomingCallController.close();
    _callAnswerController.close();
    _callHangupController.close();
    _iceCandidatesController.close();
  }
}
