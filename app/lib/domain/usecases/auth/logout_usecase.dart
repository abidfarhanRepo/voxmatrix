import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import '../../repositories/auth_repository.dart';

@injectable
class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, void>> call() async {
    return await _repository.logout();
  }
}
