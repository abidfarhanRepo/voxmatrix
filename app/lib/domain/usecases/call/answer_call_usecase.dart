import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/domain/repositories/call_repository.dart';

@injectable
class AnswerCallUseCase {
  const AnswerCallUseCase(this._repository);

  final CallRepository _repository;

  Future<Either<Failure, void>> call({
    required String callId,
    required String roomId,
  }) {
    return _repository.answerCall(
      callId: callId,
      roomId: roomId,
    );
  }
}
