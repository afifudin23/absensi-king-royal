import 'package:absensi_king_royal/services/services.dart';

// ─── Enums & Result types (interface tidak berubah) ──────────────────────────

enum LoginErrorType { emailNotRegistered, wrongPassword, inactiveAccount }

class LoginResult {
  final AppUser? user;
  final LoginErrorType? error;

  const LoginResult.success(this.user) : error = null;
  const LoginResult.failure(this.error) : user = null;
}

enum PasswordChangeErrorType { wrongCurrentPassword, weakPassword, mismatch }

class PasswordChangeResult {
  final bool isSuccess;
  final PasswordChangeErrorType? error;

  const PasswordChangeResult.success() : isSuccess = true, error = null;
  const PasswordChangeResult.failure(this.error) : isSuccess = false;
}

// ─── AppUser model (tidak berubah, dipakai di seluruh app) ───────────────────

class AppUser {
  final String id;
  final String fullName;
  final String nik;
  final String placeOfBirth;
  final DateTime birthDate;
  final String gender;
  final String address;
  final String phoneNumber;
  final String email;
  final String username;
  final String jobTitle;
  final String role;
  final String department;
  final String employeeStatus;
  final DateTime joinDate;
  final String bankAccountNumber;
  final String? profilePhotoPath;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.nik,
    required this.placeOfBirth,
    required this.birthDate,
    required this.gender,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.username,
    required this.jobTitle,
    required this.role,
    required this.department,
    required this.employeeStatus,
    required this.joinDate,
    required this.bankAccountNumber,
    this.profilePhotoPath,
    required this.isActive,
  });

  factory AppUser.fromApiProfile(UserModel p) => AppUser(
        id: p.id,
        fullName: p.fullName,
        nik: p.employeeCode ?? '',
        placeOfBirth: p.birthPlace ?? '',
        birthDate: p.birthDate != null
            ? DateTime.tryParse(p.birthDate!) ?? DateTime(2000)
            : DateTime(2000),
        gender: p.gender ?? '',
        address: p.address ?? '',
        phoneNumber: p.phoneNumber ?? '',
        email: p.email,
        username: p.email.split('@').first,
        jobTitle: p.position ?? '',
        role: p.role,
        department: p.department ?? '',
        employeeStatus: p.employmentStatus ?? '',
        joinDate: p.joinedAt != null
            ? DateTime.tryParse(p.joinedAt!) ?? DateTime.now()
            : DateTime.now(),
        bankAccountNumber: p.bankAccountNumber ?? '',
        profilePhotoPath: p.profilePictureUrl,
        isActive: true,
      );
}

// ─── AuthService (interface sama, implementasi pakai real API) ────────────────

class AuthService {
  final _authApi = AuthApi();
  final _userApi = UserApi();

  Future<LoginResult> login({
    required String identity,
    required String password,
  }) async {
    try {
      await _authApi.login(identity.trim().toLowerCase(), password);
      final profile = await _userApi.getMyProfile();
      return LoginResult.success(AppUser.fromApiProfile(profile));
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        return const LoginResult.failure(LoginErrorType.inactiveAccount);
      }
      return const LoginResult.failure(LoginErrorType.wrongPassword);
    } catch (_) {
      return const LoginResult.failure(LoginErrorType.wrongPassword);
    }
  }

  /// Kirim OTP reset password ke email. Selalu return true agar tidak
  /// mengungkap apakah email terdaftar atau tidak.
  Future<bool> requestPasswordReset(String identity) async {
    try {
      await _authApi.forgotPassword(identity.trim().toLowerCase());
    } catch (_) {}
    return true;
  }

  /// Verifikasi OTP lalu set password baru.
  Future<bool> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _authApi.resetPasswordWithOTP(
        email: email.trim().toLowerCase(),
        otp: otp.trim(),
        newPassword: newPassword,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<PasswordChangeResult> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    if (newPassword.length < 3) {
      return const PasswordChangeResult.failure(
          PasswordChangeErrorType.weakPassword);
    }
    if (newPassword != confirmNewPassword) {
      return const PasswordChangeResult.failure(
          PasswordChangeErrorType.mismatch);
    }
    try {
      await _userApi.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmNewPassword,
      );
      return const PasswordChangeResult.success();
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        return const PasswordChangeResult.failure(
            PasswordChangeErrorType.wrongCurrentPassword);
      }
      return const PasswordChangeResult.failure(
          PasswordChangeErrorType.wrongCurrentPassword);
    }
  }

  /// Restore session dari token tersimpan. Return null jika token tidak ada
  /// atau sudah expired.
  Future<AppUser?> restoreSession() async {
    final token = await ApiClient.instance.getToken();
    if (token == null) return null;
    try {
      final profile = await _userApi.getMyProfile();
      return AppUser.fromApiProfile(profile);
    } catch (_) {
      await ApiClient.instance.clearToken();
      return null;
    }
  }

  Future<void> logout() async {
    await _authApi.logout();
  }
}
