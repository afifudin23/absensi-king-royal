// ─── Auth ────────────────────────────────────────────────────────────────────

class LoginResult {
  final String accessToken;
  final String id;
  final String fullName;
  final String email;
  final String role;

  const LoginResult({
    required this.accessToken,
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return LoginResult(
      accessToken: json['access_token'] as String,
      id: user['id'] as String,
      fullName: user['full_name'] as String,
      email: user['email'] as String,
      role: user['role'] as String,
    );
  }
}

// ─── User ─────────────────────────────────────────────────────────────────────

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? employeeCode;
  final String? employmentStatus;
  final String? birthPlace;
  final String? birthDate;
  final String? gender;
  final String? address;
  final String? phoneNumber;
  final String? position;
  final String? department;
  final String? bankAccountNumber;
  final double? basicSalary;
  final String? profilePictureId;
  final String? profilePictureUrl;
  final String? joinedAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.employeeCode,
    this.employmentStatus,
    this.birthPlace,
    this.birthDate,
    this.gender,
    this.address,
    this.phoneNumber,
    this.position,
    this.department,
    this.bankAccountNumber,
    this.basicSalary,
    this.profilePictureId,
    this.profilePictureUrl,
    this.joinedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        employeeCode: json['employee_code'] as String?,
        employmentStatus: json['employment_status'] as String?,
        birthPlace: json['birth_place'] as String?,
        birthDate: json['birth_date'] as String?,
        gender: json['gender'] as String?,
        address: json['address'] as String?,
        phoneNumber: json['phone_number'] as String?,
        position: json['position'] as String?,
        department: json['department'] as String?,
        bankAccountNumber: json['bank_account_number'] as String?,
        basicSalary: (json['basic_salary'] as num?)?.toDouble(),
        profilePictureId: json['profile_picture_id'] as String?,
        profilePictureUrl: json['profile_picture_url'] as String?,
        joinedAt: json['joined_at'] as String?,
      );
}

// ─── Attendance ───────────────────────────────────────────────────────────────

class AttendanceModel {
  final String id;
  final String userId;
  final String status;
  final String date;
  final String? checkInAt;
  final String? checkOutAt;
  final String? checkInFileUrl;
  final String? checkOutFileUrl;
  final String? evidenceFileUrl;
  final String? note;
  final int? overtimeHours;
  final String source;

  const AttendanceModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.date,
    this.checkInAt,
    this.checkOutAt,
    this.checkInFileUrl,
    this.checkOutFileUrl,
    this.evidenceFileUrl,
    this.note,
    this.overtimeHours,
    required this.source,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) => AttendanceModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        status: json['status'] as String,
        date: json['date'] as String,
        checkInAt: json['check_in_at'] as String?,
        checkOutAt: json['check_out_at'] as String?,
        checkInFileUrl: json['check_in_file_url'] as String?,
        checkOutFileUrl: json['check_out_file_url'] as String?,
        evidenceFileUrl: json['evidence_file_url'] as String?,
        note: json['note'] as String?,
        overtimeHours: json['overtime_hours'] as int?,
        source: json['source'] as String,
      );
}

// ─── Attendance Recap ─────────────────────────────────────────────────────────

class AttendanceDailyModel {
  final String attendanceId;
  final String date;
  final String status;
  final String? checkInAt;
  final String? checkOutAt;
  final int? overtimeHours;
  final String? note;
  final String? checkInFileUrl;
  final String? checkOutFileUrl;
  final String? evidenceFileUrl;

  const AttendanceDailyModel({
    required this.attendanceId,
    required this.date,
    required this.status,
    this.checkInAt,
    this.checkOutAt,
    this.overtimeHours,
    this.note,
    this.checkInFileUrl,
    this.checkOutFileUrl,
    this.evidenceFileUrl,
  });

  factory AttendanceDailyModel.fromJson(Map<String, dynamic> json) =>
      AttendanceDailyModel(
        attendanceId: json['attendance_id'] as String,
        date: json['date'] as String,
        status: json['status'] as String,
        checkInAt: json['check_in_at'] as String?,
        checkOutAt: json['check_out_at'] as String?,
        overtimeHours: json['overtime_hours'] as int?,
        note: json['note'] as String?,
        checkInFileUrl: json['check_in_file_url'] as String?,
        checkOutFileUrl: json['check_out_file_url'] as String?,
        evidenceFileUrl: json['evidence_file_url'] as String?,
      );
}

class AttendanceRecapModel {
  final String userId;
  final String employeeName;
  final int month;
  final int year;
  final int totalPresent;
  final int totalOff;
  final int totalSick;
  final int totalExtraOff;
  final int totalAbsent;
  final int totalLeave;
  final int totalOvertimeHours;
  final List<AttendanceDailyModel> dailyDetails;

  const AttendanceRecapModel({
    required this.userId,
    required this.employeeName,
    required this.month,
    required this.year,
    required this.totalPresent,
    required this.totalOff,
    required this.totalSick,
    required this.totalExtraOff,
    required this.totalAbsent,
    required this.totalLeave,
    required this.totalOvertimeHours,
    required this.dailyDetails,
  });

