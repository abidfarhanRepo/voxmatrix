import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import '../../repositories/chat_repository.dart';

@injectable
class DeleteMessageUseCase {
  const DeleteMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, void>> call({
    required String roomId,
    required String messageId,
  }) async {
    return await _repository.deleteMessage(
      roomId: roomId,
      messageId: messageId,
    );
  }
}
