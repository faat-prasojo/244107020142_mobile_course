import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../auth/login_page.dart';
import '../pages/announcement_page.dart';
import '../pages/home_page.dart';

/// Semua path ada di satu tempat supaya tidak ada string rute yang tersebar.
abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const announcement = '/announcement';

  /// Rute yang boleh dituju dari `data.route` di payload FCM.
  /// Sengaja whitelist: payload berasal dari luar aplikasi, jadi jangan
  /// langsung dipercaya. /login tidak masuk karena bukan tujuan notifikasi.
  static const deepLinkable = {home, announcement};
}

/// Dipakai FCM handler untuk menampilkan banner saat app di foreground,
/// tanpa perlu BuildContext.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  // GoRouter perlu Listenable untuk re-evaluasi redirect saat status login berubah.
  final authChanged = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => authChanged.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authChanged,
    redirect: (context, state) {
      final loggedIn = ref.read(authControllerProvider) != null;
      final atLogin = state.matchedLocation == AppRoutes.login;

      if (!loggedIn) return atLogin ? null : AppRoutes.login;
      if (atLogin) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.announcement,
        builder: (context, state) => const AnnouncementPage(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authChanged.dispose();
  });
  return router;
});
