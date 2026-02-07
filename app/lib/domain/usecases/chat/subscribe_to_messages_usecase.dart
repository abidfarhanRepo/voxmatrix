import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import '../../entities/message_entity.dart';
import '../../repositories/chat_repository.dart';

@injectable
class SubscribeToMessagesUseCase {
  const SubscribeToMessagesUseCase(this._repository);

  final ChatRepository _repository;

  Stream<Either<Failure, MessageEntity>> call({
    required String roomId,
  }) {
    return _repository.getMessagesStream(roomId);
  }
}
