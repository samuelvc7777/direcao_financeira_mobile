import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class RegisterUseCase {
  RegisterUseCase(this.repository);

  final IAuthRepository repository;

  Future<Either<Failure, UserEntity>> execute(
    String name,
    String email,
    String password,
    String phone, {
    String? referralCode,
  }) async {
    if (name.trim().isEmpty) {
      return Left(ValidationFailure('O nome e obrigatorio.'));
    }

    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return Left(ValidationFailure('Informe um e-mail valido.'));
    }

    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length < 10 || phoneDigits.length > 11) {
      return Left(ValidationFailure('Informe um telefone valido.'));
    }

    final passwordRegex = RegExp(
      r'(?=.*\W+)(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$',
    );

    if (password.length < 8) {
      return Left(
        ValidationFailure('A senha deve ter no minimo 8 caracteres.'),
      );
    }

    if (!passwordRegex.hasMatch(password)) {
      return Left(
        ValidationFailure(
          'Senha fraca! Use maiusculas, minusculas e simbolos.',
        ),
      );
    }

    return repository.register(
      name,
      email,
      password,
      phoneDigits,
      referralCode: referralCode,
    );
  }
}
