import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_models.dart';
import 'auth_api.dart';

class ActivityLogApi {
  final ApiClient _client;
  ActivityLogApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  Future<List<ActivityLogModel>> getAll({
    int page = 1,
    int limit = 50,
    String? userId,
    String? method,
    int? statusCode,
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (userId != null) 'user_id': userId,
        if (method != null) 'method': method,
        if (statusCode != null) 'status_code': statusCode,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final res = await _client.dio.get(
        '/activity-logs',
        queryParameters: params,
      );
      // Response: { success, data: { data: [...], total, page, limit } }
      final outer = unwrap(res);
      final list = outer['data'] as List<dynamic>;
      return list
          .map((e) => ActivityLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
