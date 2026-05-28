import 'package:get_storage/get_storage.dart';

import '../../core/errors/exceptions.dart';
import '../../core/session/session_store.dart';

class GetStorageSessionStore implements SessionStore {
  GetStorageSessionStore({required this.storage});

  final GetStorage storage;
  static const _tokenKey = 'token';

  @override
  Future<void> saveToken(String token) async {
    try {
      await storage.write(_tokenKey, token);
    } catch (_) {
      throw const LocalDataSourceException('Erro ao salvar token.');
    }
  }

  @override
  String? getToken() {
    try {
      return storage.read<String>(_tokenKey);
    } catch (_) {
      throw const LocalDataSourceException('Erro ao ler token.');
    }
  }

  @override
  Future<void> clearToken() async {
    try {
      await storage.remove(_tokenKey);
    } catch (_) {
      throw const LocalDataSourceException('Erro ao limpar token.');
    }
  }
}