  factory AttendanceRecapModel.fromJson(Map<String, dynamic> json) =>
      AttendanceRecapModel(
        userId: json['user_id'] as String,
        employeeName: json['employee_name'] as String,
        month: json['month'] as int,
        year: json['year'] as int,
        totalPresent: json['total_present'] as int,
        totalOff: json['total_off'] as int,
        totalSick: json['total_sick'] as int,
        totalExtraOff: json['total_extra_off'] as int,
        totalAbsent: json['total_absent'] as int,
        totalLeave: json['total_leave'] as int,
        totalOvertimeHours: json['total_overtime_hours'] as int,
        dailyDetails: (json['daily_details'] as List<dynamic>)
            .map((e) => AttendanceDailyModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── Attendance Request ───────────────────────────────────────────────────────

class AttendanceRequestModel {
  final String id;
  final String userId;
  final String type;
  final String status;
  final String startDate;
  final String endDate;
  final int? requestedOvertimeHours;
  final String reason;
  final String? evidenceFileUrl;
  final String? reviewNote;
  final String createdAt;

  const AttendanceRequestModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.requestedOvertimeHours,
    required this.reason,
    this.evidenceFileUrl,
    this.reviewNote,
    required this.createdAt,
    this.employeeName,
  });

  final String? employeeName;

  factory AttendanceRequestModel.fromJson(Map<String, dynamic> json) =>
      AttendanceRequestModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        type: json['type'] as String,
        status: json['status'] as String,
        startDate: json['start_date'] as String,
        endDate: json['end_date'] as String,
        requestedOvertimeHours: json['requested_overtime_hours'] as int?,
        reason: json['reason'] as String,
        evidenceFileUrl: json['evidence_file_url'] as String?,
        reviewNote: json['review_note'] as String?,
        createdAt: json['created_at'] as String,
        employeeName: json['employee_name'] as String?,
      );
}

// ─── Payroll ──────────────────────────────────────────────────────────────────

class PayrollModel {
  final String id;
  final String employeeId;
  final double basicSalary;
  final double positionAllowance;
  final double otherAllowance;
  final double overtimeRate;
  final double loanDeduction;
  final double attendanceDeduction;
  final double incomeTax;
  final double grossSalary;
  final double netSalary;
  final String status;
  final String? sentAt;
  final String createdAt;
  final Map<String, dynamic>? additionalData;

  const PayrollModel({
    required this.id,
    required this.employeeId,
    required this.basicSalary,
    required this.positionAllowance,
    required this.otherAllowance,
    required this.overtimeRate,
    required this.loanDeduction,
    required this.attendanceDeduction,
    required this.incomeTax,
    required this.grossSalary,
    required this.netSalary,
    required this.status,
    this.sentAt,
    required this.createdAt,
    this.employeeName,
    this.additionalData,
  });

  int get month => DateTime.parse(createdAt).toLocal().month;
  int get year => DateTime.parse(createdAt).toLocal().year;

  final String? employeeName;

  factory PayrollModel.fromJson(Map<String, dynamic> json) => PayrollModel(
        id: json['id'] as String,
        employeeId: json['employee_id'] as String,
        basicSalary: (json['basic_salary'] as num).toDouble(),
        positionAllowance: (json['position_allowance'] as num).toDouble(),
        otherAllowance: (json['other_allowance'] as num).toDouble(),
        overtimeRate: (json['overtime_rate'] as num).toDouble(),
        loanDeduction: (json['loan_deduction'] as num).toDouble(),
        attendanceDeduction: (json['attendance_deduction'] as num).toDouble(),
        incomeTax: (json['income_tax'] as num).toDouble(),
        grossSalary: (json['gross_salary'] as num? ?? 0).toDouble(),
        netSalary: (json['net_salary'] as num).toDouble(),
        status: json['status'] as String,
        sentAt: json['sent_at'] as String?,
        createdAt: json['created_at'] as String,
        employeeName: json['employee_name'] as String?,
        additionalData: json['additional_data'] as Map<String, dynamic>?,
      );
}

// ─── Activity Log ─────────────────────────────────────────────────────────────

class ActivityLogModel {
  final String id;
  final String? userId;
  final String? userName;
  final String method;
  final String path;
  final int statusCode;
  final String description;
  final String? ipAddress;
  final double? latencyMs;
  final String createdAt;

  const ActivityLogModel({
    required this.id,
    this.userId,
    this.userName,
    required this.method,
    required this.path,
    required this.statusCode,
    required this.description,
    this.ipAddress,
    this.latencyMs,
    required this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) =>
      ActivityLogModel(
        id: json['id'] as String,
        userId: json['user_id'] as String?,
        userName: json['user_name'] as String?,
        method: json['method'] as String,
        path: json['path'] as String,
        statusCode: json['status_code'] as int,
        description: json['description'] as String,
        ipAddress: json['ip_address'] as String?,
        latencyMs: (json['latency_ms'] as num?)?.toDouble(),
        createdAt: json['created_at'] as String,
      );
}

// ─── File ─────────────────────────────────────────────────────────────────────

class FileModel {
  final String id;
  final String fileUrl;
  final String type;

  const FileModel({
    required this.id,
    required this.fileUrl,
    required this.type,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) => FileModel(
        id: json['id'] as String,
        fileUrl: json['file_url'] as String,
        type: json['type'] as String,
      );
}
