import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'repositories/post_repository.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

// Toggle offline deterministik. Dipakai Notifier, bukan StateProvider,
// karena StateProvider dipindah ke legacy di Riverpod 3.
// Trade-off vs connectivity_plus: toggle tidak mendeteksi koneksi asli,
// tapi demo dan test tidak bergantung Wi-Fi.
class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);