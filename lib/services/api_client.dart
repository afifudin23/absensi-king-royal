import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

String get kApiBaseUrl =>
    dotenv.env['API_BASE_URL'] ?? 'http://192.168.18.14:8080/api/v1';
const String _kTokenKey = 'auth_token';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  Dio get dio => _dio;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTokenKey);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

Map<String, dynamic> unwrap(Response response) {
  final json = response.data as Map<String, dynamic>;
  if (!(json['success'] as bool)) {
    final err = json['error'] as Map<String, dynamic>?;
    throw ApiException(
      err?['message'] as String? ?? 'Terjadi kesalahan',
      statusCode: response.statusCode,
    );
  }
  return json['data'] as Map<String, dynamic>;
}

List<dynamic> unwrapList(Response response) {
  final json = response.data as Map<String, dynamic>;
  if (!(json['success'] as bool)) {
    final err = json['error'] as Map<String, dynamic>?;
    throw ApiException(
      err?['message'] as String? ?? 'Terjadi kesalahan',
      statusCode: response.statusCode,
    );
  }
  return json['data'] as List<dynamic>;
}
