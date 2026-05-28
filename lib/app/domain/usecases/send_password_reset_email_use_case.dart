import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../repositories/i_auth_repository.dart';

class SendPasswordResetEmailUseCase {
  SendPasswordResetEmailUseCase(this.repository);

  final IAuthRepository repository;

  Future<Either<Failure, void>> execute(String email) async {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return Left(ValidationFailure('Por favor, informe um e-mail valido.'));
    }

    return repository.sendPasswordResetEmail(normalizedEmail);
  }
}
