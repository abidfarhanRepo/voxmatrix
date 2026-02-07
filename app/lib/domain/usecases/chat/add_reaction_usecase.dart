import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import '../../repositories/chat_repository.dart';

@injectable
class AddReactionUseCase {
  const AddReactionUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, String>> call({
    required String roomId,
    required String messageId,
    required String emoji,
  }) async {
    return await _repository.addReaction(
      roomId: roomId,
      messageId: messageId,
      emoji: emoji,
    );
  }
}
