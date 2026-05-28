abstract class SessionStore {
  Future<void> saveToken(String token);
  String? getToken();
  Future<void> clearToken();
}
