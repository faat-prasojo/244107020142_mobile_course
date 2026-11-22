import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Pintu keluar-masuk API key. Nilai key tidak pernah ditampilkan di UI/log.
abstract interface class AiKeyStore {
  Future<String?> readKey();
  Future<void> saveKey(String key);
  Future<void> deleteKey();
  Future<bool> hasKey();
}

class SecureAiKeyStore implements AiKeyStore {
  SecureAiKeyStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _keyName = 'gemini_api_key';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readKey() => _storage.read(key: _keyName);

  @override
  Future<void> saveKey(String key) =>
      _storage.write(key: _keyName, value: key.trim());

  @override
  Future<void> deleteKey() => _storage.delete(key: _keyName);

  @override
  Future<bool> hasKey() async {
    final key = await readKey();
    return key != null && key.trim().isNotEmpty;
  }
}
