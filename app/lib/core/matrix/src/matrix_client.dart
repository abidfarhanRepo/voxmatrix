/// Core Matrix Client implementation
///
/// This class provides a complete implementation of the Matrix Client-Server API
/// with support for synchronization, room management, and event handling.
///
/// See: https://spec.matrix.org/v1.11/client-server-api/

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/matrix/src/models/event.dart';
import 'package:voxmatrix/core/matrix/src/models/room.dart';
import 'package:voxmatrix/core/matrix/src/models/user.dart';
import 'package:voxmatrix/core/matrix/src/sync/sync_controller.dart';
import 'package:voxmatrix/core/matrix/src/room/room_manager.dart';
import 'package:voxmatrix/core/matrix/src/search/search_manager.dart';
import 'package:voxmatrix/core/matrix/src/media/media_manager.dart';
import 'package:voxmatrix/core/matrix/src/encryption/encryption_manager.dart';
import 'package:voxmatrix/core/matrix/src/push/push_manager.dart';
import 'package:voxmatrix/core/matrix/src/receipts/receipt_manager.dart';
import 'package:voxmatrix/core/matrix/src/typing/typing_manager.dart';
import 'package:voxmatrix/core/matrix/src/room/room_creation_manager.dart';
import 'package:voxmatrix/core/matrix/src/presence/presence_manager.dart';
import 'package:voxmatrix/core/matrix/src/account/account_manager.dart';
import 'package:voxmatrix/core/matrix/src/message/message_operations.dart';
import 'package:voxmatrix/core/matrix/src/todevice/todevice_manager.dart';
import 'package:voxmatrix/core/matrix/src/user/profile_manager.dart';

/// Matrix Client - Main entry point for Matrix operations
class MatrixClient {
  /// Create a new Matrix client
  ///
  /// [homeserver] The Matrix homeserver URL (e.g., 'https://matrix.org')
  /// [accessToken] The access token for authentication
  /// [userId] The user's Matrix ID (optional, will be fetched if not provided)
  /// [deviceId] The device ID (optional)
  /// [logger] Optional logger instance
  MatrixClient({
    required String homeserver,
    required this.accessToken,
    this.userId,
    this.deviceId,
    Logger? logger,
  }) : _logger = logger ?? Logger() {
    // Remove trailing slash from homeserver URL
    _homeserver = homeserver.replaceAll(RegExp(r'/+$'), '');
  }

  /// The Matrix homeserver URL
  String get homeserver => _homeserver;
  late String _homeserver;

  /// The access token for authentication
  final String accessToken;

  /// The user's Matrix ID
  final String? userId;

  /// The device ID
  final String? deviceId;

  /// Logger instance
  final Logger _logger;

  /// Sync controller for handling synchronization
  late final SyncController _syncController;

  /// Room manager for handling room operations
  late final RoomManager _roomManager;

  /// Media manager for handling file upload/download
  late final MediaManager _mediaManager;

  /// Search manager for handling search operations
  late final SearchManager _searchManager;

  /// Encryption manager for handling E2EE
  late final EncryptionManager _encryptionManager;

  /// Push manager for handling push notifications
  late final PushManager _pushManager;

  /// Receipt manager for handling read receipts
  late final ReceiptManager _receiptManager;

  /// Typing manager for handling typing indicators
  late final TypingManager _typingManager;

  /// Room creation manager for room operations
  late final RoomCreationManager _roomCreationManager;

  /// Presence manager for user presence
  late final PresenceManager _presenceManager;

  /// Account data manager for user account data
  late final AccountDataManager _accountDataManager;

  /// Message operations manager for message actions
  late final MessageOperationsManager _messageOperationsManager;

  /// To-device manager for direct device messaging
  late final ToDeviceManager _toDeviceManager;

  /// User profile manager for user profiles
  late final UserProfileManager _userProfileManager;

  /// Event controller for broadcasting Matrix events
  final _eventController = StreamController<MatrixEvent>.broadcast();

  /// Connection state
  MatrixConnectionState _connectionState = MatrixConnectionState.disconnected;

  /// Stream of connection state changes
  final _connectionStateController = StreamController<MatrixConnectionState>.broadcast();

  /// Has the client been disposed
  bool _disposed = false;

  /// Get the current connection state
  MatrixConnectionState get connectionState => _connectionState;

