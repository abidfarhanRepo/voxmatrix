/// Room Manager for Matrix room operations
///
/// Handles room state management, lazy loading, and room operations
/// See: https://spec.matrix.org/v1.11/client-server-api/#room-management

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:collection/collection.dart';
import 'package:voxmatrix/core/matrix/src/matrix_client.dart';
import 'package:voxmatrix/core/matrix/src/models/room.dart';
import 'package:voxmatrix/core/matrix/src/models/user.dart';
import 'package:voxmatrix/core/matrix/src/models/event.dart';
import 'package:voxmatrix/core/matrix/src/sync/sync_controller.dart';

/// Room Manager for handling room operations
class RoomManager {
  /// Create a new room manager
  RoomManager({
    required this.client,
    required Logger logger,
  }) : _logger = logger {
    _rooms = {};
    _directRooms = {};
    _roomsController = StreamController<Map<String, MatrixRoom>>.broadcast();
  }

  /// The Matrix client
  final MatrixClient client;

  /// Logger instance
  final Logger _logger;

  /// Cache of rooms
  late final Map<String, MatrixRoom> _rooms;

  /// Map of direct message rooms (user ID -> room IDs)
  late final Map<String, List<String>> _directRooms;

  /// Stream controller for room updates
  late final StreamController<Map<String, MatrixRoom>> _roomsController;

  /// Stream of room updates
  Stream<Map<String, MatrixRoom>> get rooms => _roomsController.stream;

  /// Get all cached rooms
  Map<String, MatrixRoom> get cachedRooms => Map.unmodifiable(_rooms);

  /// Get a room by ID
  MatrixRoom? getRoom(String roomId) => _rooms[roomId];

  /// Get all direct message rooms
  List<MatrixRoom> get directRooms =>
      _rooms.values.where((room) => room.isDirect).toList();

  /// Process room sync data
  Future<void> processRoomSync(String roomId, MatrixRoomSync roomSync) async {
    final existingRoom = _rooms[roomId];

    if (roomSync.membership == RoomMembership.leave) {
      // User left the room
      _rooms.remove(roomId);
      _logger.d('Removed room: $roomId');
    } else if (roomSync.membership == RoomMembership.invite) {
      // User was invited to the room
      final room = await _createRoomFromSync(roomId, roomSync);
      _rooms[roomId] = room;
      _logger.d('Added invited room: $roomId');
    } else {
      // User is in the room (joined)
      if (existingRoom == null) {
        // New room
        final room = await _createRoomFromSync(roomId, roomSync);
        _rooms[roomId] = room;
        _logger.d('Added new room: $roomId');
      } else {
        // Update existing room
        _rooms[roomId] = await _updateRoomFromSync(existingRoom, roomSync);
      }
    }

    // Emit room updates
    _roomsController.add(Map.unmodifiable(_rooms));
  }

  /// Update direct message mappings
  void updateDirectMessages(Map<String, dynamic> directData) {
    _directRooms.clear();
    for (final entry in directData.entries) {
      final userId = entry.key;
      final roomList = entry.value;
      if (roomList is List) {
        _directRooms[userId] = roomList.cast<String>();
        // Mark rooms as direct
        for (final roomId in roomList) {
          final room = _rooms[roomId];
          if (room != null) {
            _rooms[roomId] = room.copyWith(isDirect: true);
          }
        }
      }
    }
    _logger.d('Updated direct messages: ${_directRooms.length} users');
  }

