import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_models.dart';
import 'auth_api.dart';

class AttendanceApi {
  final ApiClient _client;
  AttendanceApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  Future<AttendanceModel> checkIn(String fileId) async {
    try {
      final res = await _client.dio.post(
        '/attendance/check-in',
        data: {'file_id': fileId},
      );
      return AttendanceModel.fromJson(unwrap(res));
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<AttendanceModel> checkOut(String fileId) async {
    try {
      final res = await _client.dio.post(
        '/attendance/check-out',
        data: {'file_id': fileId},
      );
      return AttendanceModel.fromJson(unwrap(res));
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Ambil log absensi dengan filter tanggal opsional.
  /// Untuk cek hari ini: startDate = endDate = DateTime.now()
  /// Untuk bulan ini: startDate = awal bulan, endDate = akhir bulan
  Future<List<AttendanceModel>> getLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    try {
      final res = await _client.dio.get(
        '/attendance/logs',
        queryParameters: {
          if (startDate != null) 'start_date': _formatDate(startDate),
          if (endDate != null) 'end_date': _formatDate(endDate),
          if (userId != null) 'user_id': userId,
        },
      );
      return unwrapList(res)
          .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Cek apakah sudah absen masuk/pulang hari ini
  Future<AttendanceModel?> getTodayAttendance() async {
    final today = DateTime.now();
    final logs = await getLogs(startDate: today, endDate: today);
    return logs.isEmpty ? null : logs.first;
  }

  /// Admin: rekap absensi semua karyawan per bulan
  Future<List<AttendanceRecapModel>> getRecap(int month, int year) async {
    try {
      final res = await _client.dio.get(
        '/attendance/recap',
        queryParameters: {'month': month, 'year': year},
      );
      return unwrapList(res)
          .map((e) => AttendanceRecapModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<AttendanceModel?> getById(String id) async {
    if (id.isEmpty) return null;
    try {
      final res = await _client.dio.get('/attendance/$id');
      return AttendanceModel.fromJson(unwrap(res));
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Admin: edit absensi manual
  Future<void> updateAttendance(String attendanceId, Map<String, dynamic> data) async {
    try {
      await _client.dio.patch('/attendance/$attendanceId', data: data);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
