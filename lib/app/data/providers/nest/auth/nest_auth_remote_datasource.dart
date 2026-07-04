import 'package:dio/dio.dart';

import '../../../datasources/auth_datasource.dart';
import '../../../dtos/auth_session_dto.dart';
import '../../../models/user_model.dart';

class NestAuthRemoteDataSource implements IAuthRemoteDataSource {
  NestAuthRemoteDataSource({required this.dio});

  final Dio dio;

  @override
  Future<AuthSessionDto> login({
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    return AuthSessionDto.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<AuthSessionDto> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );

    return AuthSessionDto.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await dio.post('/auth/forgot-password', data: {'email': email});
  }

  @override
  Future<void> updatePassword({required String password}) async {
    await dio.post('/auth/reset-password', data: {'password': password});
  }

  @override
  Future<UserModel> updateProfilePhotoBase64({
    required String? profilePhotoBase64,
  }) async {
    throw UnsupportedError(
      'Atualizacao de foto de perfil ainda nao esta disponivel no backend Nest.',
    );
  }
}
