import '../../core/session/authenticated_session.dart';
import '../models/user_model.dart';

class AuthSessionDto extends AuthenticatedSession {
  AuthSessionDto({required super.token, required UserModel super.user});

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'];
    final user = json['user'];

    if (token is! String || token.isEmpty) {
      throw const FormatException('Token ausente na resposta de autenticacao.');
    }

    if (user is! Map) {
      throw const FormatException(
        'Usuario ausente na resposta de autenticacao.',
      );
    }

    return AuthSessionDto(
      token: token,
      user: UserModel.fromJson(Map<String, dynamic>.from(user)),
    );
  }
}
