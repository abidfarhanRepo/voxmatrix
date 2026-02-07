import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import '../../entities/room.dart';
import '../../repositories/room_repository.dart';

@injectable
class CreateRoomUseCase {
  const CreateRoomUseCase(this._repository);

  final RoomRepository _repository;

  Future<Either<Failure, RoomEntity>> call({
    required String name,
    String? topic,
    bool isDirect = false,
    bool isPrivate = false,
    List<String> inviteUsers = const [],
  }) async {
    // For Matrix, private rooms use preset "private_chat"
    // and public rooms don't exist in the same way
    return await _repository.createRoom(
      name: name,
      topic: topic,
      isDirect: isDirect,
      isPrivate: isPrivate,
      inviteUsers: inviteUsers,
    );
  }
}
