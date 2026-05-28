import '../dtos/auth_session_dto.dart';
import '../models/user_model.dart';

abstract class IAuthRemoteDataSource {
  Future<AuthSessionDto> login({
    required String email,
    required String password,
  });

  Future<AuthSessionDto> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> updatePassword({required String password});

  Future<UserModel> updateProfilePhotoBase64({
    required String? profilePhotoBase64,
  });
}
