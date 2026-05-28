abstract class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RemoteDataSourceException extends AppException {
  const RemoteDataSourceException(super.message);
}

class LocalDataSourceException extends AppException {
  const LocalDataSourceException(super.message);
}
