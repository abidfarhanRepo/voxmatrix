import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/domain/entities/call.dart';
import 'package:voxmatrix/domain/repositories/call_repository.dart';

@injectable
class CreateCallUseCase {
  const CreateCallUseCase(this._repository);

  final CallRepository _repository;

  Future<Either<Failure, CallEntity>> call({
    required String roomId,
    required String calleeId,
    required bool isVideoCall,
  }) {
    return _repository.createCall(
      roomId: roomId,
      calleeId: calleeId,
      isVideoCall: isVideoCall,
    );
  }
}
