import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/domain/repositories/call_repository.dart';

@injectable
class HangupCallUseCase {
  const HangupCallUseCase(this._repository);

  final CallRepository _repository;

  Future<Either<Failure, void>> call({
    required String callId,
    required String roomId,
    String? reason,
  }) {
    return _repository.hangupCall(
      callId: callId,
      roomId: roomId,
      reason: reason,
    );
  }
}
