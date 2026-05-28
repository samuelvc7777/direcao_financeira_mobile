import 'package:get_storage/get_storage.dart';

abstract class AppPreferences {
  bool? readBool(String key);
  int? readInt(String key);
  double? readDouble(String key);
  String? readString(String key);
  Future<void> writeBool(String key, bool value);
  Future<void> writeInt(String key, int value);
  Future<void> writeDouble(String key, double value);
  Future<void> writeString(String key, String value);
}

class GetStorageAppPreferences implements AppPreferences {
  GetStorageAppPreferences({required this.storage});

  final GetStorage storage;

  @override
  bool? readBool(String key) => storage.read<bool>(key);

  @override
  int? readInt(String key) => storage.read<int>(key);

  @override
  double? readDouble(String key) => storage.read<double>(key);

  @override
  String? readString(String key) => storage.read<String>(key);

  @override
  Future<void> writeBool(String key, bool value) => storage.write(key, value);

  @override
  Future<void> writeInt(String key, int value) => storage.write(key, value);

  @override
  Future<void> writeDouble(String key, double value) =>
      storage.write(key, value);

  @override
  Future<void> writeString(String key, String value) =>
      storage.write(key, value);
}
