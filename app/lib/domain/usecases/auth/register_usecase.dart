import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/failures.dart';
import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

@injectable
class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call({
    required String username,
    required String password,
    required String email,
    required String homeserver,
  }) async {
    return await _repository.register(
      username: username,
      password: password,
      email: email,
      homeserver: homeserver,
    );
  }
}
