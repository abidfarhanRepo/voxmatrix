import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import '../../repositories/chat_repository.dart';

@injectable
class UploadFileUseCase {
  const UploadFileUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, String>> call({
    required String filePath,
    required String roomId,
  }) async {
    return await _repository.uploadFile(
      filePath: filePath,
      roomId: roomId,
    );
  }
}
