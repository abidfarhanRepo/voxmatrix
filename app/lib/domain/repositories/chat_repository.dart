import 'package:dartz/dartz.dart';
import 'package:voxmatrix/core/error/failures.dart';
import '../entities/message_entity.dart';
import '../entities/room.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<MessageEntity>>> getMessages({
    required String roomId,
    int limit = 50,
    String? from,
  });

  Future<Either<Failure, MessageEntity>> sendMessage({
    required String roomId,
    required String content,
    String? replyToId,
    List<Attachment>? attachments,
  });

  Future<Either<Failure, MessageEntity>> editMessage({
    required String roomId,
    required String messageId,
    required String newContent,
  });

  Future<Either<Failure, void>> deleteMessage({
    required String roomId,
    required String messageId,
  });

  Future<Either<Failure, String>> addReaction({
    required String roomId,
    required String messageId,
    required String emoji,
  });

  Future<Either<Failure, void>> removeReaction({
    required String roomId,
    required String reactionEventId,
  });

  Future<Either<Failure, String>> uploadFile({
    required String filePath,
    required String roomId,
  });

  Future<Either<Failure, void>> sendTypingNotification({
    required String roomId,
    bool isTyping = true,
  });

  Future<Either<Failure, void>> markAsRead({
    required String roomId,
    required String messageId,
  });

  Stream<Either<Failure, MessageEntity>> getMessagesStream(String roomId);

  Stream<Either<Failure, List<String>>> getTypingUsers(String roomId);
}
