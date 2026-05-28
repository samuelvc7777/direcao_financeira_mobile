import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class RegisterUseCase {
  final IAuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, UserEntity>> execute(
    String name,
    String email,
    String password,
  ) async {
    if (name.trim().isEmpty) {
      return Left(ValidationFailure('O nome é obrigatório.'));
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return Left(ValidationFailure('Informe um e-mail válido.'));
    }

    final passwordRegex = RegExp(r'(?=.*\W+)(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$');

    if (password.length < 8) {
      return Left(ValidationFailure('A senha deve ter no mínimo 8 caracteres.'));
    }

    if (!passwordRegex.hasMatch(password)) {
      return Left(ValidationFailure('Senha fraca! Use maiúsculas, minúsculas e símbolos.'));
    }

    return await repository.register(name, email, password);
  }
}
