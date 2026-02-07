import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import '../../repositories/room_repository.dart';

@injectable
class JoinRoomUseCase {
  const JoinRoomUseCase(this._repository);

  final RoomRepository _repository;

  Future<Either<Failure, void>> call(String roomId) async {
    return await _repository.joinRoom(roomId);
  }
}
