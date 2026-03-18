import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CacheHelper {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );
  static final Map<String, String> _memory = {};

  static Future<void> init() async {
    final all = await _storage.readAll(aOptions: AndroidOptions());
    _memory.addAll(all);
  }

  static String getString(String key) {
    return _memory[key] ?? '';
  }

  static Future<void> setString(String key, String value) async {
    _memory[key] = value;
    await _storage.write(key: key, value: value);
  }

  static int getInt(String key) {
    return int.tryParse(_memory[key] ?? '') ?? 0;
  }

  static Future<void> setInt(String key, int value) async {
    _memory[key] = value.toString();
    await _storage.write(key: key, value: value.toString());
  }

  static void removeLocal(String key) {
    _memory.remove(key);
  }

  static Future<void> remove(String key) async {
    _memory.remove(key);
    await _storage.delete(key: key);
  }
}
