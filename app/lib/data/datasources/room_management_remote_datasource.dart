import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';

/// Room management remote datasource - implements Matrix room state API
/// See: https://spec.matrix.org/v1.11/client-server-api/#room-management
@injectable
class RoomManagementRemoteDataSource {
  const RoomManagementRemoteDataSource(this._logger);

  final Logger _logger;

  /// Get the _matrix client URL for a homeserver
  String _getMatrixUrl(String homeserver) {
    final cleanUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
    return '$cleanUrl/_matrix/client/v3';
  }

  /// Generate a unique transaction ID
  String _generateTxnId() => 'm${DateTime.now().millisecondsSinceEpoch}';

  /// Create a new room
  /// POST /_matrix/client/v3/createRoom
  Future<Either<Failure, Map<String, dynamic>>> createRoom({
    required String homeserver,
    required String accessToken,
    required String name,
    String? topic,
    bool isDirect = false,
    bool isPublic = false,
    List<String> inviteUserIds = const [],
    Map<String, dynamic>? presetConfig,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/createRoom');

      // Build request body - only include topic if provided
      final body = <String, dynamic>{
        'name': name,
        'visibility': isPublic ? 'public' : 'private',
        'preset': isDirect ? 'trusted_private_chat' : 'private_chat',
        'invite': inviteUserIds,
        if (topic != null && topic.isNotEmpty) 'topic': topic,
        if (presetConfig != null) ...presetConfig,
      };

      _logger.i('Creating room: $name');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _logger.i('Room created: ${data['room_id']}');
        return Right(data);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to create room',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error creating room', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Set room name
  /// PUT /_matrix/client/v3/rooms/{roomId}/state/m.room.name/
  Future<Either<Failure, void>> setRoomName({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String name,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/state/m.room.name/');

      final body = {'name': name};

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _logger.i('Room name updated: $roomId -> $name');
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        throw AuthException(
          message: 'Permission denied',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to set room name',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error setting room name', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Set room topic
  /// PUT /_matrix/client/v3/rooms/{roomId}/state/m.room.topic/
  Future<Either<Failure, void>> setRoomTopic({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String topic,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/state/m.room.topic/');

      final body = {'topic': topic};

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _logger.i('Room topic updated: $roomId');
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        throw AuthException(
          message: 'Permission denied',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to set room topic',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error setting room topic', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Set room avatar
  /// PUT /_matrix/client/v3/rooms/{roomId}/state/m.room.avatar/
  Future<Either<Failure, void>> setRoomAvatar({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String mxcUrl,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/state/m.room.avatar/');

      final body = {'url': mxcUrl};

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _logger.i('Room avatar updated: $roomId');
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        throw AuthException(
          message: 'Permission denied',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to set room avatar',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error setting room avatar', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Invite a user to a room
  /// POST /_matrix/client/v3/rooms/{roomId}/invite
  Future<Either<Failure, void>> inviteUser({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String userId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/invite');

      final body = {'user_id': userId};

      _logger.i('Inviting user $userId to room $roomId');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        throw AuthException(
          message: 'Permission denied',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to invite user',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error inviting user', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Kick a user from a room
  /// POST /_matrix/client/v3/rooms/{roomId}/kick
  Future<Either<Failure, void>> kickUser({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String userId,
    String? reason,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/kick');

      final body = {'user_id': userId};
      if (reason != null) {
        body['reason'] = reason;
      }

      _logger.i('Kicking user $userId from room $roomId');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        throw AuthException(
          message: 'Permission denied',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to kick user',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error kicking user', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Ban a user from a room
  /// POST /_matrix/client/v3/rooms/{roomId}/ban
  Future<Either<Failure, void>> banUser({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String userId,
    String? reason,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/ban');

      final body = {'user_id': userId};
      if (reason != null) {
        body['reason'] = reason;
      }

      _logger.i('Banning user $userId from room $roomId');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        throw AuthException(
          message: 'Permission denied',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to ban user',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error banning user', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Unban a user from a room
  /// POST /_matrix/client/v3/rooms/{roomId}/unban
  Future<Either<Failure, void>> unbanUser({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String userId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/unban');

      final body = {'user_id': userId};

      _logger.i('Unbanning user $userId from room $roomId');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        throw AuthException(
          message: 'Permission denied',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to unban user',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error unbanning user', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get room members
  /// GET /_matrix/client/v3/rooms/{roomId}/members
  Future<Either<Failure, List<Map<String, dynamic>>>> getRoomMembers({
    required String homeserver,
    required String accessToken,
    required String roomId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/members');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final chunk = data['chunk'] as List? ?? [];

        final members = chunk.map((event) {
          if (event is! Map<String, dynamic>) return null;

          final content = event['content'] as Map<String, dynamic>?;
          final senderId = event['sender'] as String?;
          final stateKey = event['state_key'] as String?;
          final membership = content?['membership'] as String?;
          final displayName = content?['displayname'] as String?;
          final avatarUrl = content?['avatar_url'] as String?;

          return <String, dynamic>{
            'userId': senderId,
            'displayName': displayName,
            'avatarUrl': avatarUrl,
            'membership': membership,
            'stateKey': stateKey,
          };
        }).whereType<Map<String, dynamic>>().toList();

        return Right(members);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to get room members',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error getting room members', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Set room power levels
  /// PUT /_matrix/client/v3/rooms/{roomId}/state/m.room.power_levels/
  Future<Either<Failure, void>> setPowerLevels({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required Map<String, int> users,
    required Map<String, int> events,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/state/m.room.power_levels/');

      final body = {
        'users': users,
        'events': events,
      };

      _logger.i('Updating power levels for room: $roomId');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        throw AuthException(
          message: 'Permission denied',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to set power levels',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error setting power levels', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Set room join rules
  /// PUT /_matrix/client/v3/rooms/{roomId}/state/m.room.join_rules/
  Future<Either<Failure, void>> setJoinRules({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String joinRule,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/state/m.room.join_rules/');

      final body = {'join_rule': joinRule};

      _logger.i('Setting join rule for room: $roomId -> $joinRule');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        throw AuthException(
          message: 'Permission denied',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to set join rules',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error setting join rules', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Set guest access
  /// PUT /_matrix/client/v3/rooms/{roomId}/state/m.room.guest_access/
  Future<Either<Failure, void>> setGuestAccess({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required bool allowed,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$roomId/state/m.room.guest_access/');

      final body = {'guest_access': allowed ? 'can_join' : 'forbidden'};

      _logger.i('Setting guest access for room: $roomId -> $allowed');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        throw AuthException(
          message: 'Permission denied',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to set guest access',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error setting guest access', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Set history visibility
  /// PUT /_matrix/client/v3/rooms/{roomId}/state/m.room.history_visibility/
  Future<Either<Failure, void>> setHistoryVisibility({
    required String homeserver,
    required String accessToken,
    required String roomId,
    required String visibility,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse(
        '$baseUrl/rooms/$roomId/state/m.room.history_visibility/',
      );

      final body = {'history_visibility': visibility};

      _logger.i('Setting history visibility for room: $roomId -> $visibility');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        throw AuthException(
          message: 'Permission denied',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to set history visibility',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error setting history visibility', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
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

      _logger.i('Getting room state for: $roomId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final events = jsonDecode(response.body) as List;

        // Convert list of events to a map keyed by event type
        final stateMap = <String, dynamic>{};
        for (final event in events) {
          if (event is Map<String, dynamic>) {
            final type = event['type'] as String?;
            final content = event['content'] as Map<String, dynamic>?;
            if (type != null && content != null) {
              stateMap[type] = content;
            }
          }
        }

        return Right(stateMap);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to get room state',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error getting room state', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Delete room (requires admin privileges)
  /// POST /_matrix/client/v3/rooms/{roomId}/delete or /_matrix/client/v1/rooms/{roomId}/delete
  Future<Either<Failure, void>> deleteRoom({
    required String homeserver,
    required String accessToken,
    required String roomId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver).replaceAll('/v3', '');
      final uri = Uri.parse('$baseUrl/v1/rooms/$roomId/delete');

      _logger.i('Deleting room: $roomId');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _logger.i('Room deleted: $roomId');
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        throw AuthException(
          message: 'Permission denied - requires admin privileges',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to delete room',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error deleting room', error: e, stackTrace: stackTrace);
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

      _logger.i('Leaving room: $roomId');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _logger.i('Left room: $roomId');
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to leave room',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error leaving room', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
