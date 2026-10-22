import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'token_store.dart';

/// State-nya adalah user Firebase yang sedang login (null = belum login).
final authControllerProvider =
    NotifierProvider<AuthController, User?>(AuthController.new);

class AuthController extends Notifier<User?> {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  User? build() {
    // idTokenChanges emit saat login, logout, DAN saat Firebase me-refresh ID token
    // (tiap ~1 jam). Jadi token di TokenStore selalu ikut segar tanpa interceptor manual.
    final sub = _auth.idTokenChanges().listen(_onTokenChanged);
    ref.onDispose(sub.cancel);
    return _auth.currentUser;
  }

  Future<void> _onTokenChanged(User? user) async {
    final store = ref.read(tokenStoreProvider);
    state = user;
    if (user == null) {
      await store.clearSession();
      return;
    }
    try {
      await store.saveIdToken(await user.getIdToken());
    } catch (_) {
      // Gagal ambil token (mis. offline) tidak boleh menjatuhkan sesi.
    }
  }

  /// Return null kalau sukses, atau pesan error siap tampil untuk UI.
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return authErrorMessage(e.code);
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return authErrorMessage(e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();
}

/// Memetakan kode error FirebaseAuth ke pesan yang dimengerti pengguna.
String authErrorMessage(String code) {
  switch (code) {
    case 'invalid-credential':
    case 'user-not-found':
    case 'wrong-password':
      return 'Email atau password salah.';
    case 'invalid-email':
      return 'Format email tidak valid.';
    case 'user-disabled':
      return 'Akun ini dinonaktifkan.';
    case 'email-already-in-use':
      return 'Email sudah terdaftar. Coba login.';
    case 'weak-password':
      return 'Password terlalu lemah (minimal 6 karakter).';
    case 'too-many-requests':
      return 'Terlalu banyak percobaan. Coba lagi beberapa saat.';
    case 'network-request-failed':
      return 'Tidak ada koneksi internet.';
    case 'operation-not-allowed':
      return 'Metode Email/Password belum diaktifkan di Firebase Console.';
    default:
      return 'Terjadi kesalahan ($code).';
  }
}
