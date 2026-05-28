import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../repositories/i_auth_repository.dart';

class UpdatePasswordUseCase {
  UpdatePasswordUseCase(this.repository);

  final IAuthRepository repository;

  Future<Either<Failure, void>> execute(String password) async {
    final normalizedPassword = password.trim();
    final passwordRegex = RegExp(
      r'(?=.*\W+)(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$',
    );

    if (normalizedPassword.length < 8) {
      return Left(
        ValidationFailure('A senha deve ter no minimo 8 caracteres.'),
      );
    }

    if (!passwordRegex.hasMatch(normalizedPassword)) {
      return Left(
        ValidationFailure(
          'A senha deve conter maiuscula, minuscula e caractere especial.',
        ),
      );
    }

    return repository.updatePassword(normalizedPassword);
  }
}
