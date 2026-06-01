import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_models.dart';

class AuthApi {
  final ApiClient _client;
  AuthApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  Future<LoginResult> login(String email, String password) async {
    try {
      final res = await _client.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = unwrap(res);
      final result = LoginResult.fromJson(data);
      await _client.saveToken(result.accessToken);
      return result;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout');
    } on DioException catch (_) {
      // Tetap hapus token lokal meski request gagal
    } finally {
      await _client.clearToken();
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _client.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<void> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _client.dio.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}

ApiException handleDioError(DioException e) {
  if (e.response != null) {
    final json = e.response!.data;
    if (json is Map<String, dynamic> && json['error'] != null) {
      final err = json['error'] as Map<String, dynamic>;
      return ApiException(
        err['message'] as String? ?? 'Terjadi kesalahan',
        statusCode: e.response!.statusCode,
      );
    }
    return ApiException(
      'Server error (${e.response!.statusCode})',
      statusCode: e.response!.statusCode,
    );
  }
  return const ApiException('Tidak dapat terhubung ke server');
}
