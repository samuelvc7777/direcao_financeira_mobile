import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class IAuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, UserEntity>> register(
    String name,
    String email,
    String password,
  );
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);
  Future<Either<Failure, void>> updatePassword(String password);
  Future<Either<Failure, UserEntity>> updateProfilePhotoBase64(
    String? profilePhotoBase64,
  );
  Future<Either<Failure, void>> saveToken(String token);
  Future<Either<Failure, String?>> getToken();
  Future<Either<Failure, void>> saveUser(UserEntity user);
  Either<Failure, UserEntity?> getStoredUser();
  Future<Either<Failure, void>> logout();
}