  /// Fetch full room state (for lazy loading)
  Future<List<MatrixEvent>> getRoomState(String roomId) async {
    _logger.d('Fetching room state for: $roomId');

    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/rooms/$roomId/state');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      final events = data
          .map((e) => e is Map<String, dynamic> ? MatrixEvent.fromJson(e) : null)
          .whereType<MatrixEvent>()
          .toList();
      _logger.d('Retrieved ${events.length} state events for room: $roomId');
      return events;
    } else if (response.statusCode == 401) {
      throw MatrixException('Access token expired or invalid');
    } else {
      throw MatrixException('Failed to get room state: ${response.statusCode}');
    }
  }

  /// Fetch room members
  Future<List<MatrixUser>> getRoomMembers(String roomId) async {
    final stateEvents = await getRoomState(roomId);
    final members = <MatrixUser>[];

    for (final event in stateEvents) {
      if (event.type == 'm.room.member') {
        final membership = event.membership;
        if (membership == 'join') {
          members.add(MatrixUser(
            id: event.senderId ?? event.stateKey ?? '',
            displayName: event.displayName,
            avatarUrl: event.avatarUrl,
            membership: membership ?? 'unknown',
          ));
        }
      }
    }

    _logger.d('Retrieved ${members.length} members for room: $roomId');
    return members;
  }

  /// Create a room from sync data
  Future<MatrixRoom> _createRoomFromSync(
    String roomId,
    MatrixRoomSync roomSync,
  ) async {
    // Extract room name
    String? roomName;
    String? topic;
    String? avatarUrl;

    for (final event in roomSync.state) {
      if (event.type == 'm.room.name') {
        roomName = event.roomName;
      } else if (event.type == 'm.room.topic') {
        topic = event.roomTopic;
      } else if (event.type == 'm.room.avatar') {
        final url = event.content['url'] as String?;
        if (url != null) {
          avatarUrl = _mxcToHttp(url);
        }
      }
    }

    // Generate room name from heroes if not set
    roomName ??= _generateRoomName(roomId, roomSync);

    // Check if this is a direct message
    final isDirect = _isDirectMessage(roomId);

    // Get members from state events
    final members = _extractMembers(roomSync.state);

    return MatrixRoom(
      id: roomId,
      name: roomName,
      topic: topic,
      avatarUrl: avatarUrl,
      isDirect: isDirect,
      members: members,
      heroes: roomSync.heroes,
      joinedMemberCount: roomSync.joinedMemberCount,
      invitedMemberCount: roomSync.invitedMemberCount,
      lastEvent: roomSync.timeline.isNotEmpty ? roomSync.timeline.last : null,
      unreadCount: roomSync.notificationCount,
      highlightCount: roomSync.highlightCount,
      currentState: roomSync.state,
    );
  }

  /// Update an existing room from sync data
  Future<MatrixRoom> _updateRoomFromSync(
    MatrixRoom existingRoom,
    MatrixRoomSync roomSync,
  ) async {
    // Update room name
    String? roomName = existingRoom.name;
    String? topic = existingRoom.topic;
    String? avatarUrl = existingRoom.avatarUrl;

    for (final event in roomSync.state) {
      if (event.type == 'm.room.name' && event.roomName != null) {
        roomName = event.roomName;
      } else if (event.type == 'm.room.topic' && event.roomTopic != null) {
        topic = event.roomTopic;
      } else if (event.type == 'm.room.avatar') {
        final url = event.content['url'] as String?;
        if (url != null) {
          avatarUrl = _mxcToHttp(url);
        }
      }
    }

    // Get updated members
    final members = _extractMembers(roomSync.state);

    return existingRoom.copyWith(
      name: roomName ?? _generateRoomName(existingRoom.id, roomSync),
      topic: topic,
      avatarUrl: avatarUrl,
      members: members,
      heroes: roomSync.heroes,
      joinedMemberCount: roomSync.joinedMemberCount,
      invitedMemberCount: roomSync.invitedMemberCount,
      lastEvent: roomSync.timeline.isNotEmpty ? roomSync.timeline.last : existingRoom.lastEvent,
      unreadCount: roomSync.notificationCount,
      highlightCount: roomSync.highlightCount,
      currentState: roomSync.state,
    );
  }

  /// Generate room name from heroes
  String _generateRoomName(String roomId, MatrixRoomSync roomSync) {
    // Try explicit room name from state
    for (final event in roomSync.state) {
      if (event.type == 'm.room.name') {
        final name = event.roomName;
        if (name != null && name.isNotEmpty) {
          return name;
        }
      }
    }

    // Use heroes to generate name - this is the primary fallback
    if (roomSync.heroes.isNotEmpty) {
      // Filter out current user
      final currentUserId = client.userId;
      final otherHeroes = currentUserId != null
          ? roomSync.heroes.where((h) => h != currentUserId).toList()
          : roomSync.heroes;

      if (otherHeroes.isNotEmpty) {
        if (otherHeroes.length == 1) {
          final name = otherHeroes.first.split(':')[0].replaceAll('@', '');
          if (name.isNotEmpty) return name;
        } else if (otherHeroes.length <= 3) {
          final names = otherHeroes
              .map((h) => h.split(':')[0].replaceAll('@', ''))
              .where((s) => s.isNotEmpty)
              .join(', ');
          if (names.isNotEmpty) return names;
        } else {
          return 'Group (${roomSync.joinedMemberCount} members)';
        }
      }
    }

    // Fallback based on member count - NEVER show empty room to users
    if (roomSync.joinedMemberCount <= 2) {
      return 'Direct Message';
    } else {
      return 'Group (${roomSync.joinedMemberCount} members)';
    }
  }

  /// Extract members from state events
  List<MatrixUser> _extractMembers(List<MatrixEvent> stateEvents) {
    final members = <String, MatrixUser>{};

    for (final event in stateEvents) {
      if (event.type == 'm.room.member') {
        final userId = event.stateKey;
        if (userId != null && event.membership == 'join') {
          members[userId] = MatrixUser(
            id: userId,
            displayName: event.displayName,
            avatarUrl: event.avatarUrl,
            membership: event.membership ?? 'join',
          );
        }
      }
    }

    return members.values.toList();
  }

  /// Check if a room is a direct message
  bool _isDirectMessage(String roomId) {
    for (final roomList in _directRooms.values) {
      if (roomList.contains(roomId)) {
        return true;
      }
    }
    return false;
  }

  /// Convert MXC URL to HTTP URL
  String? _mxcToHttp(String? mxcUrl) {
    if (mxcUrl == null || !mxcUrl.startsWith('mxc://')) {
      return mxcUrl;
    }
    final parts = mxcUrl.substring(6).split('/');
    if (parts.length >= 2) {
      return 'https://${parts[0]}/_matrix/media/v3/download/${parts[0]}/${parts[1]}';
    }
    return mxcUrl;
  }

  /// Dispose of the room manager
  Future<void> dispose() async {
    await _roomsController.close();
    _rooms.clear();
    _directRooms.clear();
    _logger.i('Room manager disposed');
  }
}
