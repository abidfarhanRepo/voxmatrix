/// Room Creation Manager for Matrix room operations
///
/// Handles creating rooms, inviting users, and managing room settings
/// See: https://spec.matrix.org/v1.11/client-server-api/#post_matrixclientv3createroom

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/matrix/src/matrix_client.dart';

/// Room Creation Manager
class RoomCreationManager {
  /// Create a new room creation manager
  RoomCreationManager({
    required this.client,
    required Logger logger,
  }) : _logger = logger;

  /// The Matrix client
  final MatrixClient client;

  /// Logger instance
  final Logger _logger;

  /// Create a new room
  ///
  /// [name] Optional room name
  /// [topic] Optional room topic
  /// [isPublic] Whether the room is publicly visible (default: false)
  /// [isDirect] Whether this is a direct message room (default: false)
  /// [invite] List of user IDs to invite
  /// [preset] Room preset (private_chat, public_chat, trusted_private_chat)
  /// [alias] Optional room alias (local part only, e.g., 'myroom')
  /// [avatarUrl] Optional room avatar URL
  /// [historyVisibility] Who can see history (invited, joined, shared, world_readable)
  /// [guestAccess] Whether guests can join (can_join, forbidden)
  Future<CreateRoomResponse> createRoom({
    String? name,
    String? topic,
    bool isPublic = false,
    bool isDirect = false,
    List<String>? invite,
    String? preset,
    String? alias,
    String? avatarUrl,
    String? historyVisibility,
    String? guestAccess,
  }) async {
    _logger.i('Creating room${name != null ? ": $name" : ""}');

    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/createRoom');

    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (topic != null) 'topic': topic,
      'visibility': isPublic ? 'public' : 'private',
      if (isDirect) 'is_direct': true,
      if (invite != null && invite.isNotEmpty) 'invite': invite,
      'preset': preset ??
          (isPublic
              ? 'public_chat'
              : (isDirect ? 'trusted_private_chat' : 'private_chat')),
      if (alias != null) 'room_alias_name': alias,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (historyVisibility != null)
        'history_visibility': historyVisibility,
      if (guestAccess != null) 'guest_access': guestAccess,
      'initial_state': [
        {
          'type': 'm.room.guest_access',
          'state_key': '',
          'content': {
            'guest_access': guestAccess ?? (isPublic ? 'can_join' : 'forbidden'),
          },
        },
      ],
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final roomId = data['room_id'] as String?;
      if (roomId != null) {
        _logger.i('Room created successfully: $roomId');
        return CreateRoomResponse.fromJson(data);
      } else {
        throw MatrixException('Room creation failed: No room ID in response');
      }
    } else {
      final error = response.body.isNotEmpty ? response.body : 'Unknown error';
      throw MatrixException('Failed to create room: $error');
    }
  }

  /// Invite a user to a room
  ///
  /// [roomId] The room ID
  /// [userId] The user ID to invite
  Future<void> inviteUser(String roomId, String userId) async {
    _logger.i('Inviting user $userId to room $roomId');

    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/rooms/$roomId/invite');

    final body = jsonEncode({
      'user_id': userId,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final error = response.body.isNotEmpty ? response.body : 'Unknown error';
      throw MatrixException('Failed to invite user: $error');
    }

    _logger.i('User invited successfully');
  }

  /// Kick a user from a room
  ///
  /// [roomId] The room ID
  /// [userId] The user ID to kick
  /// [reason] Optional reason for the kick
  Future<void> kickUser(String roomId, String userId, {String? reason}) async {
    _logger.i('Kicking user $userId from room $roomId');

    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/rooms/$roomId/kick');

    final body = jsonEncode({
      'user_id': userId,
      if (reason != null) 'reason': reason,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final error = response.body.isNotEmpty ? response.body : 'Unknown error';
      throw MatrixException('Failed to kick user: $error');
    }

    _logger.i('User kicked successfully');
  }

  /// Ban a user from a room
  ///
  /// [roomId] The room ID
  /// [userId] The user ID to ban
  /// [reason] Optional reason for the ban
  Future<void> banUser(String roomId, String userId, {String? reason}) async {
    _logger.i('Banning user $userId from room $roomId');

    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/rooms/$roomId/ban');

    final body = jsonEncode({
      'user_id': userId,
      if (reason != null) 'reason': reason,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final error = response.body.isNotEmpty ? response.body : 'Unknown error';
      throw MatrixException('Failed to ban user: $error');
    }

    _logger.i('User banned successfully');
  }

  /// Unban a user from a room
  ///
  /// [roomId] The room ID
  /// [userId] The user ID to unban
  Future<void> unbanUser(String roomId, String userId) async {
    _logger.i('Unbanning user $userId from room $roomId');

    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/rooms/$roomId/unban');

    final body = jsonEncode({
      'user_id': userId,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final error = response.body.isNotEmpty ? response.body : 'Unknown error';
      throw MatrixException('Failed to unban user: $error');
    }

    _logger.i('User unbanned successfully');
  }

  /// Set room name
  ///
  /// [roomId] The room ID
  /// [name] The new room name
  Future<void> setRoomName(String roomId, String name) async {
    _logger.i('Setting room name for $roomId to: $name');

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/rooms/$roomId/state/m.room.name',
    );

    final body = jsonEncode({'name': name});

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw MatrixException('Failed to set room name: ${response.statusCode}');
    }

    _logger.i('Room name set successfully');
  }

  /// Set room topic
  ///
  /// [roomId] The room ID
  /// [topic] The new room topic
  Future<void> setRoomTopic(String roomId, String topic) async {
    _logger.i('Setting room topic for $roomId to: $topic');

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/rooms/$roomId/state/m.room.topic',
    );

    final body = jsonEncode({'topic': topic});

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw MatrixException('Failed to set room topic: ${response.statusCode}');
    }

    _logger.i('Room topic set successfully');
  }

  /// Set room avatar
  ///
  /// [roomId] The room ID
  /// [avatarUrl] The MXC URI of the avatar
  Future<void> setRoomAvatar(String roomId, String avatarUrl) async {
    _logger.i('Setting room avatar for $roomId to: $avatarUrl');

    final url = Uri.parse(
      '${client.homeserver}/_matrix/client/v3/rooms/$roomId/state/m.room.avatar',
    );

    final body = jsonEncode({'url': avatarUrl});

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw MatrixException('Failed to set room avatar: ${response.statusCode}');
    }

    _logger.i('Room avatar set successfully');
  }

  /// Dispose of the room creation manager
  Future<void> dispose() async {
    _logger.i('Room creation manager disposed');
  }
}

/// Response from room creation
class CreateRoomResponse {
  /// Create a response from JSON
  factory CreateRoomResponse.fromJson(Map<String, dynamic> json) {
    return CreateRoomResponse(
      roomId: json['room_id'] as String? ?? '',
      roomAlias: json['room_alias'] as String?,
    );
  }

  /// Create a new response
  CreateRoomResponse({
    required this.roomId,
    this.roomAlias,
  });

  /// The created room ID
  final String roomId;

  /// The room alias (if created)
  final String? roomAlias;
}
