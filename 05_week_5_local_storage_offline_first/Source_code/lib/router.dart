import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'pages/home_shell.dart';
import 'pages/note_detail_page.dart';

/// Parameter dibuat opsional supaya test bisa memulai dari `/note/1`
/// dan mengganti HomeShell (yang membuka SQLite sungguhan) dengan widget palsu.
GoRouter createRouter({
  String initialLocation = '/',
  WidgetBuilder? homeBuilder,
}) {
  final WidgetBuilder home = homeBuilder ?? (_) => const HomeShell();
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => home(context),
      ),
      GoRoute(
        path: '/note/:id',
        builder: (context, state) {
          // tryParse, bukan parse: URL seperti /note/abc tidak boleh crash.
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return id == null
              ? const InvalidNotePage()
              : NoteDetailPage(id: id);
        },
      ),
    ],
  );
}

// Lewat provider supaya instance GoRouter tidak dibuat ulang setiap MyApp
// rebuild (mis. saat tema berganti), yang akan mereset tumpukan navigasi.
final routerProvider = Provider<GoRouter>((ref) {
  final router = createRouter();
  ref.onDispose(router.dispose);
  return router;
});
