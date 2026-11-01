import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Satu-satunya pintu keluar-masuk token di aplikasi.
/// Semua disimpan di secure storage (Keystore Android / Keychain iOS),
/// bukan SharedPreferences yang plaintext.
///
/// Catatan: sesi login utama dikelola Firebase SDK sendiri. ID token di sini
/// disalin supaya siap dipakai sebagai header Bearer kalau nanti ada backend.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kIdToken = 'firebase_id_token';
  static const _kFcmToken = 'fcm_device_token';

  Future<void> saveIdToken(String? token) async {
    if (token == null) {
      await _storage.delete(key: _kIdToken);
    } else {
      await _storage.write(key: _kIdToken, value: token);
    }
  }

  Future<String?> readIdToken() => _storage.read(key: _kIdToken);

  Future<void> saveFcmToken(String token) =>
      _storage.write(key: _kFcmToken, value: token);

  Future<String?> readFcmToken() => _storage.read(key: _kFcmToken);

  /// Dipanggil saat logout. Token FCM sengaja tidak dihapus karena itu
  /// identitas perangkat, bukan identitas user.
  Future<void> clearSession() => _storage.delete(key: _kIdToken);
}

/// Token jangan pernah di-log utuh. Fungsi ini menyisakan awal dan akhir saja.
String maskToken(String? token) {
  if (token == null || token.isEmpty) return '-';
  if (token.length <= 12) return '****';
  return '${token.substring(0, 6)}...${token.substring(token.length - 4)}';
}
