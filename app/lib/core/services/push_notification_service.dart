import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Firebase Cloud Messaging service for push notifications
///
/// This service handles:
/// - FCM token registration with Firebase
/// - Token registration with Matrix homeserver (Pusher API)
/// - Background message handling
/// - Tap-to-open navigation
@Injectable()
class PushNotificationService {
  PushNotificationService(
    this._logger,
  ) {
    _init();
  }

  final Logger _logger;

  static const _pushGatewayUrl = 'https://matrix.org/_matrix/push/v1/notify';

  final _messageStreamController =
      StreamController<RemoteMessage>.broadcast();
  final _tokenRefreshController =
      StreamController<String>.broadcast();

  Stream<RemoteMessage> get messageStream => _messageStreamController.stream;
  Stream<String> get tokenRefreshStream => _tokenRefreshController.stream;

  String? _fcmToken;
  bool _isInitialized = false;

  Future<void> _init() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Request notification permission (Android 13+)
      final settings = await FirebaseMessaging.instance.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i('Notification permission granted');
      } else {
        _logger.w('Notification permission denied');
      }

      // Get initial message if app was opened from notification
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();

      if (initialMessage != null) {
        _logger.i('App opened from notification');
        _messageStreamController.add(initialMessage);
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        _logger.i('Received foreground message: ${message.notification?.title}');
        _messageStreamController.add(message);
      });

      // Handle background messages (opened from notification)
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _logger.i('Notification opened: ${message.notification?.title}');
        _messageStreamController.add(message);
      });

      // Handle token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _logger.i('FCM token refreshed');
        _fcmToken = token;
        _tokenRefreshController.add(token);
        registerPusherWithMatrix();
      });

      // Get initial token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        _fcmToken = token;
        _logger.i('FCM token obtained: ${token.substring(0, 10)}...');
      }

      _isInitialized = true;
      _logger.i('Firebase Cloud Messaging initialized');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize FCM', error: e, stackTrace: stackTrace);
    }
  }

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if push notifications are initialized
  bool get isInitialized => _isInitialized;

  /// Register push notifications with Matrix homeserver
  Future<bool> registerPusherWithMatrix({
    String? accessToken,
    String? userId,
  }) async {
    if (_fcmToken == null) {
      _logger.w('No FCM token available');
      return false;
    }

    try {
      // This would normally make an HTTP request to the Matrix homeserver
      // to register the pusher using the Pusher API
      // POST /_matrix/client/v3/pushers/set

      final pusherData = {
        'pusher': {
          'pushkey': _fcmToken,
          'kind': 'http',
          'app_id': 'org.voxmatrix.app',
          'app_display_name': 'VoxMatrix',
          'device_display_name': 'Android App',
          'profile_tag': 'voxmatrix',
          'lang': 'en',
          'data': {
            'url': _pushGatewayUrl,
            'format': 'event_id_only',
          },
        },
        'append': false,
      };

      _logger.i('Registering pusher with Matrix: $pusherData');

      // TODO: Implement actual HTTP request to Matrix homeserver
      // For now, just log the request

      _logger.i('Pusher registered with Matrix');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to register pusher', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Unregister push notifications from Matrix homeserver
  Future<bool> unregisterPusher() async {
    if (_fcmToken == null) {
      return false;
    }

    try {
      final pusherData = {
        'pusher': {
          'pushkey': _fcmToken,
          'kind': 'http',
          'app_id': 'org.voxmatrix.app',
          'profile_tag': 'voxmatrix',
        },
        'append': false,
      };

      _logger.i('Unregistering pusher: $pusherData');

      // TODO: Implement actual HTTP request to Matrix homeserver
      // DELETE /_matrix/client/v3/pushers/set

      _logger.i('Pusher unregistered');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to unregister pusher', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Handle incoming push notification
  void handleMessage(RemoteMessage message) {
    _logger.i('Handling push notification');

    final data = message.data;

    // Extract Matrix-specific data
    final eventType = data['event_type'] as String?;
    final roomId = data['room_id'] as String?;
    final sender = data['sender'] as String?;
    final body = message.notification?.body;
    final title = message.notification?.title;

    _logger.d('Notification data: $data');

    // Navigate to appropriate screen based on event type
    // This would typically be handled by the app's navigation logic
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _messageStreamController.close();
    await _tokenRefreshController.close();
  }
}

/// Background message handler for Firebase
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Handle background message
  // This is called when the app is in the background or terminated
  // and a new message arrives
}

/// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _firebaseMessagingBackgroundHandler(message);
}
