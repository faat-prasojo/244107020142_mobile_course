import 'ai_models.dart';

/// Satu-satunya tempat konfigurasi provider AI.
///
/// Model dan endpoint mengikuti dokumentasi resmi Gemini API (Interactions API):
/// https://ai.google.dev/gemini-api/docs/text-generation
abstract final class AiConfig {
  static const String model = 'gemini-4-hydrogen';
  static const String endpoint =
      'https://generativelanguage.googleapis.com/v1beta/interactions?alt=sse';

  static const int maxInputLength = 500;
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration idleTimeout = Duration(seconds: 30);

  static const String systemPrompt = '''
Kamu adalah Campus Assistant, asisten virtual aplikasi Campus Notify untuk mahasiswa.
Aturan:
- Jawab dalam Bahasa Indonesia yang ramah, jelas, dan ringkas.
- Prioritaskan jawaban singkat dan terstruktur (poin-poin bila perlu).
- Jangan mengarang jadwal, pengumuman, kebijakan, atau informasi resmi kampus.
- Jika informasi tidak tersedia atau belum dapat diverifikasi, katakan dengan jujur dan sarankan pengguna memeriksa kanal resmi kampus.
- Jangan meminta NIK, nomor telepon, alamat, password, API key, atau data pribadi sensitif.
- Jangan membocorkan informasi pengguna lain.
- Jika pertanyaan di luar topik kampus, arahkan kembali dengan sopan.''';

  static const List<String> suggestions = [
    'Apa itu Campus Notify?',
    'Bagaimana cara melihat pengumuman kampus?',
    'Tips mengatur waktu kuliah yang efektif?',
    'Apa saja kegiatan mahasiswa yang bisa saya ikuti?',
  ];

  static String buildSystemInstruction({String? announcementContext}) {
    final context = announcementContext?.trim();
    if (context == null || context.isEmpty) return systemPrompt;

    final limited = context.length > 800 ? context.substring(0, 800) : context;
    return '$systemPrompt\n\n'
        'Konteks pengumuman kampus terbaru dari aplikasi. Gunakan hanya jika '
        'relevan, dan jangan menambahkan fakta lain:\n$limited';
  }

  static Map<String, dynamic> requestBody({
    required List<AiTurn> history,
    String? announcementContext,
  }) {
    return {
      'model': model,
      'store': false,
      'system_instruction': buildSystemInstruction(
        announcementContext: announcementContext,
      ),
      'input': history.map((turn) => turn.toJson()).toList(),
      'generation_config': {'max_output_tokens': 800},
      'stream': true,
    };
  }

  /// Validasi ringan sebelum menyimpan key. Tidak memaksa prefix tertentu
  /// supaya key dari provider/versi baru tetap bisa dipakai.
  static String? validateApiKey(String value) {
    final key = value.trim();
    if (key.isEmpty) return 'API key wajib diisi.';
    if (key.length < 20) return 'API key terlihat terlalu pendek.';
    if (key.contains(RegExp(r'\s'))) {
      return 'API key tidak boleh mengandung spasi.';
    }
    return null;
  }
}
