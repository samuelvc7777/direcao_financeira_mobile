import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class LoginUseCase {
  final IAuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, UserEntity>> execute(String email, String password) async {
    if (email.isEmpty || !email.contains('@')) {
      return Left(ValidationFailure('Por favor, informe um e-mail válido.'));
    }
    if (password.length < 6) {
      return Left(ValidationFailure('A senha deve ter pelo menos 6 caracteres.'));
    }

    return await repository.login(email, password);
  }
}
