import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import '../../entities/message_entity.dart';
import '../../repositories/chat_repository.dart';

@injectable
class EditMessageUseCase {
  const EditMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, MessageEntity>> call({
    required String roomId,
    required String messageId,
    required String newContent,
  }) async {
    return await _repository.editMessage(
      roomId: roomId,
      messageId: messageId,
      newContent: newContent,
    );
  }
}
