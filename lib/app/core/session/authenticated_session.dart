import '../../domain/entities/user_entity.dart';

class AuthenticatedSession {
  const AuthenticatedSession({required this.token, required this.user});

  final String token;
  final UserEntity user;
}
