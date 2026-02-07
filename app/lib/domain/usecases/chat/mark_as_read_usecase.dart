import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/domain/repositories/chat_repository.dart';

@lazySingleton
class MarkAsReadUseCase {
  const MarkAsReadUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, void>> call({
    required String roomId,
    required String messageId,
  }) {
    return _repository.markAsRead(
      roomId: roomId,
      messageId: messageId,
    );
  }
}
