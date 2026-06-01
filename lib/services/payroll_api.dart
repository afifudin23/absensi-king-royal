import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_models.dart';
import 'auth_api.dart';

class PayrollApi {
  final ApiClient _client;
  PayrollApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  /// Karyawan: lihat slip gaji yang sudah dikirim
  Future<List<PayrollModel>> getMyPayrolls() async {
    try {
      final res = await _client.dio.get('/payrolls/me');
      return unwrapList(res)
          .map((e) => PayrollModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Admin: list semua slip gaji
  Future<List<PayrollModel>> getAll() async {
    try {
      final res = await _client.dio.get('/payrolls');
      return unwrapList(res)
          .map((e) => PayrollModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Admin: generate slip satu karyawan
  Future<PayrollModel> generateOne(String employeeId) async {
    try {
      final res = await _client.dio.post('/payrolls/generate/$employeeId');
      return PayrollModel.fromJson(unwrap(res));
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Admin: generate slip semua karyawan
  Future<void> generateAll() async {
    try {
      await _client.dio.post('/payrolls/generate-all');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Admin: edit komponen slip gaji
  Future<PayrollModel> updatePayroll(
    String payrollId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final res = await _client.dio.put('/payrolls/$payrollId', data: fields);
      return PayrollModel.fromJson(unwrap(res));
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Admin: kirim slip gaji via email
  Future<void> sendPayroll(String payrollId) async {
    try {
      await _client.dio.post('/payrolls/$payrollId/send');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
