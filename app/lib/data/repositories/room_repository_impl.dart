import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/data/datasources/room_remote_datasource.dart';
import 'package:voxmatrix/data/datasources/room_management_remote_datasource.dart';
import 'package:voxmatrix/data/models/room_model.dart';
import 'package:voxmatrix/domain/entities/room.dart';
import 'package:voxmatrix/domain/repositories/room_repository.dart';

/// Room repository implementation - uses Matrix Client-Server API
@LazySingleton(as: RoomRepository)
class RoomRepositoryImpl implements RoomRepository {
  RoomRepositoryImpl(
    this._remoteDataSource,
    this._managementDataSource,
    this._localDataSource,
    this._logger,
  );

  final RoomRemoteDataSource _remoteDataSource;
  final RoomManagementRemoteDataSource _managementDataSource;
  final AuthLocalDataSource _localDataSource;
  final Logger _logger;

  // Stream controller for real-time updates
  final _roomsStreamController =
      StreamController<Either<Failure, List<RoomEntity>>>.broadcast();
  String? _nextBatchToken;
  bool _isSyncing = false;

  /// Get stored credentials
  Future<_Credentials?> _getCredentials() async {
    try {
      final token = await _localDataSource.getAccessToken();
      final homeserver = await _localDataSource.getHomeserver();

      if (token == null || homeserver == null) {
        return null;
      }

      return _Credentials(accessToken: token, homeserver: homeserver);
    } catch (e) {
      _logger.e('Error getting credentials', error: e);
      return null;
    }
  }

