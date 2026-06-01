import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_models.dart';
import 'auth_api.dart';

class AttendanceRequestApi {
  final ApiClient _client;
  AttendanceRequestApi([ApiClient? client])
      : _client = client ?? ApiClient.instance;

  Future<String> create({
    required String type, // sick | leave | extra_off | overtime
    required String startDate, // YYYY-MM-DD
    required String endDate,   // YYYY-MM-DD (sama dengan startDate untuk overtime)
    required String reason,
    int? requestedOvertimeHours,
    String? evidenceFileId,
  }) async {
    try {
      final res = await _client.dio.post(
        '/attendance-requests',
        data: {
          'type': type,
          'start_date': startDate,
          'end_date': endDate,
          'reason': reason,
          if (requestedOvertimeHours != null)
            'requested_overtime_hours': requestedOvertimeHours,
          if (evidenceFileId != null) 'evidence_file_id': evidenceFileId,
        },
      );
      final data = unwrap(res);
      return data['id'] as String;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<List<AttendanceRequestModel>> getMyRequests() async {
    try {
      final res = await _client.dio.get('/attendance-requests/me');
      return unwrapList(res)
          .map((e) =>
              AttendanceRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Admin: ambil semua pengajuan dengan filter opsional
  Future<List<AttendanceRequestModel>> getAll({
    String? status,
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final res = await _client.dio.get(
        '/attendance-requests',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (type != null && type.isNotEmpty) 'type': type,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
      );
      return unwrapList(res)
          .map((e) =>
              AttendanceRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Admin: approve atau reject pengajuan
  Future<void> updateStatus(String id, String status, {String? reviewNote}) async {
    try {
      await _client.dio.patch(
        '/attendance-requests/$id/status',
        data: {
          'status': status,
          if (reviewNote != null && reviewNote.isNotEmpty)
            'review_note': reviewNote,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
