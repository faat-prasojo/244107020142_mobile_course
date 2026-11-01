import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/token_store.dart';
import '../firebase_options.dart';
import '../router/app_router.dart';

/// Handler untuk pesan yang datang saat app di background / terminated.
/// Syarat dari plugin: harus fungsi TOP-LEVEL (bukan method kelas) dan diberi
/// @pragma('vm:entry-point') supaya tidak dibuang tree-shaking saat release.
/// Handler jalan di isolate terpisah, jadi Firebase harus di-init ulang di sini.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Cukup id pesan saja; isi pesan dan token tidak perlu masuk log.
  debugPrint('[FCM background] id=${message.messageId}');
}

/// Fungsi murni (tanpa efek samping) supaya mudah di-unit-test.
/// Membaca `data.route` dari payload, tapi hanya menerima rute di whitelist.
String routeFromMessage(RemoteMessage message) {
  final raw = message.data['route'];
  if (raw is String && AppRoutes.deepLinkable.contains(raw)) return raw;
  return AppRoutes.announcement;
}

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(ref.read(tokenStoreProvider));
  ref.onDispose(service.dispose);
  return service;
});

class PushService {
  PushService(this._tokenStore);

  static const campusTopic = 'pengumuman-kampus';

  final TokenStore _tokenStore;
  final List<StreamSubscription<dynamic>> _subs = [];
  GoRouter? _router;
  bool _started = false;

  /// Token perangkat terbaru (untuk ditampilkan / disalin ke Firebase Console).
  final ValueNotifier<String?> fcmToken = ValueNotifier(null);

  /// Pesan terakhir yang diterima atau diklik; dibaca AnnouncementPage.
  final ValueNotifier<RemoteMessage?> lastMessage = ValueNotifier(null);

  /// Panggil sekali setelah login dan setelah router siap.
  Future<void> start(GoRouter router) async {
    if (_started) return;
    _started = true;
    _router = router;

    final fm = FirebaseMessaging.instance;

    // Android 13+ dan iOS wajib minta izin runtime.
    final settings = await fm.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] izin notifikasi ditolak');
      _started = false; // coba lagi di login berikutnya
      return;
    }

    // Listener dipasang dulu, baru ambil token, supaya tidak ada pesan terlewat.
    _subs
      ..add(FirebaseMessaging.onMessage.listen(_onForeground))
      ..add(FirebaseMessaging.onMessageOpenedApp.listen(_open))
      ..add(fm.onTokenRefresh.listen(_handleToken));

    try {
      final token = await fm.getToken();
      if (token != null) await _handleToken(token);
    } catch (e) {
      // Umum terjadi di emulator tanpa Google Play Services / iOS tanpa APNs.
      debugPrint('[FCM] getToken gagal: $e');
    }

    // Subscribe topic tidak didukung di web.
    if (!kIsWeb) {
      try {
        await fm.subscribeToTopic(campusTopic);
      } catch (e) {
        debugPrint('[FCM] subscribe topic gagal: $e');
      }
    }

    // State terminated: app dibuka dengan mengetuk notifikasi.
    // Dipanggil di akhir karena router sudah ada dan navigasi baru aman.
    final initial = await fm.getInitialMessage();
    if (initial != null) _open(initial);
  }

  /// Dipanggil saat logout, supaya perangkat tidak terus menerima
  /// pengumuman atas nama akun yang sudah keluar.
  Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    if (!kIsWeb) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(campusTopic);
      } catch (e) {
        debugPrint('[FCM] unsubscribe gagal: $e');
      }
    }
    lastMessage.value = null;
    _started = false;
  }

  Future<void> _handleToken(String token) async {
    fcmToken.value = token;
    await _tokenStore.saveFcmToken(token);
    // Tidak ada backend di tugas ini. Kalau nanti ada, kirim token baru ke
    // endpoint (mis. POST /devices) DI SINI, karena onTokenRefresh juga lewat sini.
    debugPrint('[FCM] token: ${maskToken(token)}');
  }

  /// Foreground: Android tidak menampilkan banner sistem untuk notification
  /// payload, jadi ditampilkan sendiri lewat SnackBar.
  void _onForeground(RemoteMessage message) {
    lastMessage.value = message;
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Pesan baru';

    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(title),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: 'Buka', onPressed: () => _open(message)),
        ),
      );
  }

  /// Dipakai ketiga state: foreground (tombol Buka), background
  /// (onMessageOpenedApp), dan terminated (getInitialMessage).
  void _open(RemoteMessage message) {
    lastMessage.value = message;
    _router?.go(routeFromMessage(message));
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    fcmToken.dispose();
    lastMessage.dispose();
  }
}
