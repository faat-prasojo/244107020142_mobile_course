import 'package:dio/dio.dart';

String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat. Silakan periksa jaringan Anda dan coba lagi.';
      case DioExceptionType.connectionError:
        return 'Gagal terhubung ke server. Pastikan koneksi internet Anda aktif.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return 'Data tidak ditemukan (404).';
        } else if (statusCode == 500) {
          return 'Terjadi masalah pada server (500). Silakan coba lagi nanti.';
        }
        return 'Terjadi kesalahan pada server ($statusCode).';
      default:
        return 'Terjadi kesalahan jaringan yang tidak terduga.';
    }
  }
  return 'Terjadi kesalahan: ${error.toString()}';
}