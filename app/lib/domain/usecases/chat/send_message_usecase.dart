import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import '../../entities/message_entity.dart';
import '../../repositories/chat_repository.dart';

@injectable
class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, MessageEntity>> call({
    required String roomId,
    required String content,
    String? replyToId,
    List<Attachment>? attachments,
  }) async {
    return await _repository.sendMessage(
      roomId: roomId,
      content: content,
      replyToId: replyToId,
      attachments: attachments,
    );
  }
}