  /// Stream of connection state changes
  Stream<MatrixConnectionState> get connectionStateStream => _connectionStateController.stream;

  /// Stream of Matrix events
  Stream<MatrixEvent> get events => _eventController.stream;

  /// Get the sync controller
  SyncController get syncController => _syncController;

  /// Get the room manager
  RoomManager get roomManager => _roomManager;

  /// Get the media manager
  MediaManager get mediaManager => _mediaManager;

  /// Get the search manager
  SearchManager get searchManager => _searchManager;

  /// Get the encryption manager
  EncryptionManager get encryptionManager => _encryptionManager;

  /// Get the push manager
  PushManager get pushManager => _pushManager;

  /// Get the receipt manager
  ReceiptManager get receiptManager => _receiptManager;

  /// Get the typing manager
  TypingManager get typingManager => _typingManager;

  /// Get the room creation manager
  RoomCreationManager get roomCreationManager => _roomCreationManager;

  /// Get the presence manager
  PresenceManager get presenceManager => _presenceManager;

  /// Get the account data manager
  AccountDataManager get accountDataManager => _accountDataManager;

  /// Get the message operations manager
  MessageOperationsManager get messageOperations => _messageOperationsManager;

  /// Get the to-device manager
  ToDeviceManager get toDeviceManager => _toDeviceManager;

  /// Get the user profile manager
  UserProfileManager get userProfileManager => _userProfileManager;

  /// Set the connection state (internal use)
  void setConnectionState(MatrixConnectionState state) => _setConnectionState(state);

  /// Connect to the Matrix homeserver and start synchronization
  ///
  /// This method will:
  /// 1. Initialize the sync controller
  /// 2. Initialize the room manager
  /// 3. Start the synchronization loop
  /// 4. Begin fetching room state with lazy loading enabled
  ///
  /// Returns the user's Matrix ID if connection is successful
  Future<String> connect() async {
    _logger.i('Connecting to Matrix homeserver: $_homeserver');

    _setConnectionState(MatrixConnectionState.connecting);

    try {
      // Initialize sync controller
      _syncController = SyncController(
        client: this,
        logger: _logger,
      );

      // Initialize room manager
      _roomManager = RoomManager(
        client: this,
        logger: _logger,
      );

      // Initialize media manager
      _mediaManager = MediaManager(
        client: this,
        logger: _logger,
      );

      // Initialize search manager
      _searchManager = SearchManager(
        client: this,
        logger: _logger,
      );

      // Initialize encryption manager
      _encryptionManager = EncryptionManager(
        client: this,
        logger: _logger,
      );

      // Initialize push manager
      _pushManager = PushManager(
        client: this,
        logger: _logger,
      );

      // Initialize receipt manager
      _receiptManager = ReceiptManager(
        client: this,
        logger: _logger,
      );

      // Initialize typing manager
      _typingManager = TypingManager(
        client: this,
        logger: _logger,
      );

      // Initialize room creation manager
      _roomCreationManager = RoomCreationManager(
        client: this,
        logger: _logger,
      );

      // Initialize presence manager
      _presenceManager = PresenceManager(
        client: this,
        logger: _logger,
      );

      // Initialize account data manager
      _accountDataManager = AccountDataManager(
        client: this,
        logger: _logger,
      );

      // Initialize message operations manager
      _messageOperationsManager = MessageOperationsManager(
        client: this,
        logger: _logger,
      );

      // Initialize to-device manager
      _toDeviceManager = ToDeviceManager(
        client: this,
        logger: _logger,
      );

      // Initialize user profile manager
      _userProfileManager = UserProfileManager(
        client: this,
        logger: _logger,
      );

      // Start synchronization
      await _syncController.start();

      _setConnectionState(MatrixConnectionState.connected);

      _logger.i('Connected to Matrix homeserver');

      // Return user ID (either provided or fetched from sync)
      return userId ?? _syncController.userId ?? '';
    } catch (e, stackTrace) {
      _logger.e('Failed to connect to Matrix homeserver', error: e, stackTrace: stackTrace);
      _setConnectionState(MatrixConnectionState.failed);
      rethrow;
    }
  }

