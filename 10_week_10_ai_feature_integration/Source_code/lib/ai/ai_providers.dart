import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_key_store.dart';
import 'ai_service.dart';

final aiKeyStoreProvider = Provider<AiKeyStore>((ref) => SecureAiKeyStore());

final aiServiceProvider = Provider<AiService>((ref) {
  final service = AiService();
  ref.onDispose(service.dispose);
  return service;
});

/// Status konfigurasi API key untuk banner/empty state.
final aiKeyStatusProvider = FutureProvider<bool>((ref) {
  return ref.watch(aiKeyStoreProvider).hasKey();
});
