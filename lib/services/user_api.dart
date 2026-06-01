import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_models.dart';
import 'auth_api.dart';

class UserApi {
  final ApiClient _client;
  UserApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  Future<UserModel> getMyProfile() async {
    try {
      final res = await _client.dio.get('/users/me');
      return UserModel.fromJson(unwrap(res));
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<List<UserModel>> getAll({String search = '', String role = ''}) async {
    try {
      final res = await _client.dio.get(
        '/users',
        queryParameters: {
          if (search.isNotEmpty) 'search': search,
          if (role.isNotEmpty) 'role': role,
        },
      );
      return unwrapList(res)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<UserModel> getByID(String userID) async {
    try {
      final res = await _client.dio.get('/users/$userID');
      return UserModel.fromJson(unwrap(res));
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _client.dio.put(
        '/users/me/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<void> adminResetPassword(String userID, String newPassword) async {
    try {
      await _client.dio.post(
        '/users/$userID/reset-password',
        data: {'new_password': newPassword},
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<void> createUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? employeeCode,
    String? birthPlace,
    String? birthDate,
    String? gender,
    String? address,
    String? phoneNumber,
    String? position,
    String? department,
    String? employmentStatus,
    String? joinedAt,
    String? bankAccountNumber,
    double? basicSalary,
  }) async {
    try {
      await _client.dio.post(
        '/users',
        data: {
          'full_name': fullName,
          'email': email,
          'password': password,
          'role': role,
          if (employeeCode != null) 'employee_code': employeeCode,
          if (birthPlace != null) 'birth_place': birthPlace,
          if (birthDate != null) 'birth_date': birthDate,
          if (gender != null) 'gender': gender,
          if (address != null) 'address': address,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (position != null) 'position': position,
          if (department != null) 'department': department,
          if (employmentStatus != null) 'employment_status': employmentStatus,
          if (joinedAt != null) 'joined_at': joinedAt,
          if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
          if (basicSalary != null) 'basic_salary': basicSalary,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<void> updateUser(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _client.dio.put('/users/$userId', data: fields);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<void> updateMyProfile({
    String? fullName,
    String? birthPlace,
    DateTime? birthDate,
    String? gender,
    String? address,
    String? phoneNumber,
    String? bankAccountNumber,
  }) async {
    try {
      await _client.dio.put(
        '/users/me',
        data: {
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
          if (birthPlace != null) 'birth_place': birthPlace,
          if (birthDate != null)
            'birth_date':
                '${birthDate.year.toString().padLeft(4, '0')}-'
                '${birthDate.month.toString().padLeft(2, '0')}-'
                '${birthDate.day.toString().padLeft(2, '0')}',
          if (gender != null) 'gender': gender,
          if (address != null) 'address': address,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (bankAccountNumber != null)
            'bank_account_number': bankAccountNumber,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<void> updateMyProfilePhoto(String? fileId) async {
    try {
      await _client.dio.put(
        '/users/me',
        data: fileId != null
            ? {'profile_picture_id': fileId}
            : {'clear_profile_picture': true},
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<void> deleteUser(String userID) async {
    try {
      await _client.dio.delete('/users/$userID');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
