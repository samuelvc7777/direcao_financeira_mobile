import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../datasources/auth_datasource.dart';
import '../../../dtos/auth_session_dto.dart';
import '../../../models/user_model.dart';
import '../shared/supabase_user_scope.dart';

class SupabaseAuthRemoteDataSource implements IAuthRemoteDataSource {
  SupabaseAuthRemoteDataSource({required this.client})
    : userScope = SupabaseUserScope(client: client);

  final SupabaseClient client;
  final SupabaseUserScope userScope;

  @override
  Future<AuthSessionDto> login({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final session = response.session;
    if (session == null) {
      throw const AuthException(
        'Nao foi possivel iniciar a sessao no Supabase.',
      );
    }

    final authUser = response.user;
    if (authUser == null) {
      throw const AuthException(
        'Usuario autenticado, mas sem dados retornados pelo Supabase.',
      );
    }

    final name =
        authUser.userMetadata?['name']?.toString() ??
        authUser.email?.split('@').first ??
        'Usuario';
    final user = await userScope.ensureUserProfileForAuthUser(
      email: email,
      name: name,
    );

    return AuthSessionDto(
      token: session.refreshToken ?? session.accessToken,
      user: user,
    );
  }

  @override
  Future<AuthSessionDto> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );

    var session = response.session;
    var authUser = response.user;

    if (session == null) {
      final loginResponse = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      session = loginResponse.session;
      authUser = loginResponse.user ?? authUser;
    }

    if (session == null || authUser == null) {
      throw const AuthException(
        'Cadastro realizado, mas a sessao nao foi iniciada automaticamente no Supabase.',
      );
    }

    final user = await userScope.ensureUserProfileForAuthUser(
      email: email,
      name: name,
    );

    return AuthSessionDto(
      token: session.refreshToken ?? session.accessToken,
      user: user,
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'direcaofinanceira://reset-password',
    );
  }

  @override
  Future<void> updatePassword({required String password}) async {
    await client.auth.updateUser(UserAttributes(password: password));
  }

  @override
  Future<UserModel> updateProfilePhotoBase64({
    required String? profilePhotoBase64,
  }) {
    return userScope.updateCurrentUserProfilePhotoBase64(
      profilePhotoBase64: profilePhotoBase64,
    );
  }
}
