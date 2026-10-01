import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'local/db.dart';
import 'local/note.dart';
import 'models/post.dart';
import 'network_errors.dart';
import 'providers.dart';
import 'repositories/note_repository.dart';

// ---------- Cache posts ----------

class PostCacheRepository {
  PostCacheRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;
  final Future<Database> Function() _openDb;

  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');
    return rows
        .map((r) => Post.fromJson(
            jsonDecode(r['payload'] as String) as Map<String, dynamic>))
        .toList();
  }

  // Replace-all dalam satu transaction: atomik, dan post yang sudah hilang
  // di server ikut terhapus. Trade-off vs upsert: menulis ulang seluruh tabel
  // tiap refresh, tapi untuk 100 posts itu murah dan jauh lebih sederhana.
  Future<void> replaceCache(List<Post> posts) async {
    final db = await _openDb();
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete('cached_posts');
      final batch = txn.batch();
      for (final p in posts) {
        batch.insert('cached_posts', {
          'id': p.id,
          'payload': jsonEncode(p.toJson()),
          'cached_at': now,
        });
      }
      await batch.commit(noResult: true);
    });
  }
}

final postCacheRepositoryProvider =
    Provider((ref) => PostCacheRepository());

class CachedPostsNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    final cached =
        await ref.read(postCacheRepositoryProvider).readCachedPosts();

    // Cache kosong (first launch): tidak ada yang bisa ditampilkan,
    // jadi tunggu network. Kalau gagal -> AsyncError -> UI tampil pesan + retry.
    if (cached.isEmpty) return _fetchAndStore();

    // Cache ada: tampilkan seketika, refresh di belakang layar.
    unawaited(_refreshInBackground());
    return cached;
  }

  Future<List<Post>> _fetchAndStore() async {
    if (ref.read(forceOfflineProvider)) throw const OfflineException();
    final posts = await ref.read(postRepositoryProvider).fetchPosts();
    await ref.read(postCacheRepositoryProvider).replaceCache(posts);
    return posts;
  }

  // Hasil refresh langsung diisi ke state. TIDAK memanggil invalidate,
  // karena invalidate akan memicu build() -> refresh lagi -> loop tak berujung.
  Future<void> _refreshInBackground() async {
    try {
      final fresh = await _fetchAndStore();
      if (!ref.mounted) return; // provider sudah di-dispose (Riverpod 3)
      state = AsyncData(fresh);
    } catch (_) {
      // Offline/timeout: cache tetap tampil, jangan ubah state jadi error.
    }
  }
}

final cachedPostsProvider =
    AsyncNotifierProvider<CachedPostsNotifier, List<Post>>(
  CachedPostsNotifier.new,
  retry: (retryCount, error) => null,
);

// ---------- Antrean sinkronisasi catatan ----------

// Return: jumlah catatan yang berhasil disinkronkan.
// Signature kompatibel dengan contoh codelab: syncNotes(repo).
Future<int> syncNotes(
  NoteRepository repo, {
  bool online = true,
  Future<void> Function(Note)? upload,
}) async {
  if (!online) return 0;
  final queue = await repo.fetchDirty();
  var synced = 0;
  for (final note in queue) {
    try {
      await (upload ?? _fakeUpload)(note); // simulasi POST ke server
      await repo.markSynced(note); // bersihkan per item, bukan massal
      synced++;
    } catch (_) {
      // Berhenti di item gagal agar urutan terjaga; sisanya tetap dirty.
      break;
    }
  }
  return synced;
}

Future<void> _fakeUpload(Note n) =>
    Future.delayed(const Duration(milliseconds: 300));