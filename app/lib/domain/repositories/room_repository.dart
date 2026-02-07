import 'package:dartz/dartz.dart';
import 'package:voxmatrix/core/error/failures.dart';
import '../entities/room.dart';

abstract class RoomRepository {
  Future<Either<Failure, List<RoomEntity>>> getRooms();

  Future<Either<Failure, RoomEntity>> getRoomById(String roomId);

  Future<Either<Failure, RoomEntity>> createRoom({
    required String name,
    String? topic,
    bool isDirect = false,
    bool isPrivate = false,
    List<String> inviteUsers = const [],
  });

  Future<Either<Failure, void>> joinRoom(String roomId);

  Future<Either<Failure, void>> leaveRoom(String roomId);

  Future<Either<Failure, void>> inviteToRoom({
    required String roomId,
    required String userId,
  });

  Future<Either<Failure, void>> kickFromRoom({
    required String roomId,
    required String userId,
    required String reason,
  });

  Future<Either<Failure, void>> updateRoom({
    required String roomId,
    String? name,
    String? topic,
    String? avatarUrl,
  });

  Future<Either<Failure, void>> favouriteRoom(String roomId, bool isFavourite);

  Future<Either<Failure, void>> muteRoom(String roomId, bool isMuted);

  Stream<Either<Failure, List<RoomEntity>>> getRoomsStream();

  Stream<Either<Failure, RoomEntity>> getRoomUpdates(String roomId);
}
