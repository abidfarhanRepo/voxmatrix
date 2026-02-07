import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/domain/repositories/chat_repository.dart';

@injectable
class SendTypingNotificationUseCase {
  const SendTypingNotificationUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, void>> call({
    required String roomId,
    bool isTyping = true,
  }) {
    return _repository.sendTypingNotification(
      roomId: roomId,
      isTyping: isTyping,
    );
  }
}
