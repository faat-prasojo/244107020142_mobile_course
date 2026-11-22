enum AiErrorKind {
  missingKey,
  invalidKey,
  rateLimit,
  network,
  timeout,
  server,
  emptyResponse,
  generic,
}

/// Error yang sudah dipetakan menjadi pesan ramah untuk pengguna.
/// Pesan mentah dari server tidak pernah ditampilkan.
class AiException implements Exception {
  const AiException(this.message, {this.kind = AiErrorKind.generic});

  final String message;
  final AiErrorKind kind;

  factory AiException.fromStatus(int statusCode) {
    if (statusCode == 400) {
      return const AiException(
        'Permintaan tidak valid. Coba ubah pertanyaanmu.',
        kind: AiErrorKind.generic,
      );
    }
    if (statusCode == 401 || statusCode == 403) {
      return const AiException(
        'API key tidak valid atau tidak memiliki akses. Periksa pengaturan AI.',
        kind: AiErrorKind.invalidKey,
      );
    }
    if (statusCode == 404) {
      return const AiException(
        'Model AI tidak ditemukan. Periksa konfigurasi provider.',
        kind: AiErrorKind.generic,
      );
    }
    if (statusCode == 429) {
      return const AiException(
        'Batas permintaan AI tercapai. Coba lagi beberapa saat lagi.',
        kind: AiErrorKind.rateLimit,
      );
    }
    if (statusCode >= 500) {
      return const AiException(
        'Layanan AI sedang bermasalah. Coba lagi nanti.',
        kind: AiErrorKind.server,
      );
    }
    return const AiException(
      'Permintaan ke layanan AI gagal. Coba lagi.',
      kind: AiErrorKind.generic,
    );
  }

  static const missingKey = AiException(
    'API key belum diatur. Buka Pengaturan AI untuk menambahkannya.',
    kind: AiErrorKind.missingKey,
  );

  static const network = AiException(
    'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.',
    kind: AiErrorKind.network,
  );

  static const timeout = AiException(
    'Permintaan AI memakan waktu terlalu lama. Coba lagi.',
    kind: AiErrorKind.timeout,
  );

  static const emptyResponse = AiException(
    'AI tidak mengembalikan jawaban. Coba lagi dengan pertanyaan lain.',
    kind: AiErrorKind.emptyResponse,
  );

  @override
  String toString() => message;
}
