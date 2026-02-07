import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/core/matrix/matrix_client.dart';
import 'package:voxmatrix/core/services/matrix_client_service.dart';
import 'package:matrix/matrix.dart' as matrix;

/// Room remote datasource - uses Matrix SDK for room operations
/// See: https://spec.matrix.org/v1.11/client-server-api/#room-listing
@injectable
class RoomRemoteDataSource {
  const RoomRemoteDataSource(
    this._logger,
    this._matrixClientService,
  );

  final Logger _logger;
  final MatrixClientService _matrixClientService;

  /// Get all rooms the user is in using the SDK
  Future<Either<Failure, List<Map<String, dynamic>>>> getRooms({
    required String homeserver,
    required String accessToken,
    String? currentUserId,
  }) async {
    try {
      _logger.i('Getting rooms from SDK');

      // Prefer SDK-backed rooms if the Matrix client is available.
      if (_matrixClientService.isInitialized ||
          await _tryInitMatrixClient(
            homeserver: homeserver,
            accessToken: accessToken,
            userId: currentUserId,
          )) {
        final client = _matrixClientService.client;
        final rooms = <Map<String, dynamic>>[];

        for (final room in client.rooms) {
          try {
            await room.postLoad();

            final name = room.getLocalizedDisplayname();
            final isDirect = room.isDirectChat;
            final avatarMxc = room.avatar?.toString();
            final avatarUrl = avatarMxc != null ? _mxcToHttp(avatarMxc, homeserver) : null;

            Map<String, dynamic>? lastMessage;
            final lastEvent = room.lastEvent;
            if (lastEvent != null && lastEvent.type == matrix.EventTypes.Message) {
              final content = lastEvent.content;
              final msgType = content['msgtype'] as String?;
              String? messageContent;
              if (msgType == 'm.text') {
                messageContent = content['body'] as String?;
              } else if (msgType == 'm.image') {
                messageContent = '📷 Image';
              } else if (msgType == 'm.video') {
                messageContent = '🎥 Video';
              } else if (msgType == 'm.audio') {
                messageContent = '🎵 Audio';
              } else if (msgType == 'm.file') {
                messageContent = '📎 File';
              } else {
                messageContent = content['body'] as String? ?? 'Message';
              }

              final senderId = lastEvent.senderId;
              final senderName = senderId?.split(':').first.replaceAll('@', '') ?? 'Unknown';

              lastMessage = {
                'senderId': senderId,
                'senderName': senderName,
                'content': messageContent,
                'timestamp': lastEvent.originServerTs,
              };
            }

            rooms.add({
              'id': room.id,
              'name': name.isNotEmpty ? name : 'Unnamed Room',
              'isDirect': isDirect,
              'topic': room.topic,
              'avatarUrl': avatarUrl,
              'lastMessage': lastMessage,
              'unreadCount': room.notificationCount,
              'members': const <Map<String, dynamic>>[],
            });
          } catch (e, stackTrace) {
            _logger.w('Failed to parse room ${room.id}', error: e, stackTrace: stackTrace);
          }
        }

        return Right(rooms);
      }

      // Import the Matrix SDK client to use RoomManager
      // This is a placeholder - in production, we'd inject the SDK client
      // For now, we'll use the direct HTTP approach with improved room name logic

      final baseUrl = _getMatrixUrl(homeserver);

      final uri = Uri.parse('$baseUrl/sync').replace(queryParameters: {
        'timeout': '30000',
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 35));

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Sync failed with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rooms = data['rooms'] as Map<String, dynamic>?;

      if (rooms == null) {
        return const Right([]);
      }

      // Extract m.direct from global account data
      final Set<String> directRoomIds = {};
      final globalAccountData = data['account_data'] as Map<String, dynamic>? ?? {};
      final globalEvents = globalAccountData['events'] as List? ?? [];
      for (final event in globalEvents) {
        if (event is! Map<String, dynamic>) continue;
        if (event['type'] == 'm.direct') {
          final content = event['content'] as Map<String, dynamic>? ?? {};
          content.forEach((userId, roomList) {
            if (roomList is List) {
              for (final roomId in roomList) {
                directRoomIds.add(roomId.toString());
              }
            }
          });
          break;
        }
      }

      final joined = rooms['join'] as Map<String, dynamic>? ?? {};
      final roomList = <Map<String, dynamic>>[];

      for (final entry in joined.entries) {
        final roomId = entry.key;
        final roomData = entry.value as Map<String, dynamic>;

        try {
          final summary = roomData['summary'] as Map<String, dynamic>? ?? {};
          final unreadNotifications = roomData['unread_notifications'] as Map<String, dynamic>? ?? {};
          final timeline = roomData['timeline'] as Map<String, dynamic>? ?? {};
          final stateData = roomData['state'] as Map<String, dynamic>? ?? {};

          // Get heroes from summary
          final heroes = summary['m.heroes'] as List? ?? [];
          final joinedCount = summary['m.joined_member_count'] as int? ?? 0;

          // Get room name from summary (server-computed)
          final summaryDisplayName = summary['m.room.displayname'] as String?;

          _logger.d('Room $roomId: summary=$summary');
          _logger.d('Room $roomId:heroes=$heroes, joinedCount=$joinedCount, summaryDisplayName=$summaryDisplayName');

          // Get explicit room name from state events
          String? explicitRoomName;
          String? roomTopic;
          String? roomAvatar;

          // In Matrix sync, state.events is a List of state events
          final stateEventsList = stateData['events'] as List<dynamic>? ?? [];

          _logger.d('Room $roomId: Processing ${stateEventsList.length} state events');
          _logger.d('  State keys: ${stateData.keys.toList()}');
          
          for (final event in stateEventsList) {
            if (event is! Map<String, dynamic>) continue;

            final type = event['type'] as String?;
            final content = event['content'] as Map<String, dynamic>?;

            _logger.d('  State event type: $type');

            if (type == 'm.room.name' && content != null) {
              explicitRoomName = content['name'] as String?;
              if (explicitRoomName != null) {
                explicitRoomName = explicitRoomName.trim();
              }
              _logger.d('  ✓ Found explicit name from m.room.name: "$explicitRoomName"');
            } else if (type == 'm.room.topic' && content != null) {
              roomTopic = content['topic'] as String?;
            } else if (type == 'm.room.avatar' && content != null) {
              final url = content['url'] as String?;
              if (url != null) {
                roomAvatar = _mxcToHttp(url, homeserver);
              }
            }
          }

          // If no room name found in state (sync may not include it), fetch explicitly
          if (explicitRoomName == null || explicitRoomName.isEmpty) {
            _logger.d('Room $roomId: State events empty or no name found, fetching room state...');
            explicitRoomName = await _fetchRoomName(
              homeserver: homeserver,
              accessToken: accessToken,
              roomId: roomId,
            );
            if (explicitRoomName != null && explicitRoomName.isNotEmpty) {
              _logger.d('Room $roomId: Fetched explicit name: "$explicitRoomName"');
            }
          }

          // Check if direct message
          final isDirect = directRoomIds.contains(roomId);

          // Generate display name using SDK-style logic
          final displayName = _generateRoomDisplayName(
            roomId: roomId,
            summaryDisplayName: summaryDisplayName,
            explicitRoomName: explicitRoomName,
            heroes: heroes,
            joinedCount: joinedCount,
            isDirect: isDirect,
            currentUserId: currentUserId,
          );

          _logger.d('Room $roomId: displayName="$displayName" (summary=$summaryDisplayName, explicit=$explicitRoomName)');

          // Get last message
          final timelineEvents = timeline['events'] as List? ?? [];
          Map<String, dynamic>? lastMessage;
          if (timelineEvents.isNotEmpty) {
            final lastEvent = timelineEvents.last;
            if (lastEvent is Map<String, dynamic>) {
              final senderId = lastEvent['sender'] as String?;
              final content = lastEvent['content'] as Map<String, dynamic>?;

              String senderName = senderId?.split(':').first.replaceAll('@', '') ?? 'Unknown';
              String? messageContent;

              final msgType = content?['msgtype'] as String?;
              if (msgType == 'm.text') {
                messageContent = content?['body'] as String?;
              } else if (msgType == 'm.image') {
                messageContent = '📷 Image';
              } else if (msgType == 'm.video') {
                messageContent = '🎥 Video';
              } else if (msgType == 'm.audio') {
                messageContent = '🎵 Audio';
              } else if (msgType == 'm.file') {
                messageContent = '📎 File';
              } else {
                messageContent = content?['body'] as String? ?? 'Message';
              }

              final timestamp = lastEvent['origin_server_ts'] as int?;

              if (senderId != null && messageContent != null) {
                lastMessage = {
                  'senderId': senderId,
                  'senderName': senderName,
                  'content': messageContent,
                  'timestamp': timestamp != null
                      ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                      : DateTime.now(),
                };
              }
            }
          }

          // Get unread counts
          final unreadCount = unreadNotifications['notification_count'] as int? ?? 0;
          final highlightCount = unreadNotifications['highlight_count'] as int? ?? 0;

          roomList.add({
            'id': roomId,
            'name': displayName,
            'topic': roomTopic,
            'avatarUrl': roomAvatar,
            'isDirect': isDirect,
            'members': [], // Members are lazy-loaded, not included in sync
            'lastMessage': lastMessage,
            'unreadCount': unreadCount,
            'highlightCount': highlightCount,
          });
        } catch (e, stackTrace) {
          _logger.e('Error parsing room $roomId', error: e, stackTrace: stackTrace);
        }
      }

      _logger.i('Loaded ${roomList.length} rooms');
      return Right(roomList);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error getting rooms', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<bool> _tryInitMatrixClient({
    required String homeserver,
    required String accessToken,
    String? userId,
  }) async {
    if (userId == null || userId.isEmpty) {
      return false;
    }
    try {
      final ok = await _matrixClientService.initialize(
        homeserver: homeserver,
        accessToken: accessToken,
        userId: userId,
      );
      if (ok) {
        await _matrixClientService.startSync();
      }
      return ok;
    } catch (e) {
      _logger.w('Failed to init Matrix client for rooms', error: e);
      return false;
    }
  }

