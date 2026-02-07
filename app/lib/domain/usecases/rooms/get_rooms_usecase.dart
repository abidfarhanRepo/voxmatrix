import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import '../../entities/room.dart';
import '../../repositories/room_repository.dart';

@injectable
class GetRoomsUseCase {
  const GetRoomsUseCase(this._repository);

  final RoomRepository _repository;

  Future<Either<Failure, List<RoomEntity>>> call() async {
    return await _repository.getRooms();
  }
}
