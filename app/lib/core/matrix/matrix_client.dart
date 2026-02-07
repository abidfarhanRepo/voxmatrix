/// Matrix SDK for VoxMatrix
///
/// This SDK provides a complete implementation of the Matrix Client-Server API
/// with support for:
/// - Synchronization with lazy loading
/// - Room state management
/// - Event handling
/// - End-to-end encryption
/// - File upload/download
/// - Push notifications
///
/// Usage:
/// ```dart
/// final client = MatrixClient(
///   homeserver: 'https://matrix.org',
///   accessToken: 'your_token',
/// );
///
/// // Start synchronization
/// await client.connect();
///
/// // Listen for events
/// client.stream.listen((event) {
///   print('Received: $event');
/// });
///
/// // Send a message
/// await client.sendTextMessage(roomId, 'Hello!');
/// ```
library;

export 'src/matrix_client.dart';
export 'src/models/event.dart';
export 'src/models/room.dart';
export 'src/models/user.dart';
export 'src/sync/sync_controller.dart';
export 'src/sync/sync_stream.dart';
export 'src/room/room_manager.dart';
export 'src/media/media_manager.dart';
export 'src/encryption/encryption_manager.dart';
export 'src/push/push_manager.dart';
export 'src/search/search_manager.dart';
export 'src/receipts/receipt_manager.dart';
export 'src/typing/typing_manager.dart';
export 'src/room/room_creation_manager.dart';
export 'src/presence/presence_manager.dart';
export 'src/account/account_manager.dart';
export 'src/message/message_operations.dart';
export 'src/todevice/todevice_manager.dart';
export 'src/user/profile_manager.dart';