  /// Get room state
  /// GET /_matrix/client/v3/rooms/{roomId}/state
  Future<Either<Failure, Map<String, dynamic>>> getRoomState({
    required String homeserver,
    required String accessToken,
    required String roomId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/state');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return Right({'events': data});
      } else {
        throw ServerException(
          message: 'Failed to get room state: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      _logger.e('Error getting room state', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Join a room
  /// POST /_matrix/client/v3/rooms/{roomId}/join
  Future<Either<Failure, Map<String, dynamic>>> joinRoom({
    required String homeserver,
    required String accessToken,
    required String roomIdOrAlias,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomIdOrAlias/join');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(data);
      } else {
        throw ServerException(
          message: 'Failed to join room: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      _logger.e('Error joining room', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Leave a room
  /// POST /_matrix/client/v3/rooms/{roomId}/leave
  Future<Either<Failure, void>> leaveRoom({
    required String homeserver,
    required String accessToken,
    required String roomId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/leave');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return const Right(null);
      } else {
        throw ServerException(
          message: 'Failed to leave room: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      _logger.e('Error leaving room', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get the _matrix client URL for a homeserver
  String _getMatrixUrl(String homeserver) {
    final cleanUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
    return '$cleanUrl/_matrix/client/v3';
  }

  /// Convert mxc:// URL to http:// URL
  String _mxcToHttp(String mxcUrl, String homeserver) {
    if (!mxcUrl.startsWith('mxc://')) {
      return mxcUrl;
    }

    final parts = mxcUrl.substring(6).split('/');
    if (parts.length != 2) {
      return mxcUrl;
    }

    final server = parts[0];
    final mediaId = parts[1];

    return '$homeserver/_matrix/media/v3/download/$server/$mediaId';
  }

  /// Generate room display name using SDK-style logic
  /// This matches the logic in RoomManager._generateRoomName()
  String _generateRoomDisplayName({
    required String roomId,
    String? summaryDisplayName,
    String? explicitRoomName,
    required List heroes,
    required int joinedCount,
    required bool isDirect,
    String? currentUserId,
  }) {
    _logger.d('=== DISPLAY NAME DEBUG for $roomId ===');
    _logger.d('  explicitRoomName: "$explicitRoomName"');
    _logger.d('  summaryDisplayName: "$summaryDisplayName"');
    _logger.d('  heroes: $heroes (count: ${heroes.length})');
    _logger.d('  joinedCount: $joinedCount');
    _logger.d('  isDirect: $isDirect');

    // 1. Use explicit room name from m.room.name event - THIS IS PRIMARY
    if (explicitRoomName != null && explicitRoomName.isNotEmpty) {
      _logger.d('  RESULT: Using explicit room name: "$explicitRoomName"');
      return explicitRoomName;
    }

    // 2. Use server-computed display name from summary (if valid)
    // BUT NOT "Empty room" which is server's placeholder when no name is set
    if (summaryDisplayName != null &&
        summaryDisplayName.isNotEmpty &&
        summaryDisplayName != 'Empty room' &&
        !summaryDisplayName.startsWith('!')) {
      _logger.d('  RESULT: Using summary display name: "$summaryDisplayName"');
      return summaryDisplayName;
    }

    // 3. Filter heroes to exclude current user
    final otherHeroes = currentUserId != null
        ? heroes.where((h) => h.toString() != currentUserId).toList()
        : heroes.cast<String>();

    _logger.d('  otherHeroes (filtered): $otherHeroes (count: ${otherHeroes.length})');

    // 4. Generate name from heroes - this is the primary fallback for rooms without explicit names
    if (otherHeroes.isNotEmpty) {
      if (otherHeroes.length == 1) {
        // Single other person - use their username
        final heroId = otherHeroes.first;
        final name = heroId.split(':').first.replaceAll('@', '');
        _logger.d('  RESULT: Single hero name: "$name"');
        return name.isNotEmpty ? name : 'Unknown';
      } else if (otherHeroes.length <= 3) {
        // Multiple people - show their usernames
        final names = otherHeroes
            .take(3)
            .map((h) => h.split(':').first.replaceAll('@', ''))
            .where((s) => s.isNotEmpty)
            .toList();
        final displayNames = names.join(', ');
        _logger.d('  RESULT: Multiple heroes name: "$displayNames"');
        return displayNames.isNotEmpty ? displayNames : 'Group';
      } else {
        // Many people - show count
        final groupName = 'Group ($joinedCount members)';
        _logger.d('  RESULT: Group name: "$groupName"');
        return groupName;
      }
    }

    // 5. Fallback based on member count - NEVER show "Empty Room" to users
    // This should only be reached if no heroes and no explicit name
    if (isDirect) {
      _logger.d('  RESULT: Fallback direct message');
      return 'Direct Message';
    } else if (joinedCount > 1) {
      final groupName = 'Group ($joinedCount members)';
      _logger.d('  RESULT: Fallback group name: "$groupName"');
      return groupName;
    } else {
      // Room with no name and no other members - use room ID as last resort
      final roomIdDisplay = roomId.replaceAll(RegExp(r'[!:].*'), '');
      _logger.d('  RESULT: Using room ID fallback: "$roomIdDisplay"');
      return roomIdDisplay.isNotEmpty ? roomIdDisplay : 'Unnamed Room';
    }
  }

  /// Search for users in the user directory
  /// POST /_matrix/client/v3/user_directory/search
  Future<Either<Failure, List<Map<String, dynamic>>>> searchUsers({
    required String homeserver,
    required String accessToken,
    required String query,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/user_directory/search');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'search_term': query,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List? ?? [];
        final users = results.map((user) {
          return {
            'user_id': user['user_id'] as String?,
            'display_name': user['display_name'] as String?,
            'avatar_url': user['avatar_url'] as String?,
          };
        }).toList();
        return Right(users);
      } else if (response.statusCode == 429) {
        return Left(ServerFailure(
          message: 'Rate limited, please try again',
          statusCode: response.statusCode,
        ));
      } else {
        return Left(ServerFailure(
          message: 'User search failed: ${response.statusCode}',
          statusCode: response.statusCode,
        ));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error searching users', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Look up a specific user by their user ID
  /// GET /_matrix/client/v3/profile/{userId}
  Future<Either<Failure, Map<String, dynamic>>> getUserProfile({
    required String homeserver,
    required String accessToken,
    required String userId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/profile/$userId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(data);
      } else {
        return Left(ServerFailure(
          message: 'User not found',
          statusCode: response.statusCode,
        ));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      _logger.e('Error getting user profile', error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Fetch room name from server using /state/m.room.name endpoint
  /// This is needed when the room name isn't available in sync response
  Future<String?> _fetchRoomName({
    required String homeserver,
    required String accessToken,
    required String roomId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/state/m.room.name');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        var name = data['name'] as String?;
        if (name != null) {
          name = name.trim(); // Remove leading/trailing whitespace
          _logger.d('Fetched room name for $roomId: "$name"');
          return name.isNotEmpty ? name : null;
        }
      } else {
        _logger.d('Failed to fetch room name for $roomId: ${response.statusCode}');
      }
    } catch (e) {
      _logger.d('Error fetching room name for $roomId: $e');
    }
    return null;
  }
}
