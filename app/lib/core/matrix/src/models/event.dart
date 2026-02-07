/// Matrix Event model
///
/// Represents a Matrix event as specified in the Matrix spec
/// See: https://spec.matrix.org/v1.11/client-server-api/#events

import 'dart:convert';

/// Matrix Event class
class MatrixEvent {
  /// Create a new Matrix event
  MatrixEvent({
    required this.type,
    required this.roomId,
    required this.content,
    this.eventId,
    this.senderId,
    this.timestamp,
    this.stateKey,
    this.txnId,
    this.unsigned,
  });

  /// Create a Matrix event from JSON
  factory MatrixEvent.fromJson(Map<String, dynamic> json) {
    return MatrixEvent(
      type: json['type'] as String,
      roomId: json['room_id'] as String? ?? '',
      eventId: json['event_id'] as String?,
      senderId: json['sender'] as String?,
      timestamp: json['origin_server_ts'] as int?,
      stateKey: json['state_key'] as String?,
      content: json['content'] as Map<String, dynamic>? ?? {},
      unsigned: json['unsigned'] as Map<String, dynamic>?,
    );
  }

  /// The event type (e.g., 'm.room.message', 'm.room.member')
  final String type;

  /// The room ID
  final String roomId;

  /// The unique event ID
  final String? eventId;

  /// The sender's user ID
  final String? senderId;

  /// The timestamp when the event was created by the homeserver
  final int? timestamp;

  /// The state key (for state events)
  final String? stateKey;

  /// The event content
  final Map<String, dynamic> content;

  /// The transaction ID (for events sent by the client)
  final String? txnId;

  /// Unsigned data (e.g., age, prev_content)
  final Map<String, dynamic>? unsigned;

  /// Get the event as JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'room_id': roomId,
      if (eventId != null) 'event_id': eventId,
      if (senderId != null) 'sender': senderId,
      if (timestamp != null) 'origin_server_ts': timestamp,
      if (stateKey != null) 'state_key': stateKey,
      'content': content,
      if (txnId != null) 'txn_id': txnId,
      if (unsigned != null) 'unsigned': unsigned,
    };
  }

  /// Get the event content as JSON string
  String get jsonContent => jsonEncode(toJson());

  /// Get the event timestamp as DateTime
  DateTime? get dateTime {
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp!);
  }

  /// Check if this is a state event
  bool get isStateEvent => stateKey != null;

  /// Check if this is a message event
  bool get isMessageEvent => type == 'm.room.message';

  /// Check if this is a membership event
  bool get isMembershipEvent => type == 'm.room.member';

  /// Check if this is a room name event
  bool get isRoomNameEvent => type == 'm.room.name';

  /// Check if this is a room topic event
  bool get isRoomTopicEvent => type == 'm.room.topic';

  /// Check if this is a room avatar event
  bool get isRoomAvatarEvent => type == 'm.room.avatar';

  /// Get the message body if this is a message event
  String? get messageBody {
    if (!isMessageEvent) return null;
    final msgtype = content['msgtype'] as String?;
    if (msgtype == 'm.text') {
      return content['body'] as String?;
    }
    return null;
  }

  /// Get the membership if this is a membership event
  String? get membership {
    if (!isMembershipEvent) return null;
    return content['membership'] as String?;
  }

  /// Get the display name if this is a membership event
  String? get displayName {
    if (!isMembershipEvent) return null;
    return content['displayname'] as String?;
  }

  /// Get the avatar URL if this is a membership event
  String? get avatarUrl {
    if (!isMembershipEvent) return null;
    return content['avatar_url'] as String?;
  }

  /// Get the room name if this is a room name event
  String? get roomName {
    if (!isRoomNameEvent) return null;
    return content['name'] as String?;
  }

  /// Get the room topic if this is a room topic event
  String? get roomTopic {
    if (!isRoomTopicEvent) return null;
    return content['topic'] as String?;
  }

  /// Get the previous content for this event
  Map<String, dynamic>? get prevContent {
    return unsigned?['prev_content'] as Map<String, dynamic>?;
  }

  /// Get the age of this event in milliseconds
  int? get age {
    return unsigned?['age'] as int?;
  }

  /// Create a copy of this event with modified fields
  MatrixEvent copyWith({
    String? type,
    String? roomId,
    String? eventId,
    String? senderId,
    int? timestamp,
    String? stateKey,
    Map<String, dynamic>? content,
    String? txnId,
    Map<String, dynamic>? unsigned,
  }) {
    return MatrixEvent(
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      eventId: eventId ?? this.eventId,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      stateKey: stateKey ?? this.stateKey,
      content: content ?? this.content,
      txnId: txnId ?? this.txnId,
      unsigned: unsigned ?? this.unsigned,
    );
  }

  @override
  String toString() {
    return 'MatrixEvent(type: $type, roomId: $roomId, eventId: $eventId, senderId: $senderId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatrixEvent &&
        other.type == type &&
        other.roomId == roomId &&
        other.eventId == eventId;
  }

  @override
  int get hashCode => Object.hash(type, roomId, eventId);
}

/// Room event with membership information
class RoomEvent extends MatrixEvent {
  /// Create a new room event
  RoomEvent({
    required super.type,
    required super.roomId,
    required super.content,
    super.eventId,
    super.senderId,
    super.timestamp,
    super.stateKey,
    super.txnId,
    super.unsigned,
    this.membership,
    this.prevContent,
  });

  /// Create a RoomEvent from a MatrixEvent
  factory RoomEvent.fromEvent(MatrixEvent event) {
    return RoomEvent(
      type: event.type,
      roomId: event.roomId,
      eventId: event.eventId,
      senderId: event.senderId,
      timestamp: event.timestamp,
      stateKey: event.stateKey,
      content: event.content,
      txnId: event.txnId,
      unsigned: event.unsigned,
      membership: event.membership,
      prevContent: event.prevContent,
    );
  }

  /// The membership state (for membership events)
  final String? membership;

  /// The previous content (for state events)
  final Map<String, dynamic>? prevContent;

  @override
  String toString() {
    return 'RoomEvent(type: $type, roomId: $roomId, membership: $membership)';
  }
}