  @override
  Future<Either<Failure, List<RoomEntity>>> getRooms() async {
    final creds = await _getCredentials();
    if (creds == null) {
      return const Left(AuthFailure(
        message: 'Not authenticated',
        statusCode: 401,
      ));
    }

    // Get current user ID for proper room name generation
    final currentUserId = await _localDataSource.getUserId();

    final result = await _remoteDataSource.getRooms(
      homeserver: creds.homeserver,
      accessToken: creds.accessToken,
      currentUserId: currentUserId,
    );

    return result.fold(
      (failure) => Left(failure),
      (roomsData) {
        try {
          final rooms = roomsData.map((roomData) {
            // Convert members from List<Map> to List<RoomMemberModel>
            final memberList = (roomData['members'] as List? ?? [])
                .map((m) => RoomMemberModel(
                      userId: m['userId'] as String,
                      displayName: m['displayName'] as String? ?? m['userId'] as String,
                      avatarUrl: m['avatarUrl'] as String?,
                      presence: PresenceState.offline,
                    ))
                .toList();

            // Convert lastMessage from Map to MessageSummaryModel
            MessageSummaryModel? lastMsg;
            final lastMessageData = roomData['lastMessage'] as Map<String, dynamic>?;
            if (lastMessageData != null) {
              lastMsg = MessageSummaryModel(
                content: lastMessageData['content'] as String? ?? '',
                timestamp: lastMessageData['timestamp'] is DateTime
                    ? lastMessageData['timestamp'] as DateTime
                    : DateTime.now(),
                senderName: lastMessageData['senderName'] as String? ?? 'Unknown',
              );
            }

            return RoomModel(
              id: roomData['id'] as String,
              name: roomData['name'] as String,
              isDirect: roomData['isDirect'] as bool? ?? false,
              timestamp: DateTime.now(),
              topic: roomData['topic'] as String?,
              avatarUrl: roomData['avatarUrl'] as String?,
              lastMessage: lastMsg,
              unreadCount: roomData['unreadCount'] as int? ?? 0,
              members: memberList,
              isFavourite: false,
              isMuted: false,
            );
          }).toList();

          return Right(rooms.map((r) => r.toEntity()).toList());
        } catch (e, stackTrace) {
          _logger.e('Error parsing room data', error: e, stackTrace: stackTrace);
          return Left(ServerFailure(message: 'Failed to parse room data: $e'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, RoomEntity>> getRoomById(String roomId) async {
    final creds = await _getCredentials();
    if (creds == null) {
      return const Left(AuthFailure(
        message: 'Not authenticated',
        statusCode: 401,
      ));
    }

    final result = await _remoteDataSource.getRoomState(
      homeserver: creds.homeserver,
      accessToken: creds.accessToken,
      roomId: roomId,
    );

    return result.fold(
      (failure) => Left(failure),
      (data) {
        // Parse room state and return RoomEntity
        // This is a simplified version
        return Right(RoomEntity(
          id: roomId,
          name: roomId,
          topic: null,
          avatarUrl: null,
          isDirect: false,
          timestamp: DateTime.now(),
          isFavourite: false,
          isMuted: false,
          members: [],
          lastMessage: null,
          unreadCount: 0,
        ));
      },
    );
  }

  @override
  Future<Either<Failure, RoomEntity>> createRoom({
    required String name,
    String? topic,
    bool isDirect = false,
    bool isPrivate = false,
    List<String> inviteUsers = const [],
  }) async {
    final creds = await _getCredentials();
    if (creds == null) {
      return const Left(AuthFailure(
        message: 'Not authenticated',
        statusCode: 401,
      ));
    }

    final result = await _managementDataSource.createRoom(
      homeserver: creds.homeserver,
      accessToken: creds.accessToken,
      name: name,
      topic: topic,
      isDirect: isDirect,
      isPublic: !isPrivate,
      inviteUserIds: inviteUsers,
    );

    return result.fold(
      (failure) => Left(failure),
      (data) {
        final roomId = data['room_id'] as String;
        return Right(RoomEntity(
          id: roomId,
          name: name,
          topic: topic,
          isDirect: isDirect,
          timestamp: DateTime.now(),
        ));
      },
    );
  }

  @override
  Future<Either<Failure, void>> joinRoom(String roomId) async {
    final creds = await _getCredentials();
    if (creds == null) {
      return const Left(AuthFailure(
        message: 'Not authenticated',
        statusCode: 401,
      ));
    }

    final result = await _remoteDataSource.joinRoom(
      homeserver: creds.homeserver,
      accessToken: creds.accessToken,
      roomIdOrAlias: roomId,
    );

    return result.fold(
      (failure) => Left(failure),
      (_) => const Right(null),
    );
  }

  @override
  Future<Either<Failure, void>> leaveRoom(String roomId) async {
    final creds = await _getCredentials();
    if (creds == null) {
      return const Left(AuthFailure(
        message: 'Not authenticated',
        statusCode: 401,
      ));
    }

    final result = await _remoteDataSource.leaveRoom(
      homeserver: creds.homeserver,
      accessToken: creds.accessToken,
      roomId: roomId,
    );

    return result.fold(
      (failure) => Left(failure),
      (_) => const Right(null),
    );
  }

  @override
  Future<Either<Failure, void>> inviteToRoom({
    required String roomId,
    required String userId,
  }) async {
    // TODO: Implement Matrix invite API
    return Left(UnknownFailure(message: 'Invite not implemented yet'));
  }

  @override
  Future<Either<Failure, void>> kickFromRoom({
    required String roomId,
    required String userId,
    required String reason,
  }) async {
    // TODO: Implement Matrix kick API
    return Left(UnknownFailure(message: 'Kick not implemented yet'));
  }

  @override
  Future<Either<Failure, void>> updateRoom({
    required String roomId,
    String? name,
    String? topic,
    String? avatarUrl,
  }) async {
    // TODO: Implement Matrix room state update API
    return Left(UnknownFailure(message: 'Update room not implemented yet'));
  }

  @override
  Future<Either<Failure, void>> favouriteRoom(
    String roomId,
    bool isFavourite,
  ) async {
    // TODO: Implement Matrix account data API for favourites
    return Left(UnknownFailure(message: 'Favourite not implemented yet'));
  }

  @override
  Future<Either<Failure, void>> muteRoom(String roomId, bool isMuted) async {
    // TODO: Implement Matrix account data API for muted rooms
    return Left(UnknownFailure(message: 'Mute not implemented yet'));
  }

  @override
  Stream<Either<Failure, List<RoomEntity>>> getRoomsStream() {
    // Start periodic sync
    _startPeriodicSync();
    return _roomsStreamController.stream;
  }

  @override
  Stream<Either<Failure, RoomEntity>> getRoomUpdates(String roomId) {
    // TODO: Implement per-room updates
    return Stream.value(
      Left(UnknownFailure(message: 'Room updates not implemented yet')),
    );
  }

  /// Start periodic sync for real-time updates
  void _startPeriodicSync() {
    if (_isSyncing) return;

    _isSyncing = true;
    Timer.periodic(const Duration(seconds: 10), (_) async {
      final rooms = await getRooms();
      _roomsStreamController.add(rooms);
    });
  }

  void dispose() {
    _isSyncing = false;
    _roomsStreamController.close();
  }
}

/// Helper class for credentials
class _Credentials {
  const _Credentials({
    required this.accessToken,
    required this.homeserver,
  });

  final String accessToken;
  final String homeserver;
}
