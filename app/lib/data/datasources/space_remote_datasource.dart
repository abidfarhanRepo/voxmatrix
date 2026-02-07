import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/domain/entities/space_entity.dart';

/// Space remote datasource - implements Matrix Spaces API
/// See: https://spec.matrix.org/v1.11/client-server-api/#mspace
@injectable
class SpaceRemoteDataSource {
  const SpaceRemoteDataSource(this._logger);

  final Logger _logger;

  /// Get the _matrix client URL for a homeserver
  String _getMatrixUrl(String homeserver) {
    final cleanUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
    return '$cleanUrl/_matrix/client/v3';
  }

  /// Get all spaces the user is a member of
  /// Uses the room filter with m.room.type of m.space
  Future<Either<Failure, List<SpaceEntity>>> getSpaces({
    required String homeserver,
    required String accessToken,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms');

      _logger.i('Fetching spaces');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rooms = data['rooms'] as List? ?? [];
        _logger.i('Found ${rooms.length} rooms');

        // Filter for spaces only (m.space room type)
        final spaces = rooms
            .where((room) =>
                room['room_type'] == 'm.space' ||
                room['creation_content']?['type'] == 'm.space')
            .map((room) => SpaceEntity(
                  id: room['room_id'] as String,
                  name: room['name'] as String? ?? room['room_id'] as String,
                  topic: room['topic'] as String?,
                  avatarUrl: room['avatar_url'] as String?,
                  memberCount: room['num_joined_members'] as int? ?? 0,
                ))
            .toList();

        _logger.i('Found ${spaces.length} spaces');
        return Right(spaces);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to fetch spaces',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e, stackTrace) {
      _logger.e('Error fetching spaces', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get rooms within a space
  /// GET /_matrix/client/v3/rooms/{roomId}/hierarchy
  Future<Either<Failure, Map<String, dynamic>>> getSpaceRooms({
    required String homeserver,
    required String accessToken,
    required String spaceId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/rooms/$spaceId/hierarchy');

      _logger.i('Fetching space rooms for $spaceId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _logger.i('Found space hierarchy');
        return Right(data);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to fetch space rooms',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e, stackTrace) {
      _logger.e('Error fetching space rooms', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Create a new space
  /// POST /_matrix/client/v3/createRoom (with m.space type)
  Future<Either<Failure, SpaceEntity>> createSpace({
    required String homeserver,
    required String accessToken,
    required String name,
    String? topic,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final uri = Uri.parse('$baseUrl/createRoom');

      _logger.i('Creating space: $name');

      final body = {
        'name': name,
        if (topic != null) 'topic': topic,
        'room_type': 'm.space',
        'creation_content': {'type': 'm.space'},
        'preset': 'private_chat',
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final spaceId = data['room_id'] as String;
        _logger.i('Created space: $spaceId');

        return Right(SpaceEntity(
          id: spaceId,
          name: name,
          topic: topic,
          memberCount: 1,
        ));
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to create space',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e, stackTrace) {
      _logger.e('Error creating space', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
