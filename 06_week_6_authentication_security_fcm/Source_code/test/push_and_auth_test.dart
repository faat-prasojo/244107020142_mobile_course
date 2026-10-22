import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_6_authentication_security_fcm/auth/auth_controller.dart';
import 'package:week_6_authentication_security_fcm/auth/token_store.dart';
import 'package:week_6_authentication_security_fcm/messaging/push_service.dart';
import 'package:week_6_authentication_security_fcm/router/app_router.dart';

void main() {
  group('routeFromMessage', () {
    test('memakai data.route kalau ada di whitelist', () {
      final msg = RemoteMessage(data: {'route': '/home'});
      expect(routeFromMessage(msg), AppRoutes.home);
    });

    test('fallback ke /announcement kalau data.route tidak ada', () {
      final msg = RemoteMessage();
      expect(routeFromMessage(msg), AppRoutes.announcement);
    });

    test('menolak rute di luar whitelist', () {
      for (final bad in ['/login', 'https://evil.example', '/admin', '']) {
        final msg = RemoteMessage(data: {'route': bad});
        expect(routeFromMessage(msg), AppRoutes.announcement, reason: bad);
      }
    });
  });

  group('maskToken', () {
    test('null dan kosong jadi "-"', () {
      expect(maskToken(null), '-');
      expect(maskToken(''), '-');
    });

    test('token pendek disembunyikan total', () {
      expect(maskToken('abc123'), '****');
    });

    test('token panjang hanya menampilkan awal dan akhir', () {
      expect(maskToken('ABCDEF0123456789WXYZ'), 'ABCDEF...WXYZ');
    });
  });

  group('authErrorMessage', () {
    test('invalid-credential dipetakan ke pesan ramah', () {
      expect(authErrorMessage('invalid-credential'), 'Email atau password salah.');
    });

    test('kode tak dikenal tetap menyertakan kodenya', () {
      expect(authErrorMessage('xyz'), contains('xyz'));
    });
  });
}