  /// Disconnect from the Matrix homeserver
  ///
  /// This will stop synchronization and clean up resources
  Future<void> disconnect() async {
    _logger.i('Disconnecting from Matrix homeserver');

    _setConnectionState(MatrixConnectionState.disconnected);

    await _syncController.stop();
    await _roomManager.dispose();
    await _mediaManager.dispose();
    await _searchManager.dispose();
    await _encryptionManager.dispose();
    await _pushManager.dispose();
    await _receiptManager.dispose();
    await _typingManager.dispose();
    await _roomCreationManager.dispose();
    await _presenceManager.dispose();
    await _accountDataManager.dispose();
    await _messageOperationsManager.dispose();
    await _toDeviceManager.dispose();
    await _userProfileManager.dispose();

    _setConnectionState(MatrixConnectionState.disconnected);
  }

  /// Send a text message to a room
  ///
  /// [roomId] The room ID to send the message to
  /// [text] The message text
  /// [txnId] Optional transaction ID (will be generated if not provided)
  Future<void> sendTextMessage(
    String roomId,
    String text, {
    String? txnId,
  }) async {
    final event = MatrixEvent(
      type: 'm.room.message',
      roomId: roomId,
      content: {
        'msgtype': 'm.text',
        'body': text,
      },
      txnId: txnId ?? generateTxnId(),
    );

    await sendEvent(event);
  }

  /// Send an event to a room
  ///
  /// [event] The event to send
  Future<void> sendEvent(MatrixEvent event) async {
    _logger.d('Sending event to room ${event.roomId}: ${event.type}');

    final url = Uri.parse('$_homeserver/_matrix/client/v3/rooms/${event.roomId}/send/${event.type}/${event.txnId}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: event.jsonContent,
    );

    if (response.statusCode != 200) {
      final error = response.body.isNotEmpty ? response.body : 'Unknown error';
      throw MatrixException('Failed to send event: $error');
    }

    _logger.d('Event sent successfully: ${event.eventId}');
  }

  /// Join a room
  ///
  /// [roomIdOrAlias] The room ID or alias to join
  Future<void> joinRoom(String roomIdOrAlias) async {
    _logger.i('Joining room: $roomIdOrAlias');

    final url = Uri.parse('$_homeserver/_matrix/client/v3/rooms/$roomIdOrAlias/join');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: '{}',
    );

    if (response.statusCode != 200) {
      final error = response.body.isNotEmpty ? response.body : 'Unknown error';
      throw MatrixException('Failed to join room: $error');
    }

    _logger.i('Joined room successfully');
  }

  /// Leave a room
  ///
  /// [roomId] The room ID to leave
  Future<void> leaveRoom(String roomId) async {
    _logger.i('Leaving room: $roomId');

    final url = Uri.parse('$_homeserver/_matrix/client/v3/rooms/$roomId/leave');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: '{}',
    );

    if (response.statusCode != 200) {
      final error = response.body.isNotEmpty ? response.body : 'Unknown error';
      throw MatrixException('Failed to leave room: $error');
    }

    _logger.i('Left room successfully');
  }

  /// Emit a Matrix event to the event stream
  void emitEvent(MatrixEvent event) {
    if (!_disposed) {
      _eventController.add(event);
    }
  }

  /// Generate a unique transaction ID
  String generateTxnId() {
    return 'm${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Dispose of the client and clean up resources
  Future<void> dispose() async {
    if (_disposed) return;

    _disposed = true;

    await disconnect();

    await _eventController.close();
    await _connectionStateController.close();

    _logger.i('Matrix client disposed');
  }

  /// Set the connection state
  void _setConnectionState(MatrixConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      if (!_disposed) {
        _connectionStateController.add(state);
      }
    }
  }

  /// Deprecated: Use [generateTxnId] instead
  String _generateTxnId() => generateTxnId();
}

/// Matrix connection state
enum MatrixConnectionState {
  /// The client is disconnected
  disconnected,

  /// The client is connecting
  connecting,

  /// The client is connected
  connected,

  /// The connection failed
  failed,

  /// The client is syncing
  syncing,

  /// The client is reconnecting (with backoff)
  reconnecting,

  /// The connection is waiting for token
  waitingForToken,
}

/// Matrix exception
class MatrixException implements Exception {
  /// Create a new Matrix exception
  const MatrixException(this.message);

  /// The error message
  final String message;

  @override
  String toString() => 'MatrixException: $message';
}
