import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import '../../entities/message_entity.dart';
import '../../repositories/chat_repository.dart';

@injectable
class GetMessagesUseCase {
  const GetMessagesUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, List<MessageEntity>>> call({
    required String roomId,
    int limit = 50,
    String? from,
  }) async {
    return await _repository.getMessages(
      roomId: roomId,
      limit: limit,
      from: from,
    );
  }
}
