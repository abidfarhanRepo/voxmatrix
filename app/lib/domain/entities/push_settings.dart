import 'package:equatable/equatable.dart';

/// Push notification settings entity
class PushSettings extends Equatable {
  const PushSettings({
    required this.enabled,
    this.fcmToken,
    this.notifyForAllMessages = false,
    this.notifyForMentions = true,
    this.notifyForKeywords = true,
    this.keywords = const [],
    this.muteUntil,
  });

  final bool enabled;
  final String? fcmToken;
  final bool notifyForAllMessages;
  final bool notifyForMentions;
  final bool notifyForKeywords;
  final List<String> keywords;
  final DateTime? muteUntil;

  PushSettings copyWith({
    bool? enabled,
    String? fcmToken,
    bool? notifyForAllMessages,
    bool? notifyForMentions,
    bool? notifyForKeywords,
    List<String>? keywords,
    DateTime? muteUntil,
  }) {
    return PushSettings(
      enabled: enabled ?? this.enabled,
      fcmToken: fcmToken ?? this.fcmToken,
      notifyForAllMessages: notifyForAllMessages ?? this.notifyForAllMessages,
      notifyForMentions: notifyForMentions ?? this.notifyForMentions,
      notifyForKeywords: notifyForKeywords ?? this.notifyForKeywords,
      keywords: keywords ?? this.keywords,
      muteUntil: muteUntil ?? this.muteUntil,
    );
  }

  /// Check if notifications are currently muted
  bool get isMuted {
    if (muteUntil == null) return false;
    return DateTime.now().isBefore(muteUntil!);
  }

  @override
  List<Object?> get props => [
        enabled,
        fcmToken,
        notifyForAllMessages,
        notifyForMentions,
        notifyForKeywords,
        keywords,
        muteUntil,
      ];
}

/// Push notification type
enum PushNotificationType {
  /// Regular message
  message,

  /// Mention (@username)
  mention,

  /// Keyword match
  keyword,

  /// Invitation to room
  invitation,

  /// Call notification
  call,
}

/// Push notification data received from FCM
class PushNotification extends Equatable {
  const PushNotification({
    required this.type,
    required this.roomId,
    required this.sender,
    this.message,
    this.roomName,
    this.senderAvatar,
  });

  final PushNotificationType type;
  final String roomId;
  final String sender;
  final String? message;
  final String? roomName;
  final String? senderAvatar;

  factory PushNotification.fromMap(Map<String, dynamic> data) {
    // Parse Matrix push notification format
    final roomId = data['room_id'] as String? ?? '';
    final sender = data['sender'] as String? ?? '';
    final type = _parseNotificationType(data);
    final message = data['content']?['body'] as String?;
    final roomName = data['room_name'] as String?;
    final senderAvatar = data['sender_avatar'] as String?;

    return PushNotification(
      type: type,
      roomId: roomId,
      sender: sender,
      message: message,
      roomName: roomName,
      senderAvatar: senderAvatar,
    );
  }

  static PushNotificationType _parseNotificationType(Map<String, dynamic> data) {
    final counts = data['counts'] as Map<String, dynamic>?;
    if (counts != null) {
      if (counts['unread'] as int? ?? 0 > 0) {
        return PushNotificationType.message;
      }
    }
    final eventType = data['event_id'] as String?;
    if (eventType != null && eventType.contains('m.call.invite')) {
      return PushNotificationType.call;
    }
    if (data['type'] == 'm.room.member') {
      return PushNotificationType.invitation;
    }
    return PushNotificationType.message;
  }

  @override
  List<Object?> get props => [type, roomId, sender, message, roomName, senderAvatar];
}
