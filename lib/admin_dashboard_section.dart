import 'dart:io';

import 'package:absensi_king_royal/payroll_models.dart';
import 'package:absensi_king_royal/services/services.dart';
import 'package:absensi_king_royal/utils/enum_mapper.dart';
import 'package:absensi_king_royal/utils/export_utils.dart';
import 'package:absensi_king_royal/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

String? _resolveFileUrlStatic(String? url) {
  if (url == null || url.isEmpty) return null;
  final serverHost = Uri.parse(kApiBaseUrl).host;
  if (url.startsWith('http')) {
    return url
        .replaceAll('localhost', serverHost)
        .replaceAll('127.0.0.1', serverHost);
  }
  final base = kApiBaseUrl.replaceFirst(RegExp(r'/api/v\d+$'), '');
  return '$base$url';
}

enum AdminRole { admin, user }

enum ApprovalType { izin, cuti, extraOff, sakit, lembur }

enum ApprovalStatus { pending, approved, rejected }

enum _DailyAttendanceStatus {
  hadir,
  off,
  extraOff,
  cuti,
  sakit,
  alfa,
  tidakHadir,
}

class _DailyAttendanceDetail {
  String attendanceId = '';
  DateTime date;
  _DailyAttendanceStatus status;
  TimeOfDay? checkIn;
  TimeOfDay? checkOut;
  int lemburHours;
  String note;
  String? checkInPhotoPath;
  String? checkOutPhotoPath;
  String? evidencePhotoPath;
  bool isManuallyEdited = false;

  _DailyAttendanceDetail({
    required this.date,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.lemburHours,
    required this.note,
    required this.checkInPhotoPath,
    required this.checkOutPhotoPath,
    this.evidencePhotoPath,
  });
}

class _MonthlyRecap {
  final String userId;
  final String employeeName;
  final int month;
  final int year;
  int totalHadir;
  int totalOff;
  int totalTidakHadir;
  int totalCuti;
  int totalExtraOff;
  int totalSakit;
  int totalAlfa;
  int totalLembur;
  final List<_DailyAttendanceDetail> dailyDetails;

  _MonthlyRecap({
    required this.userId,
    required this.employeeName,
    required this.month,
    required this.year,
    required this.totalHadir,
    required this.totalOff,
    required this.totalTidakHadir,
    required this.totalCuti,
    required this.totalExtraOff,
    required this.totalSakit,
    required this.totalAlfa,
    required this.totalLembur,
    required this.dailyDetails,
  });
}

class _ApprovalRequest {
  final String id;
  final String employeeName;
  final ApprovalType type;
  final String? reason;
  final DateTime date;
  final String? attachment;
  ApprovalStatus status = ApprovalStatus.pending;

  _ApprovalRequest({
    required this.id,
    required this.employeeName,
    required this.type,
    required this.reason,
    required this.date,
    required this.attachment,
  });
}

class _SalarySlip {
  final String id;
  final String employeeId;
  String employeeName;
  final int month;
  final int year;
  int gajiPokok;
  int tunjanganJabatan;
  int lembur;
  int tunjanganLain;
  int potonganPinjaman;
  int potonganAbsen;
  int potonganBpjsKesehatan;
  int potonganBpjsTkJht;
  int potonganBpjsTkJp;
  int potonganPph21;
  String notes;
  final DateTime generatedAt;
  DateTime? sentAt;
  final int grossSalary;
  final int netSalary;

  _SalarySlip({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.year,
    required this.gajiPokok,
    required this.tunjanganJabatan,
    required this.lembur,
    required this.tunjanganLain,
    required this.potonganPinjaman,
    required this.potonganAbsen,
    required this.potonganBpjsKesehatan,
    required this.potonganBpjsTkJht,
    required this.potonganBpjsTkJp,
    required this.potonganPph21,
    required this.notes,
    required this.generatedAt,
    required this.grossSalary,
    required this.netSalary,
  });

  int get totalGaji =>
      gajiPokok +
      tunjanganJabatan +
      lembur +
      tunjanganLain -
      potonganPinjaman -
      potonganAbsen -
      potonganBpjsKesehatan -
      potonganBpjsTkJht -
      potonganBpjsTkJp -
      potonganPph21;
}

class _EmployeeData {
  final String id;
  String fullName;
  String nik;
  String placeOfBirth;
  DateTime birthDate;
  String gender;
  String address;
  String phoneNumber;
  String email;
  String jobTitle;
  AdminRole role;
  String department;
  String employeeStatus;
  DateTime joinDate;
  String bankAccountNumber;
  int gajiPokok;
  String? profilePhotoPath;
  String? profilePhotoId;
  bool isActive = true;

  _EmployeeData({
    required this.id,
    required this.fullName,
    required this.nik,
    required this.placeOfBirth,
    required this.birthDate,
    required this.gender,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.jobTitle,
    required this.role,
    required this.department,
    required this.employeeStatus,
    required this.joinDate,
    required this.bankAccountNumber,
    required this.gajiPokok,
    this.profilePhotoPath,
    this.profilePhotoId,
  });
}

class _ActivityLog {
  final DateTime time;
  final String actor;
  final String module;
  final String action;
  final String target;
  final String? detail;
  final String? before;
  final String? after;

  const _ActivityLog({
    required this.time,
    required this.actor,
    required this.module,
    required this.action,
    required this.target,
    this.detail,
    this.before,
    this.after,
  });
}

class AdminDashboardSection extends StatefulWidget {
  final String currentUserName;
  final ValueChanged<SentPayrollSlip>? onSlipSent;
  final ValueNotifier<int>? refreshTrigger;

  const AdminDashboardSection({
    super.key,
    required this.currentUserName,
    this.onSlipSent,
    this.refreshTrigger,
  });

  @override
  State<AdminDashboardSection> createState() => _AdminDashboardSectionState();
}

class _AdminDashboardSectionState extends State<AdminDashboardSection> {
  static const int _annualLeaveQuota = 12;
  late int _selectedMonth;
  late int _selectedYear;
  String _nameFilter = '';

  final _userApi = UserApi();
  final _attendanceApi = AttendanceApi();
  final _requestApi = AttendanceRequestApi();
  final _payrollApi = PayrollApi();
  final _activityLogApi = ActivityLogApi();
  final Map<String, Future<AttendanceModel?>> _attendanceCache = {};

  Future<AttendanceModel?> _getCachedAttendance(String id) {
    print('[getCachedAttendance] id=$id');
    if (id.isEmpty) return Future.value(null);
    return _attendanceCache[id] ??= _attendanceApi.getById(id).then((att) {
      print('[getById OK] id=$id evidenceFileUrl=${att?.evidenceFileUrl} checkInFileUrl=${att?.checkInFileUrl}');
      return att;
    }).catchError((e) {
      print('[getById ERROR] id=$id error=$e');
      return null;
    });
  }

  String? _resolveFileUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final serverHost = Uri.parse(kApiBaseUrl).host;
    if (url.startsWith('http')) {
      return url
          .replaceAll('localhost', serverHost)
          .replaceAll('127.0.0.1', serverHost);
    }
    final base = kApiBaseUrl.replaceFirst(RegExp(r'/api/v\d+$'), '');
    return '$base$url';
  }

  void _showPhotoPreview(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_MonthlyRecap> _recapData = [];
  List<_ApprovalRequest> _approvalRequests = [];
  List<_EmployeeData> _employees = [];
  final List<_SalarySlip> _salarySlips = [];
  final List<_ActivityLog> _activityLogs = [];
  bool _activityLogsLoading = false;

  void _onRefreshTrigger() {
    _loadEmployees().then((_) => _loadPayrolls());
    _loadRecap();
    _loadApprovalRequests();
    _loadActivityLogs();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    widget.refreshTrigger?.addListener(_onRefreshTrigger);
    _loadEmployees().then((_) => _loadPayrolls());
    _loadRecap();
    _loadApprovalRequests();
    _loadActivityLogs();
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTrigger);
    super.dispose();
  }

  // ─── Loaders ───────────────────────────────────────────────────────────────

  Future<void> _loadEmployees() async {
    try {
      final users = await _userApi.getAll();
      if (!mounted) return;
      setState(() {
        _employees = users.map(_mapUser).toList();
        for (final slip in _salarySlips) {
          if (slip.employeeName == slip.employeeId) {
            slip.employeeName = _findEmployeeNameById(slip.employeeId);
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _loadRecap() async {
    try {
      final recap = await _attendanceApi.getRecap(_selectedMonth, _selectedYear);
      if (!mounted) return;
      setState(() {
        _recapData = recap.map(_mapRecap).toList();
        for (final r in _recapData) {
          _syncRecapTotalsFromDailyDetails(r);
        }
      });
    } catch (_) {}
  }

  Future<void> _loadApprovalRequests() async {
    try {
      final start = DateTime(_selectedYear, _selectedMonth, 1);
      final end = DateTime(_selectedYear, _selectedMonth + 1, 0);
      final fmt = (DateTime d) =>
          '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      final requests = await _requestApi.getAll(
        startDate: fmt(start),
        endDate: fmt(end),
      );
      if (!mounted) return;
      setState(() {
        _approvalRequests = requests.map(_mapRequest).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadPayrolls() async {
    try {
      final payrolls = await _payrollApi.getAll();
      if (!mounted) return;
      setState(() {
        _salarySlips.clear();
        _salarySlips.addAll(payrolls.map(_mapPayroll));
      });
    } catch (_) {}
  }

  Future<void> _loadActivityLogs() async {
    if (_activityLogsLoading) return;
    setState(() => _activityLogsLoading = true);
    try {
      final logs = await _activityLogApi.getAll(limit: 100);
      if (!mounted) return;
      // GET tidak disimpan API, tapi kalau ada sisa data lama, filter di sini
      final filtered = logs.where((m) => m.method != 'GET').toList();
      setState(() {
        _activityLogs
          ..clear()
          ..addAll(filtered.map(_mapActivityLog));
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _activityLogsLoading = false);
    }
  }

  // ─── Mappers ───────────────────────────────────────────────────────────────

  _EmployeeData _mapUser(UserModel u) => _EmployeeData(
        id: u.id,
        fullName: u.fullName,
        nik: u.employeeCode ?? '',
        placeOfBirth: u.birthPlace ?? '',
        birthDate: u.birthDate != null
            ? DateTime.tryParse(u.birthDate!) ?? DateTime(2000)
            : DateTime(2000),
        gender: u.gender ?? 'Laki-laki',
        address: u.address ?? '',
        phoneNumber: u.phoneNumber ?? '',
        email: u.email,
        jobTitle: u.position ?? '',
        role: u.role == 'admin' ? AdminRole.admin : AdminRole.user,
        department: u.department ?? '',
        employeeStatus: _mapEmploymentStatus(u.employmentStatus),
        joinDate: u.joinedAt != null
            ? DateTime.tryParse(u.joinedAt!) ?? DateTime.now()
            : DateTime.now(),
        bankAccountNumber: u.bankAccountNumber ?? '',
        gajiPokok: u.basicSalary?.toInt() ?? 0,
        profilePhotoPath: _resolveFileUrlStatic(u.profilePictureUrl),
        profilePhotoId: u.profilePictureId,
      );

  String _mapEmploymentStatus(String? s) {
    switch (s) {
      case 'permanent':
        return 'Tetap';
      case 'contract':
        return 'Kontrak';
      case 'intern':
        return 'Magang';
      default:
        return s ?? 'Tetap';
    }
  }

  String _apiEmploymentStatus(String s) {
    switch (s) {
      case 'Tetap':
        return 'permanent';
      case 'Kontrak':
        return 'contract';
      case 'Magang':
        return 'intern';
      default:
        return s.toLowerCase();
    }
  }

  _MonthlyRecap _mapRecap(AttendanceRecapModel r) {
    final details = r.dailyDetails.map(_mapDailyDetail).toList();
    return _MonthlyRecap(
      userId: r.userId,
      employeeName: r.employeeName,
      month: r.month,
      year: r.year,
      totalHadir: r.totalPresent,
      totalOff: r.totalOff,
      totalTidakHadir: r.totalAbsent,
      totalCuti: r.totalLeave,
      totalExtraOff: r.totalExtraOff,
      totalSakit: r.totalSick,
      totalAlfa: 0,
      totalLembur: r.totalOvertimeHours,
      dailyDetails: details,
    );
  }

  _DailyAttendanceDetail _mapDailyDetail(AttendanceDailyModel d) {
    final date = DateTime.tryParse(d.date) ?? DateTime.now();
    TimeOfDay? checkIn;
    if (d.checkInAt != null) {
      checkIn = _parseTimeOfDayHHMM(d.checkInAt!);
    }
    TimeOfDay? checkOut;
    if (d.checkOutAt != null) {
      checkOut = _parseTimeOfDayHHMM(d.checkOutAt!);
    }
    final status = _mapDailyStatus(d.status);
    print('[mapDailyDetail] date=${d.date} status=${d.status} attendanceId=${d.attendanceId} evidenceUrl=${d.evidenceFileUrl}');
    return _DailyAttendanceDetail(
      date: date,
      status: status,
      checkIn: checkIn,
      checkOut: checkOut,
      lemburHours: d.overtimeHours ?? 0,
      note: d.note ?? '',
      checkInPhotoPath: _resolveFileUrlStatic(d.checkInFileUrl),
      checkOutPhotoPath: _resolveFileUrlStatic(d.checkOutFileUrl),
      evidencePhotoPath: _resolveFileUrlStatic(d.evidenceFileUrl),
    )..attendanceId = d.attendanceId;
  }

  _DailyAttendanceStatus _mapDailyStatus(String s) => switch (s) {
        'present' => _DailyAttendanceStatus.hadir,
        'off' => _DailyAttendanceStatus.off,
        'extra_off' => _DailyAttendanceStatus.extraOff,
        'leave' => _DailyAttendanceStatus.cuti,
        'sick' => _DailyAttendanceStatus.sakit,
        'absent' => _DailyAttendanceStatus.alfa,
        _ => _DailyAttendanceStatus.tidakHadir,
      };

  String _apiDailyStatus(_DailyAttendanceStatus s) => switch (s) {
        _DailyAttendanceStatus.hadir => 'present',
        _DailyAttendanceStatus.off => 'off',
        _DailyAttendanceStatus.extraOff => 'extra_off',
        _DailyAttendanceStatus.cuti => 'leave',
        _DailyAttendanceStatus.sakit => 'sick',
        _DailyAttendanceStatus.alfa => 'absent',
        _DailyAttendanceStatus.tidakHadir => 'absent',
      };

  _ApprovalRequest _mapRequest(AttendanceRequestModel r) {
    final date = DateTime.tryParse(r.startDate) ?? DateTime.now();
    final type = switch (r.type) {
      'sick' => ApprovalType.sakit,
      'leave' => ApprovalType.cuti,
      'extra_off' => ApprovalType.extraOff,
      'overtime' => ApprovalType.lembur,
      _ => ApprovalType.izin,
    };
    final req = _ApprovalRequest(
      id: r.id,
      employeeName: r.employeeName ?? r.userId,
      type: type,
      reason: r.reason,
      date: date,
      attachment: r.evidenceFileUrl,
    );
    req.status = switch (r.status) {
      'approved' => ApprovalStatus.approved,
      'rejected' => ApprovalStatus.rejected,
      _ => ApprovalStatus.pending,
    };
    return req;
  }

  _SalarySlip _mapPayroll(PayrollModel p) {
    final sentAt = p.sentAt != null ? DateTime.tryParse(p.sentAt!) : null;
    final slip = _SalarySlip(
      id: p.id,
      employeeId: p.employeeId,
      employeeName: p.employeeName ?? _findEmployeeNameById(p.employeeId),
      month: p.month,
      year: p.year,
      gajiPokok: p.basicSalary.toInt(),
      tunjanganJabatan: p.positionAllowance.toInt(),
      lembur: p.overtimeRate.toInt(),
      tunjanganLain: p.otherAllowance.toInt(),
      potonganPinjaman: p.loanDeduction.toInt(),
      potonganAbsen: p.attendanceDeduction.toInt(),
      potonganBpjsKesehatan: (p.additionalData?['bpjs_health_rate'] as num? ?? 0).toInt(),
      potonganBpjsTkJht: (p.additionalData?['bpjs_employment_jht_rate'] as num? ?? 0).toInt(),
      potonganBpjsTkJp: (p.additionalData?['bpjs_employment_jp_rate'] as num? ?? 0).toInt(),
      potonganPph21: p.incomeTax.toInt(),
      notes: '',
      generatedAt: DateTime.tryParse(p.createdAt) ?? DateTime.now(),
      grossSalary: p.grossSalary.toInt(),
      netSalary: p.netSalary.toInt(),
    );
    slip.sentAt = sentAt;
    return slip;
  }

  _ActivityLog _mapActivityLog(ActivityLogModel m) {
    final isError = m.statusCode >= 400;
    return _ActivityLog(
      time: DateTime.parse(m.createdAt).toLocal(),
      actor: m.userName ?? 'Sistem',
      module: _moduleFromPath(m.path),
      action: m.description.isNotEmpty ? m.description : '${m.method} ${m.path}',
      target: '',
      detail: isError ? 'Gagal (kode ${m.statusCode})' : null,
    );
  }

  String _moduleFromPath(String path) {
    final p = path.replaceFirst(RegExp(r'^/api/v\d+'), '');
    if (p.contains('/payrolls')) return 'Payroll';
    if (p.contains('/users')) return 'Karyawan';
    if (p.contains('/attendance-requests')) return 'Pengajuan Izin';
    if (p.contains('/attendances') || p.contains('/attendance/')) return 'Absensi';
    if (p.contains('/auth')) return 'Autentikasi';
    if (p.contains('/files')) return 'File';
    return 'Sistem';
  }

  String _findEmployeeNameById(String id) {
    try {
      return _employees.firstWhere((e) => e.id == id).fullName;
    } catch (_) {
      return id;
    }
  }

  List<_MonthlyRecap> get _currentRecapData {
    final byPeriod = _recapData
        .where((e) => e.month == _selectedMonth && e.year == _selectedYear)
        .toList();
    if (_nameFilter.trim().isEmpty) return byPeriod;
    final q = _nameFilter.toLowerCase();
    return byPeriod
        .where((e) => e.employeeName.toLowerCase().contains(q))
        .toList();
  }

  int get _totalPending {
    return _approvalRequests
        .where((e) => e.status == ApprovalStatus.pending)
        .length;
  }

  int get _totalKaryawan => _employees.length;

  int get _jumlahHadirHariIni {
    final today = DateTime.now();
    return _recapData.where((recap) => recap.dailyDetails.any((d) =>
      d.date.year == today.year &&
      d.date.month == today.month &&
      d.date.day == today.day &&
      d.status == _DailyAttendanceStatus.hadir,
    )).length;
  }

  int get _jumlahOffHariIni {
    final today = DateTime.now();
    return _recapData.where((recap) => recap.dailyDetails.any((d) =>
      d.date.year == today.year &&
      d.date.month == today.month &&
      d.date.day == today.day &&
      (d.status == _DailyAttendanceStatus.off ||
       d.status == _DailyAttendanceStatus.extraOff),
    )).length;
  }

  int _remainingLeaveForEmployee(String employeeName, {int? year}) {
    final activeYear = year ?? _selectedYear;
    final used = _recapData
        .where(
          (item) =>
              item.employeeName == employeeName && item.year == activeYear,
        )
        .fold<int>(0, (sum, item) => sum + item.totalCuti);
    return (_annualLeaveQuota - used).clamp(0, _annualLeaveQuota);
  }

  void _addLog(
    String action,
    String target, {
    String module = 'Umum',
    String? detail,
    String? before,
    String? after,
  }) {
    setState(() {
      _activityLogs.insert(
        0,
        _ActivityLog(
          time: DateTime.now(),
          actor: widget.currentUserName,
          module: module,
          action: action,
          target: target,
          detail: detail,
          before: before,
          after: after,
        ),
      );
    });
  }

  Future<void> _exportData() async {
    if (_employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data karyawan untuk diekspor.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Membuat file Excel...')),
    );

    try {
      // Gunakan _employees sebagai base agar semua karyawan muncul (termasuk yg tidak ada absensi)
      final recapById = {for (final r in _currentRecapData) r.userId: r};

      String _tod(TimeOfDay? t) => t == null
          ? '-'
          : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

      final rows = _employees.map((emp) {
        final recap = recapById[emp.id];
        final details = recap?.dailyDetails.map((d) => RecapDailyDetail(
          date: d.date,
          status: _dailyStatusLabel(d.status),
          checkIn: _tod(d.checkIn),
          checkOut: _tod(d.checkOut),
          lemburJam: d.lemburHours,
          keterangan: d.note.trim().isEmpty ? '-' : d.note,
        )).toList() ?? [];
        return RecapExportRow(
          nama: emp.fullName,
          hadir: recap?.totalHadir ?? 0,
          off: recap?.totalOff ?? 0,
          tidakHadir: recap?.totalTidakHadir ?? 0,
          cuti: recap?.totalCuti ?? 0,
          extraOff: recap?.totalExtraOff ?? 0,
          sakit: recap?.totalSakit ?? 0,
          alfa: recap?.totalAlfa ?? 0,
          lembur: recap?.totalLembur ?? 0,
          dailyDetails: details,
        );
      }).toList();

      final file = await exportRecapExcel(rows, _selectedMonth, _selectedYear);

      if (!mounted) return;

      // Simpan ke Downloads Android
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        final dest = File('${downloadsDir.path}/${file.uri.pathSegments.last}');
        await file.copy(dest.path);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File disimpan ke Downloads: ${dest.uri.pathSegments.last}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File Excel berhasil dibuat.')),
        );
      }

      _addLog(
        'Export Excel',
        'Rekap absensi $_selectedMonth/$_selectedYear',
        module: 'Rekap Absensi',
        detail: 'Admin mengekspor data rekap periode $_selectedMonth/$_selectedYear',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export Excel: $e')),
      );
    }
  }

  Future<void> _updateApproval(_ApprovalRequest request, ApprovalStatus status) async {
    final previousStatus = request.status;
    final apiStatus = status == ApprovalStatus.approved ? 'approved' : 'rejected';
    try {
      await _requestApi.updateStatus(request.id, apiStatus);
      if (!mounted) return;
      setState(() => request.status = status);
      final action = status == ApprovalStatus.approved ? 'Approve' : 'Reject';
      _addLog(
        '$action pengajuan',
        '${request.employeeName} - ${_labelApprovalType(request.type)}',
        module: 'Approval',
        before: _labelApprovalStatus(previousStatus),
        after: _labelApprovalStatus(status),
        detail:
            'Tanggal ${DateFormat('dd/MM/yyyy').format(request.date)} | Alasan ${request.reason ?? "-"}',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memproses pengajuan.')),
      );
    }
  }

  _MonthlyRecap? _findRecapByEmployee(String employeeName) {
    for (final recap in _currentRecapData) {
      if (recap.employeeName == employeeName) return recap;
    }
    return null;
  }

  int _safeParseInt(String value, int fallback) {
    final parsed = int.tryParse(value.trim());
    return parsed ?? fallback;
  }

  List<_DailyAttendanceDetail> _buildDailyDetailsFromRecap(
    _MonthlyRecap recap,
  ) {
    final totalRecordedDays =
        recap.totalHadir +
        recap.totalOff +
        recap.totalTidakHadir +
        recap.totalCuti +
        recap.totalExtraOff +
        recap.totalSakit +
        recap.totalAlfa;
    final workingDays = totalRecordedDays <= 0 ? 1 : totalRecordedDays;
    final counts = <_DailyAttendanceStatus, int>{
      _DailyAttendanceStatus.hadir: recap.totalHadir,
      _DailyAttendanceStatus.off: recap.totalOff,
      _DailyAttendanceStatus.cuti: recap.totalCuti,
      _DailyAttendanceStatus.extraOff: recap.totalExtraOff,
      _DailyAttendanceStatus.sakit: recap.totalSakit,
      _DailyAttendanceStatus.alfa: recap.totalAlfa,
      _DailyAttendanceStatus.tidakHadir: recap.totalTidakHadir,
    };
    var remainingLembur = recap.totalLembur;
    final lastDateOfMonth = DateTime(recap.year, recap.month + 1, 0);
    final details = <_DailyAttendanceDetail>[];

    _DailyAttendanceStatus takeStatus() {
      for (final entry in counts.entries) {
        if (entry.value > 0) {
          counts[entry.key] = entry.value - 1;
          return entry.key;
        }
      }
      return _DailyAttendanceStatus.off;
    }

    for (var i = 0; i < workingDays; i++) {
      final status = takeStatus();
      final date = lastDateOfMonth.subtract(Duration(days: i));
      final isHadir = status == _DailyAttendanceStatus.hadir;
      final lemburHours = isHadir && remainingLembur > 0 ? 1 : 0;
      if (lemburHours > 0) {
        remainingLembur -= 1;
      }
      final checkIn = isHadir ? TimeOfDay(hour: 8, minute: (i * 3) % 60) : null;
      final checkOut = isHadir
          ? TimeOfDay(hour: 17 + lemburHours, minute: (i * 7) % 60)
          : null;

      details.add(
        _DailyAttendanceDetail(
          date: date,
          status: status,
          checkIn: checkIn,
          checkOut: checkOut,
          lemburHours: lemburHours,
          note: _dailyStatusLabel(status),
          checkInPhotoPath: isHadir ? 'assets/icons/app_icon.jpg' : null,
          checkOutPhotoPath: isHadir ? 'assets/icons/app_icon.jpg' : null,
        ),
      );
    }
    return details;
  }

  void _syncRecapTotalsFromDailyDetails(_MonthlyRecap recap) {
    var hadir = 0;
    var off = 0;
    var tidakHadir = 0;
    var cuti = 0;
    var extraOff = 0;
    var sakit = 0;
    var alfa = 0;
    var lembur = 0;

    for (final day in recap.dailyDetails) {
      switch (day.status) {
        case _DailyAttendanceStatus.hadir:
          hadir += 1;
          lembur += day.lemburHours;
        case _DailyAttendanceStatus.off:
          off += 1;
        case _DailyAttendanceStatus.extraOff:
          extraOff += 1;
        case _DailyAttendanceStatus.cuti:
          cuti += 1;
        case _DailyAttendanceStatus.sakit:
          sakit += 1;
        case _DailyAttendanceStatus.alfa:
          alfa += 1;
        case _DailyAttendanceStatus.tidakHadir:
          tidakHadir += 1;
      }
    }

    recap.totalHadir = hadir;
    recap.totalOff = off;
    recap.totalTidakHadir = tidakHadir;
    recap.totalCuti = cuti;
    recap.totalExtraOff = extraOff;
    recap.totalSakit = sakit;
    recap.totalAlfa = alfa;
    recap.totalLembur = lembur;
  }

  String _dailyStatusLabel(_DailyAttendanceStatus status) {
    switch (status) {
      case _DailyAttendanceStatus.hadir:
        return 'Hadir';
      case _DailyAttendanceStatus.off:
        return 'Off';
      case _DailyAttendanceStatus.extraOff:
        return 'Extra Off';
      case _DailyAttendanceStatus.cuti:
        return 'Cuti';
      case _DailyAttendanceStatus.sakit:
        return 'Sakit';
      case _DailyAttendanceStatus.alfa:
        return 'Alfa';
      case _DailyAttendanceStatus.tidakHadir:
        return 'Tidak Hadir';
    }
  }

  Color _dailyStatusColor(_DailyAttendanceStatus status) {
    switch (status) {
      case _DailyAttendanceStatus.hadir:
        return const Color(0xFF1B5E20);
      case _DailyAttendanceStatus.off:
        return const Color(0xFF455A64);
      case _DailyAttendanceStatus.extraOff:
        return const Color(0xFF1565C0);
      case _DailyAttendanceStatus.cuti:
        return const Color(0xFF6A1B9A);
      case _DailyAttendanceStatus.sakit:
        return const Color(0xFFE65100);
      case _DailyAttendanceStatus.alfa:
        return const Color(0xFFC62828);
      case _DailyAttendanceStatus.tidakHadir:
        return const Color(0xFFB71C1C);
    }
  }

  String _timeText(TimeOfDay? value) {
    if (value == null) return '-';
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }

  TimeOfDay? _parseTimeOfDayHHMM(String value) {
    final parts = value.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  TimeOfDay? _parseTimeOfDay(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Widget _attendancePhotoPreview(String title, String? path, {VoidCallback? onTap}) {
    final hasPhoto = path != null && path.trim().isNotEmpty;
    Widget content;
    if (!hasPhoto) {
      content = const Center(child: Text('Tidak ada foto', style: TextStyle(fontSize: 12)));
    } else if (path!.startsWith('assets/')) {
      content = Image.asset(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else if (path.startsWith('http')) {
      content = Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (_, __, ___) =>
            const Center(child: Text('Foto gagal dimuat', style: TextStyle(fontSize: 12))),
      );
    } else if (File(path).existsSync()) {
      content = Image.file(File(path), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else {
      content = const Center(child: Text('Foto tidak ditemukan', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)));
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: hasPhoto ? onTap : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 120,
                width: double.infinity,
                color: const Color(0xFFECEFF5),
                child: Stack(
                  children: [
                    Positioned.fill(child: content),
                    if (hasPhoto && onTap != null)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRecap(_MonthlyRecap recap) {
    return 'Hadir ${recap.totalHadir}, Off ${recap.totalOff}, Tidak Hadir ${recap.totalTidakHadir}, Cuti ${recap.totalCuti}, Extra Off ${recap.totalExtraOff}, Sakit ${recap.totalSakit}, Alfa ${recap.totalAlfa}, Lembur ${recap.totalLembur} jam';
  }

  String _formatDailyDetail(_DailyAttendanceDetail detail) {
    return 'Status ${_dailyStatusLabel(detail.status)}, Masuk ${_timeText(detail.checkIn)}, Pulang ${_timeText(detail.checkOut)}, Lembur ${detail.lemburHours} jam, Catatan ${detail.note.trim().isEmpty ? "-" : detail.note}';
  }

  String _formatSlip(_SalarySlip slip) {
    return 'Gaji Pokok ${slip.gajiPokok}, Tunjangan Jabatan ${slip.tunjanganJabatan}, Lembur ${slip.lembur}, Tunjangan Lain ${slip.tunjanganLain}, Potongan Absen ${slip.potonganAbsen}, Total ${slip.netSalary}';
  }

  String _formatEmployee(_EmployeeData employee) {
    return 'kode karyawan ${employee.nik}, Jabatan ${employee.jobTitle}, Role ${_labelRole(employee.role)}, Departemen ${employee.department}, Status ${employee.employeeStatus}, Aktif ${employee.isActive ? "Ya" : "Tidak"}';
  }

  /// Gaji pokok penuh jika hadir >= 25. Kurang dari 25: potongan = (25 - hadir) × (gajiPokok / 30).
  int _calculatePotonganAbsen(int totalHadir, int gajiPokok) {
    if (totalHadir >= 25) return 0;
    return ((25 - totalHadir) * (gajiPokok / 30)).round();
  }

  _SalarySlip _createSalarySlip(_EmployeeData employee, _MonthlyRecap? recap) {
    final gajiPokok = employee.gajiPokok;
    final totalLembur = recap?.totalLembur ?? 0;
    final tunjanganJabatan = employee.role == AdminRole.admin
        ? 1200000
        : 500000;
    const lembur = 0;
    const tunjanganLain = 300000;
    const potonganPinjaman = 0;
    final potonganAbsen = _calculatePotonganAbsen(recap?.totalHadir ?? 0, gajiPokok);
    const potonganBpjsKesehatan = 120000;
    const potonganBpjsTkJht = 95000;
    const potonganBpjsTkJp = 65000;
    const potonganPph21 = 125000;
    final net = gajiPokok + tunjanganJabatan + (totalLembur * 25000) + tunjanganLain
        - potonganPinjaman - potonganAbsen - potonganBpjsKesehatan
        - potonganBpjsTkJht - potonganBpjsTkJp - potonganPph21;

    return _SalarySlip(
      id: 'SLIP-${DateTime.now().millisecondsSinceEpoch}-${employee.id}',
      employeeId: employee.id,
      employeeName: employee.fullName,
      month: _selectedMonth,
      year: _selectedYear,
      gajiPokok: gajiPokok,
      tunjanganJabatan: tunjanganJabatan,
      lembur: totalLembur * 25000,
      tunjanganLain: tunjanganLain,
      potonganPinjaman: potonganPinjaman,
      potonganAbsen: potonganAbsen,
      potonganBpjsKesehatan: potonganBpjsKesehatan,
      potonganBpjsTkJht: potonganBpjsTkJht,
      potonganBpjsTkJp: potonganBpjsTkJp,
      potonganPph21: potonganPph21,
      notes: 'Slip gaji dihitung dan dikirim dalam format PDF.',
      generatedAt: DateTime.now(),
      grossSalary: gajiPokok + tunjanganJabatan + (totalLembur * 25000) + tunjanganLain,
      netSalary: net,
    );
  }

  Future<void> _generateSlipForEmployee(_EmployeeData employee) async {
    try {
      final payroll = await _payrollApi.generateOne(employee.id);
      if (!mounted) return;
      final slip = _mapPayroll(payroll);
      setState(() {
        _salarySlips.removeWhere(
          (item) =>
              item.employeeId == employee.id &&
              item.month == _selectedMonth &&
              item.year == _selectedYear,
        );
        _salarySlips.insert(0, slip);
      });
      _addLog('Generate slip gaji', '${employee.fullName} ($_selectedMonth/$_selectedYear)',
          module: 'Payroll');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Slip gaji ${employee.fullName} berhasil digenerate.')),
      );
    } on ApiException catch (e) {
      print('[generateSlip ApiException] ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      print('[generateSlip ERROR] $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal generate slip gaji: $e')),
      );
    }
  }

  Future<void> _generateAllSlips() async {
    try {
      await _payrollApi.generateAll();
      if (!mounted) return;
      await _loadPayrolls();
      if (!mounted) return;
      _addLog('Generate massal slip gaji', 'Periode $_selectedMonth/$_selectedYear',
          module: 'Payroll');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil generate semua slip gaji.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal generate semua slip gaji.')),
      );
    }
  }

  Future<void> _editSlip(_SalarySlip slip) async {
    final gajiPokokController = TextEditingController(
      text: '${slip.gajiPokok}',
    );
    final tunjanganJabatanController = TextEditingController(
      text: '${slip.tunjanganJabatan}',
    );
    final lemburController = TextEditingController(text: '${slip.lembur}');
    final tunjanganLainController = TextEditingController(
      text: '${slip.tunjanganLain}',
    );
    final potonganPinjamanController = TextEditingController(
      text: '${slip.potonganPinjaman}',
    );
    final potonganAbsenController = TextEditingController(
      text: '${slip.potonganAbsen}',
    );
    final bpjsKesehatanController = TextEditingController(
      text: '${slip.potonganBpjsKesehatan}',
    );
    final bpjsTkJhtController = TextEditingController(
      text: '${slip.potonganBpjsTkJht}',
    );
    final bpjsTkJpController = TextEditingController(
      text: '${slip.potonganBpjsTkJp}',
    );
    final pph21Controller = TextEditingController(
      text: '${slip.potonganPph21}',
    );
    final notesController = TextEditingController(text: slip.notes);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit Slip ${slip.employeeName}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: gajiPokokController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Gaji Pokok'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tunjanganJabatanController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tunjangan Jabatan',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: lemburController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Lembur'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tunjanganLainController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tunjangan Lain',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: potonganPinjamanController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Potongan Pinjaman',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: potonganAbsenController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Potongan Absen',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bpjsKesehatanController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Potongan BPJS Kesehatan',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bpjsTkJhtController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Potongan BPJS TK JHT',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bpjsTkJpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Potongan BPJS TK JP',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pph21Controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Potongan Pajak PPh21',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Catatan'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  final updated = await _payrollApi.updatePayroll(slip.id, {
                    'basic_salary': _safeParseInt(gajiPokokController.text, slip.gajiPokok).toDouble(),
                    'position_allowance': _safeParseInt(tunjanganJabatanController.text, slip.tunjanganJabatan).toDouble(),
                    'overtime_rate': _safeParseInt(lemburController.text, slip.lembur).toDouble(),
                    'other_allowance': _safeParseInt(tunjanganLainController.text, slip.tunjanganLain).toDouble(),
                    'loan_deduction': _safeParseInt(potonganPinjamanController.text, slip.potonganPinjaman).toDouble(),
                    'attendance_deduction': _safeParseInt(potonganAbsenController.text, slip.potonganAbsen).toDouble(),
                    'income_tax': _safeParseInt(pph21Controller.text, slip.potonganPph21).toDouble(),
                  });
                  if (!mounted) return;
                  final newSlip = _mapPayroll(updated);
                  setState(() {
                    final idx = _salarySlips.indexWhere((s) => s.id == slip.id);
                    if (idx >= 0) _salarySlips[idx] = newSlip;
                  });
                  _addLog('Edit slip gaji', '${slip.employeeName} (${slip.month}/${slip.year})',
                      module: 'Payroll');
                } on ApiException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menyimpan slip gaji.')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendSlip(_SalarySlip slip) async {
    try {
      await _payrollApi.sendPayroll(slip.id);
      if (!mounted) return;
      final sentAt = DateTime.now();
      setState(() => slip.sentAt = sentAt);
      widget.onSlipSent?.call(
        SentPayrollSlip(
          employeeId: slip.employeeId,
          employeeName: slip.employeeName,
          month: slip.month,
          year: slip.year,
          sentAt: sentAt,
          totalGaji: slip.netSalary,
        ),
      );
      _addLog('Kirim slip gaji PDF', '${slip.employeeName} (${slip.month}/${slip.year})',
          module: 'Payroll');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Slip gaji ${slip.employeeName} berhasil dikirim.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim slip gaji.')),
      );
    }
  }

  Future<void> _showAddEmployeeDialog() async {
    await _showEmployeeDialog();
  }

  Future<void> _showEditEmployeeDialog(_EmployeeData employee) async {
    try {
      final detail = await _userApi.getByID(employee.id);
      final full = _mapUser(detail);
      if (!mounted) return;
      await _showEmployeeDialog(employee: full);
    } catch (_) {
      if (!mounted) return;
      await _showEmployeeDialog(employee: employee);
    }
  }

  Future<void> _showEmployeeDialog({_EmployeeData? employee}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _EmployeeFormPage(
          employee: employee,
          userApi: _userApi,
        ),
      ),
    );
    if (saved == true && mounted) {
      await _loadEmployees();
      _addLog(
        employee == null ? 'Tambah karyawan' : 'Edit data karyawan',
        '',
        module: 'Manajemen Karyawan',
      );
    }
  }

  Future<void> _showDailyDetail(_MonthlyRecap recap) async {
    final startDate = DateTime(recap.year, recap.month, 1);
    final endDate = DateTime(recap.year, recap.month + 1, 0);
    Map<String, AttendanceModel> logsByDate = {};
    try {
      final logs = await _attendanceApi.getLogs(
        startDate: startDate,
        endDate: endDate,
        userId: recap.userId,
      );
      logsByDate = {for (final l in logs) l.date: l};
      print('[_showDailyDetail] loaded ${logs.length} logs for userId=${recap.userId}');
    } catch (e) {
      print('[_showDailyDetail] failed to load logs: $e');
    }
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final items = recap.dailyDetails
          ..sort((a, b) => b.date.compareTo(a.date));
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail Rekap Absensi - ${recap.employeeName}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Menampilkan foto, jam, status, dan catatan. Edit bisa dilakukan per hari.',
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        DateFormat(
                                          'EEEE, dd MMMM yyyy',
                                          'id_ID',
                                        ).format(item.date),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _dailyStatusColor(item.status),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        _dailyStatusLabel(item.status),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Jam Masuk: ${_timeText(item.checkIn)}'),
                                Text('Jam Pulang: ${_timeText(item.checkOut)}'),
                                Text('Lembur: ${item.lemburHours} jam'),
                                Text(
                                  'Catatan: ${item.note.trim().isEmpty ? '-' : item.note}',
                                ),
                                if (item.isManuallyEdited)
                                  const Text(
                                    'Data ini sudah diedit manual oleh admin.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                if (item.status != _DailyAttendanceStatus.hadir)
                                  Row(children: [
                                    _attendancePhotoPreview(
                                      'Foto Bukti',
                                      item.evidencePhotoPath,
                                      onTap: item.evidencePhotoPath != null ? () => _showPhotoPreview(context, item.evidencePhotoPath!) : null,
                                    ),
                                  ])
                                else
                                  Row(children: [
                                    _attendancePhotoPreview(
                                      'Foto Masuk',
                                      item.checkInPhotoPath,
                                      onTap: item.checkInPhotoPath != null ? () => _showPhotoPreview(context, item.checkInPhotoPath!) : null,
                                    ),
                                    const SizedBox(width: 10),
                                    _attendancePhotoPreview(
                                      'Foto Pulang',
                                      item.checkOutPhotoPath,
                                      onTap: item.checkOutPhotoPath != null ? () => _showPhotoPreview(context, item.checkOutPhotoPath!) : null,
                                    ),
                                  ]),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _editDailyAttendance(recap, item),
                                    icon: const Icon(Icons.edit_rounded),
                                    label: const Text('Edit Data Harian'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editDailyAttendance(
    _MonthlyRecap recap,
    _DailyAttendanceDetail detail,
  ) async {
    var selectedStatus = detail.status;
    final checkInController = TextEditingController(
      text: detail.checkIn == null
          ? ''
          : '${detail.checkIn!.hour.toString().padLeft(2, '0')}:${detail.checkIn!.minute.toString().padLeft(2, '0')}',
    );
    final checkOutController = TextEditingController(
      text: detail.checkOut == null
          ? ''
          : '${detail.checkOut!.hour.toString().padLeft(2, '0')}:${detail.checkOut!.minute.toString().padLeft(2, '0')}',
    );
    final lemburController = TextEditingController(
      text: '${detail.lemburHours}',
    );
    final noteController = TextEditingController(text: detail.note);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(
                'Edit Detail ${DateFormat('dd MMM yyyy', 'id_ID').format(detail.date)}',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<_DailyAttendanceStatus>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status Kehadiran',
                        ),
                        items: _DailyAttendanceStatus.values
                            .where((s) => s != _DailyAttendanceStatus.tidakHadir)
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(_dailyStatusLabel(status)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setLocalState(() => selectedStatus = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: checkInController,
                        decoration: const InputDecoration(
                          labelText: 'Jam Masuk (HH:mm)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: checkOutController,
                        decoration: const InputDecoration(
                          labelText: 'Jam Pulang (HH:mm)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: lemburController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Lembur (jam)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Catatan'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    if (detail.attendanceId.isEmpty) return;
                    final checkIn = _parseTimeOfDay(checkInController.text);
                    final checkOut = _parseTimeOfDay(checkOutController.text);
                    final lemburHours = _safeParseInt(lemburController.text, detail.lemburHours).clamp(0, 24);
                    final note = noteController.text.trim();

                    String? checkInStr;
                    String? checkOutStr;
                    if (checkIn != null) {
                      final d = detail.date;
                      checkInStr = '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}T${checkIn.hour.toString().padLeft(2,'0')}:${checkIn.minute.toString().padLeft(2,'0')}:00Z';
                    }
                    if (checkOut != null) {
                      final d = detail.date;
                      checkOutStr = '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}T${checkOut.hour.toString().padLeft(2,'0')}:${checkOut.minute.toString().padLeft(2,'0')}:00Z';
                    }

                    try {
                      await _attendanceApi.updateAttendance(detail.attendanceId, {
                        'status': _apiDailyStatus(selectedStatus),
                        if (checkInStr != null) 'check_in_at': checkInStr,
                        if (checkOutStr != null) 'check_out_at': checkOutStr,
                        'overtime_hours': lemburHours,
                        'note': note,
                      });
                      if (!mounted) return;
                      setState(() {
                        detail.status = selectedStatus;
                        detail.checkIn = checkIn;
                        detail.checkOut = checkOut;
                        detail.lemburHours = lemburHours;
                        detail.note = note;
                        detail.isManuallyEdited = true;
                        _syncRecapTotalsFromDailyDetails(recap);
                      });
                      _addLog('Edit detail rekap absensi',
                          '${recap.employeeName} - ${DateFormat('dd/MM/yyyy').format(detail.date)}',
                          module: 'Rekap Absensi');
                    } on ApiException catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal menyimpan perubahan absensi.')),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editRecap(_MonthlyRecap recap) async {
    final hadirController = TextEditingController(text: '${recap.totalHadir}');
    final offController = TextEditingController(text: '${recap.totalOff}');
    final cutiController = TextEditingController(text: '${recap.totalCuti}');
    final extraOffController = TextEditingController(
      text: '${recap.totalExtraOff}',
    );
    final sakitController = TextEditingController(text: '${recap.totalSakit}');
    final lemburController = TextEditingController(
      text: '${recap.totalLembur}',
    );
    final tidakHadirController = TextEditingController(
      text: '${recap.totalTidakHadir}',
    );
    final alfaController = TextEditingController(text: '${recap.totalAlfa}');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit Rekap - ${recap.employeeName}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _numberField(hadirController, 'Total Hadir'),
                  _numberField(offController, 'Total Off'),
                  _numberField(cutiController, 'Total Cuti'),
                  _numberField(extraOffController, 'Total Extra Off'),
                  _numberField(sakitController, 'Total Sakit'),
                  _numberField(lemburController, 'Total Lembur (jam)'),
                  _numberField(tidakHadirController, 'Total Tidak Hadir'),
                  _numberField(alfaController, 'Total Alfa'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final beforeSummary = _formatRecap(recap);
                setState(() {
                  recap.totalHadir = _safeParseInt(
                    hadirController.text,
                    recap.totalHadir,
                  );
                  recap.totalOff = _safeParseInt(
                    offController.text,
                    recap.totalOff,
                  );
                  recap.totalCuti = _safeParseInt(
                    cutiController.text,
                    recap.totalCuti,
                  );
                  recap.totalExtraOff = _safeParseInt(
                    extraOffController.text,
                    recap.totalExtraOff,
                  );
                  recap.totalSakit = _safeParseInt(
                    sakitController.text,
                    recap.totalSakit,
                  );
                  recap.totalLembur = _safeParseInt(
                    lemburController.text,
                    recap.totalLembur,
                  );
                  recap.totalTidakHadir = _safeParseInt(
                    tidakHadirController.text,
                    recap.totalTidakHadir,
                  );
                  recap.totalAlfa = _safeParseInt(
                    alfaController.text,
                    recap.totalAlfa,
                  );
                });
                _addLog(
                  'Edit rekap absensi',
                  '${recap.employeeName} (${recap.month}/${recap.year})',
                  module: 'Rekap Absensi',
                  before: beforeSummary,
                  after: _formatRecap(recap),
                  detail: 'Edit ringkasan bulanan oleh admin',
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  String _labelRole(AdminRole role) =>
      role == AdminRole.admin ? 'Admin' : 'User';

  String _labelApprovalType(ApprovalType type) {
    switch (type) {
      case ApprovalType.izin:
        return 'Izin';
      case ApprovalType.cuti:
        return 'Cuti';
      case ApprovalType.extraOff:
        return 'Extra Off';
      case ApprovalType.sakit:
        return 'Sakit';
      case ApprovalType.lembur:
        return 'Lembur';
    }
  }

  String _labelApprovalStatus(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return 'Pending';
      case ApprovalStatus.approved:
        return 'Approve';
      case ApprovalStatus.rejected:
        return 'Reject';
    }
  }

  Color _statusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return const Color(0xFFF9A825);
      case ApprovalStatus.approved:
        return const Color(0xFF2E7D32);
      case ApprovalStatus.rejected:
        return const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final monthOptions = List<int>.generate(12, (i) => i + 1);
    final yearOptions = List<int>.generate(
      5,
      (i) => DateTime.now().year - 2 + i,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _OverviewCard(
          totalKaryawan: _totalKaryawan,
          hadirHariIni: _jumlahHadirHariIni,
          totalPending: _totalPending,
          totalOffHariIni: _jumlahOffHariIni,
        ),
        const SizedBox(height: 12),
        _RecapCard(
          selectedMonth: _selectedMonth,
          selectedYear: _selectedYear,
          monthOptions: monthOptions,
          yearOptions: yearOptions,
          onMonthChanged: (value) {
            setState(() => _selectedMonth = value);
            _loadRecap();
            _loadPayrolls();
            _loadApprovalRequests();
          },
          onYearChanged: (value) {
            setState(() => _selectedYear = value);
            _loadRecap();
            _loadPayrolls();
            _loadApprovalRequests();
          },
          onNameFilterChanged: (value) => setState(() => _nameFilter = value),
          currentRecapData: _currentRecapData,
          onExportExcel: _exportData,
          onShowDetail: _showDailyDetail,
          onEditRecap: _editRecap,
          annualLeaveQuota: _annualLeaveQuota,
          remainingLeaveByEmployee: {
            for (final employee in _employees)
              employee.fullName: _remainingLeaveForEmployee(employee.fullName),
          },
          emptyTextColor: cs.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        _ApprovalCard(
          requests: _approvalRequests,
          onUpdateApproval: _updateApproval,
          labelApprovalType: _labelApprovalType,
          labelApprovalStatus: _labelApprovalStatus,
          statusColor: _statusColor,
          approvalHistory: _activityLogs
              .where(
                (log) =>
                    log.action.contains('Approve') ||
                    log.action.contains('Reject'),
              )
              .take(8)
              .toList(),
          annualLeaveQuota: _annualLeaveQuota,
          remainingLeaveLookup: _remainingLeaveForEmployee,
          emptyTextColor: cs.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        _PayrollCard(
          employees: _employees.where((employee) => employee.isActive).toList(),
          salarySlips: _salarySlips
              .where(
                (slip) =>
                    slip.month == _selectedMonth && slip.year == _selectedYear,
              )
              .toList(),
          selectedMonth: _selectedMonth,
          selectedYear: _selectedYear,
          onGenerateAll: _generateAllSlips,
          onGenerateEmployee: _generateSlipForEmployee,
          onEditSlip: _editSlip,
          onSendSlip: _sendSlip,
        ),
        const SizedBox(height: 12),
        _EmployeeManagementCard(
          employees: _employees,
          onAdd: _showAddEmployeeDialog,
          onEdit: _showEditEmployeeDialog,
          onChangeRole: (employee, role) async {
            final apiRole = role == AdminRole.admin ? 'admin' : 'user';
            try {
              await _userApi.updateUser(employee.id, {'role': apiRole});
              if (!mounted) return;
              setState(() => employee.role = role);
              _addLog('Ubah role', employee.fullName, module: 'Manajemen Karyawan');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Role berhasil diubah.')),
              );
            } catch (e) {
              print('[onChangeRole ERROR] $e');
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gagal mengubah role.')),
              );
            }
          },
          onToggleActive: (employee, value) async {
            try {
              await _userApi.updateUser(employee.id, {'is_active': value});
              if (!mounted) return;
              setState(() => employee.isActive = value);
              _addLog(value ? 'Aktifkan karyawan' : 'Nonaktifkan karyawan',
                  employee.fullName, module: 'Manajemen Karyawan');
            } catch (_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gagal mengubah status karyawan.')),
              );
            }
          },
          onResetPassword: (employee) async {
            final success = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => _AdminResetPasswordPage(
                  employeeId: employee.id,
                  employeeName: employee.fullName,
                  userApi: _userApi,
                ),
              ),
            );
            if (success == true && mounted) {
              _addLog('Reset password', employee.fullName, module: 'Keamanan Akun');
            }
          },
          onDelete: (employee) async {
            try {
              await _userApi.deleteUser(employee.id);
              if (!mounted) return;
              setState(() => _employees.remove(employee));
              _addLog('Hapus data karyawan', employee.fullName, module: 'Manajemen Karyawan');
            } on ApiException catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
            } catch (_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gagal menghapus karyawan.')),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _LogCard(
          logs: _activityLogs,
          emptyTextColor: cs.onSurfaceVariant,
          isLoading: _activityLogsLoading,
          onRefresh: _loadActivityLogs,
        ),
      ],
    );
  }
}

// ─── Admin Reset Password Page ────────────────────────────────────────────────

class _AdminResetPasswordPage extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  final UserApi userApi;

  const _AdminResetPasswordPage({
    required this.employeeId,
    required this.employeeName,
    required this.userApi,
  });

  @override
  State<_AdminResetPasswordPage> createState() => _AdminResetPasswordPageState();
}

class _AdminResetPasswordPageState extends State<_AdminResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.userApi.adminResetPassword(widget.employeeId, _newPassCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password ${widget.employeeName} berhasil direset. Segera hubungi karyawan.'),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mereset password. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password Karyawan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE65100), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Perhatian — Hanya Admin',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tindakan ini akan mereset password karyawan ${widget.employeeName} secara permanen. '
                          'Setelah berhasil, segera hubungi karyawan dan berikan password baru.',
                          style: TextStyle(color: cs.onSurface, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nama karyawan
            Text(
              'Karyawan: ${widget.employeeName}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 20),

            // Password Baru
            TextFormField(
              controller: _newPassCtrl,
              obscureText: _hideNew,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_hideNew ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                  onPressed: () => setState(() => _hideNew = !_hideNew),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi.';
                if (v.length < 3) return 'Minimal 3 karakter.';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Konfirmasi Password
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _hideConfirm,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password Baru',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_hideConfirm ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                  onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi.';
                if (v != _newPassCtrl.text) return 'Konfirmasi password tidak sama.';
                return null;
              },
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.lock_reset_rounded),
              label: Text(_isSubmitting ? 'Mereset...' : 'Reset Password'),
            ),
            const SizedBox(height: 12),
            Text(
              'Setelah reset, karyawan harus login menggunakan password baru ini.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Employee Form Page ────────────────────────────────────────────────────────

class _EmployeeFormPage extends StatefulWidget {
  final _EmployeeData? employee;
  final UserApi userApi;

  const _EmployeeFormPage({this.employee, required this.userApi});

  @override
  State<_EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<_EmployeeFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _nikCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _jobTitleCtrl;
  late final TextEditingController _departmentCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _bankCtrl;
  late final TextEditingController _gajiCtrl;
  late final TextEditingController _placeOfBirthCtrl;

  late AdminRole _role;
  late String _gender;
  late String _employeeStatus;
  late DateTime _birthDate;
  late DateTime _joinDate;

  bool _isSaving = false;

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _fullNameCtrl = TextEditingController(text: e?.fullName ?? '');
    _nikCtrl = TextEditingController(text: e?.nik ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _jobTitleCtrl = TextEditingController(text: e?.jobTitle ?? '');
    _departmentCtrl = TextEditingController(text: e?.department ?? '');
    _phoneCtrl = TextEditingController(text: e?.phoneNumber ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _bankCtrl = TextEditingController(text: e?.bankAccountNumber ?? '');
    _gajiCtrl = TextEditingController(text: '${e?.gajiPokok ?? 0}');
    _placeOfBirthCtrl = TextEditingController(text: e?.placeOfBirth ?? '');
    _role = e?.role ?? AdminRole.user;
    final genderDisplay = genderToDisplay(e?.gender);
    _gender = genderDisplay == '-' ? 'Laki-laki' : genderDisplay;
    final statusDisplay = employmentStatusToDisplay(e?.employeeStatus);
    _employeeStatus = statusDisplay == '-' ? 'Tetap' : statusDisplay;
    _birthDate = e?.birthDate ?? DateTime(2000, 1, 1);
    _joinDate = e?.joinDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _nikCtrl.dispose();
    _emailCtrl.dispose();
    _jobTitleCtrl.dispose();
    _departmentCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _bankCtrl.dispose();
    _gajiCtrl.dispose();
    _placeOfBirthCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
    DateTime? lastDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _apiStatus(String display) {
    switch (display) {
      case 'Tetap': return 'permanent';
      case 'Kontrak': return 'contract';
      case 'Magang': return 'internship';
      case 'Freelance': return 'freelance';
      default: return 'permanent';
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final fullName = _fullNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final nik = _nikCtrl.text.trim();
    final jobTitle = _jobTitleCtrl.text.trim();
    final department = _departmentCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final bank = _bankCtrl.text.trim();
    final gajiPokok = int.tryParse(_gajiCtrl.text.trim()) ?? 0;
    final placeOfBirth = _placeOfBirthCtrl.text.trim();
    final apiRole = _role == AdminRole.admin ? 'admin' : 'user';

    try {
      if (_isEdit) {
        await widget.userApi.updateUser(widget.employee!.id, {
          'full_name': fullName,
          if (email.isNotEmpty) 'email': email,
          if (nik.isNotEmpty) 'employee_code': nik,
          if (placeOfBirth.isNotEmpty) 'birth_place': placeOfBirth,
          'birth_date': _fmt(_birthDate),
          'gender': genderToApi(_gender),
          if (address.isNotEmpty) 'address': address,
          if (phone.isNotEmpty) 'phone_number': phone,
          if (jobTitle.isNotEmpty) 'position': jobTitle,
          'role': apiRole,
          if (department.isNotEmpty) 'department': department,
          'employment_status': _apiStatus(_employeeStatus),
          'joined_at': _fmt(_joinDate),
          if (bank.isNotEmpty) 'bank_account_number': bank,
          if (gajiPokok > 0) 'basic_salary': gajiPokok.toDouble(),
        });
      } else {
        await widget.userApi.createUser(
          fullName: fullName,
          email: email,
          password: 'Password123!',
          role: apiRole,
          employeeCode: nik,
          birthPlace: placeOfBirth,
          birthDate: _fmt(_birthDate),
          gender: genderToApi(_gender),
          address: address,
          phoneNumber: phone,
          position: jobTitle,
          department: department,
          employmentStatus: _apiStatus(_employeeStatus),
          joinedAt: _fmt(_joinDate),
          bankAccountNumber: bank,
          basicSalary: gajiPokok.toDouble(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Data karyawan berhasil diperbarui.' : 'Karyawan berhasil ditambahkan.')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan data karyawan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget sectionLabel(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary),
          ),
        );

    Widget reqStar(String label) => Text.rich(TextSpan(children: [
          TextSpan(text: label),
          const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
        ]));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Karyawan' : 'Tambah Karyawan'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Foto ───────────────────────────────────────────────────────
            Center(
              child: ProfileAvatar(
                radius: 40,
                photoPath: widget.employee?.profilePhotoPath,
              ),
            ),
            const SizedBox(height: 20),

            // ── Akun ───────────────────────────────────────────────────────
            sectionLabel('Akun'),
            TextFormField(
              controller: _fullNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                label: reqStar('Nama Lengkap'),
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama lengkap wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                label: _isEdit ? const Text('Email') : reqStar('Email'),
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (!_isEdit && (v == null || v.trim().isEmpty)) {
                  return 'Email wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AdminRole>(
              value: _role,
              decoration: InputDecoration(
                label: reqStar('Role'),
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: AdminRole.admin, child: Text('Admin')),
                DropdownMenuItem(value: AdminRole.user, child: Text('User')),
              ],
              onChanged: (v) { if (v != null) setState(() => _role = v); },
            ),
            const SizedBox(height: 20),

            // ── Kepegawaian ────────────────────────────────────────────────
            sectionLabel('Kepegawaian'),
            TextFormField(
              controller: _nikCtrl,
              decoration: const InputDecoration(
                labelText: 'Kode Karyawan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _jobTitleCtrl,
              decoration: const InputDecoration(
                labelText: 'Jabatan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _departmentCtrl,
              decoration: const InputDecoration(
                labelText: 'Departemen',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _employeeStatus,
              decoration: const InputDecoration(
                labelText: 'Status Karyawan',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Tetap', child: Text('Tetap')),
                DropdownMenuItem(value: 'Kontrak', child: Text('Kontrak')),
                DropdownMenuItem(value: 'Magang', child: Text('Magang')),
                DropdownMenuItem(value: 'Freelance', child: Text('Freelance')),
              ],
              onChanged: (v) { if (v != null) setState(() => _employeeStatus = v); },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(
                initial: _joinDate,
                onPicked: (d) => _joinDate = d,
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              ),
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Masuk',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_joinDate)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gajiCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Gaji Pokok',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 20),

            // ── Data Pribadi ───────────────────────────────────────────────
            sectionLabel('Data Pribadi'),
            TextFormField(
              controller: _placeOfBirthCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Tempat Lahir',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(
                initial: _birthDate,
                onPicked: (d) => _birthDate = d,
                lastDate: DateTime.now(),
              ),
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Lahir',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_birthDate)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Jenis Kelamin',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
              ],
              onChanged: (v) { if (v != null) setState(() => _gender = v); },
            ),
            const SizedBox(height: 20),

            // ── Kontak & Rekening ──────────────────────────────────────────
            sectionLabel('Kontak & Rekening'),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'No HP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Alamat',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bankCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'No Rekening',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Menyimpan...' : (_isEdit ? 'Simpan Perubahan' : 'Tambah Karyawan')),
            ),
            const SizedBox(height: 8),
            Text(
              '* Wajib diisi. Password default: Password123!',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final int totalKaryawan;
  final int hadirHariIni;
  final int totalPending;
  final int totalOffHariIni;

  const _OverviewCard({
    required this.totalKaryawan,
    required this.hadirHariIni,
    required this.totalPending,
    required this.totalOffHariIni,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Ringkas',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricChip(label: 'Total Karyawan', value: '$totalKaryawan'),
                _MetricChip(label: 'Hadir Hari Ini', value: '$hadirHariIni'),
                _MetricChip(
                  label: 'Pending Izin/Cuti/Extra Off/Sakit/Lembur',
                  value: '$totalPending',
                ),
                _MetricChip(
                  label: 'Total Off Hari Ini',
                  value: '$totalOffHariIni',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecapCard extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final List<int> monthOptions;
  final List<int> yearOptions;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<String> onNameFilterChanged;
  final List<_MonthlyRecap> currentRecapData;
  final VoidCallback onExportExcel;
  final ValueChanged<_MonthlyRecap> onShowDetail;
  final ValueChanged<_MonthlyRecap> onEditRecap;
  final int annualLeaveQuota;
  final Map<String, int> remainingLeaveByEmployee;
  final Color emptyTextColor;

  const _RecapCard({
    required this.selectedMonth,
    required this.selectedYear,
    required this.monthOptions,
    required this.yearOptions,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onNameFilterChanged,
    required this.currentRecapData,
    required this.onExportExcel,
    required this.onShowDetail,
    required this.onEditRecap,
    required this.annualLeaveQuota,
    required this.remainingLeaveByEmployee,
    required this.emptyTextColor,
  });

  String _statusLabel(_DailyAttendanceStatus status) {
    switch (status) {
      case _DailyAttendanceStatus.hadir:
        return 'Hadir';
      case _DailyAttendanceStatus.off:
        return 'Off';
      case _DailyAttendanceStatus.extraOff:
        return 'Extra Off';
      case _DailyAttendanceStatus.cuti:
        return 'Cuti';
      case _DailyAttendanceStatus.sakit:
        return 'Sakit';
      case _DailyAttendanceStatus.alfa:
        return 'Alfa';
      case _DailyAttendanceStatus.tidakHadir:
        return 'Tidak Hadir';
    }
  }

  String _timeLabel(TimeOfDay? value) {
    if (value == null) return '-';
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _miniPhoto(String? path) {
    Widget content;
    if (path == null || path.trim().isEmpty) {
      content = const Center(
        child: Text('Tanpa foto', style: TextStyle(fontSize: 11)),
      );
    } else if (path.startsWith('http')) {
      content = Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Center(child: Text('Foto hilang', style: TextStyle(fontSize: 11))),
      );
    } else if (path.startsWith('assets/')) {
      content = Image.asset(path, fit: BoxFit.cover);
    } else if (File(path).existsSync()) {
      content = Image.file(File(path), fit: BoxFit.cover);
    } else {
      content = const Center(
        child: Text('Tanpa foto', style: TextStyle(fontSize: 11)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 56,
        width: 76,
        color: const Color(0xFFECEFF5),
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rekap Absensi (All Karyawan)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Bulan',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: monthOptions
                        .map(
                          (month) => DropdownMenuItem(
                            value: month,
                            child: Text(
                              DateFormat(
                                'MMMM',
                                'id_ID',
                              ).format(DateTime(2026, month)),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      onMonthChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Tahun',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: yearOptions
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      onYearChanged(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: onNameFilterChanged,
              decoration: const InputDecoration(
                labelText: 'Filter Nama Karyawan',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onExportExcel,
                  icon: const Icon(Icons.table_view_rounded),
                  label: const Text('Export Excel'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Rekap Per Karyawan',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (currentRecapData.isEmpty)
              Text(
                'Data tidak ditemukan.',
                style: TextStyle(color: emptyTextColor),
              )
            else
              _PaginatedSection<_MonthlyRecap>(
                items: currentRecapData,
                itemBuilder: (item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.employeeName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hadir ${item.totalHadir} | Off ${item.totalOff} | Tidak Hadir ${item.totalTidakHadir} | Cuti ${item.totalCuti} | Extra Off ${item.totalExtraOff} | Sakit ${item.totalSakit} | Alfa ${item.totalAlfa} | Lembur ${item.totalLembur} jam',
                        ),
                        Text(
                          'Sisa Cuti ${remainingLeaveByEmployee[item.employeeName] ?? annualLeaveQuota}/$annualLeaveQuota | Detail harian ${item.dailyDetails.length} hari',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (item.dailyDetails.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Builder(
                            builder: (_) {
                              final latest = item.dailyDetails
                                ..sort((a, b) => b.date.compareTo(a.date));
                              final day = latest.first;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Absensi terbaru: ${DateFormat('dd MMM yyyy', 'id_ID').format(day.date)} | ${_statusLabel(day.status)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Jam masuk ${_timeLabel(day.checkIn)} | Jam pulang ${_timeLabel(day.checkOut)}',
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _miniPhoto(day.checkInPhotoPath),
                                      const SizedBox(width: 8),
                                      _miniPhoto(day.checkOutPhotoPath),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => onShowDetail(item),
                              icon: const Icon(Icons.visibility_rounded),
                              label: const Text('Detail Lengkap'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final List<_ApprovalRequest> requests;
  final void Function(_ApprovalRequest, ApprovalStatus) onUpdateApproval;
  final String Function(ApprovalType) labelApprovalType;
  final String Function(ApprovalStatus) labelApprovalStatus;
  final Color Function(ApprovalStatus) statusColor;
  final List<_ActivityLog> approvalHistory;
  final int annualLeaveQuota;
  final int Function(String employeeName) remainingLeaveLookup;
  final Color emptyTextColor;

  const _ApprovalCard({
    required this.requests,
    required this.onUpdateApproval,
    required this.labelApprovalType,
    required this.labelApprovalStatus,
    required this.statusColor,
    required this.approvalHistory,
    required this.annualLeaveQuota,
    required this.remainingLeaveLookup,
    required this.emptyTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Approval Izin/Cuti/Extra Off/Sakit/Lembur',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (requests.isEmpty)
              Text('Tidak ada pengajuan.', style: TextStyle(color: emptyTextColor))
            else
              _PaginatedSection<_ApprovalRequest>(
                items: requests,
                itemBuilder: (item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.employeeName} - ${labelApprovalType(item.type)}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor(item.status),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                labelApprovalStatus(item.status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Tanggal: ${DateFormat('dd MMM yyyy', 'id_ID').format(item.date)}'),
                        Text(
                          'Alasan: ${(item.reason == null || item.reason!.trim().isEmpty) ? '-' : item.reason}',
                        ),
                        if (item.attachment != null && item.attachment!.isNotEmpty)
                          GestureDetector(
                            onTap: () async {
                              final uri = Uri.tryParse(item.attachment!);
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: const Text(
                              'Lampiran',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.blue,
                              ),
                            ),
                          )
                        else
                          const Text('Lampiran: -'),
                        if (item.type == ApprovalType.cuti)
                          Text(
                            'Sisa Cuti: ${remainingLeaveLookup(item.employeeName)}/$annualLeaveQuota',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        if (item.status == ApprovalStatus.pending) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: () => onUpdateApproval(item, ApprovalStatus.approved),
                                  child: const Text('Approve'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: () => onUpdateApproval(item, ApprovalStatus.rejected),
                                  child: const Text('Reject'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Riwayat Approval',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            if (approvalHistory.isEmpty)
              Text(
                'Belum ada riwayat approval.',
                style: TextStyle(color: emptyTextColor),
              )
            else
              ...approvalHistory.map(
                (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${DateFormat('dd/MM HH:mm').format(log.time)} - ${log.actor} ${log.action} (${log.target})',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PayrollCard extends StatelessWidget {
  final List<_EmployeeData> employees;
  final List<_SalarySlip> salarySlips;
  final int selectedMonth;
  final int selectedYear;
  final VoidCallback onGenerateAll;
  final ValueChanged<_EmployeeData> onGenerateEmployee;
  final ValueChanged<_SalarySlip> onEditSlip;
  final ValueChanged<_SalarySlip> onSendSlip;

  const _PayrollCard({
    required this.employees,
    required this.salarySlips,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onGenerateAll,
    required this.onGenerateEmployee,
    required this.onEditSlip,
    required this.onSendSlip,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payroll & Slip Gaji',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Periode $selectedMonth/$selectedYear - komponen gaji dan potongan, kirim dalam format PDF.',
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onGenerateAll,
              icon: const Icon(Icons.calculate_rounded),
              label: const Text('Generate Semua Slip'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Generate Per Karyawan',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _PaginatedSection<_EmployeeData>(
              items: employees,
              itemBuilder: (employee) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(employee.fullName)),
                    OutlinedButton.icon(
                      onPressed: () => onGenerateEmployee(employee),
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('Generate'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Slip Terbentuk',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (salarySlips.isEmpty)
              const Text('Belum ada slip untuk periode ini.')
            else
              _PaginatedSection<_SalarySlip>(
                items: salarySlips,
                itemBuilder: (slip) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                slip.employeeName,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text('Gaji Bersih: ${currency.format(slip.netSalary)}'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Gaji Pokok: ${currency.format(slip.gajiPokok)}'),
                        Text('Tunjangan Jabatan: ${currency.format(slip.tunjanganJabatan)}'),
                        Text('Lembur: ${currency.format(slip.lembur)}'),
                        Text('Tunjangan Lain: ${currency.format(slip.tunjanganLain)}'),
                        Text(
                          'Gaji Kotor: ${currency.format(slip.grossSalary)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Divider(height: 12),
                        Text('Potongan Pinjaman: ${currency.format(slip.potonganPinjaman)}'),
                        Text('Potongan Absen: ${currency.format(slip.potonganAbsen)}'),
                        Text('Potongan BPJS Kesehatan: ${currency.format(slip.potonganBpjsKesehatan)}'),
                        Text('Potongan BPJS TK JHT: ${currency.format(slip.potonganBpjsTkJht)}'),
                        Text('Potongan BPJS TK JP: ${currency.format(slip.potonganBpjsTkJp)}'),
                        Text('Potongan Pajak PPh21: ${currency.format(slip.potonganPph21)}'),
                        Text('Catatan: ${slip.notes.isEmpty ? '-' : slip.notes}'),
                        Text(
                          slip.sentAt == null
                              ? 'Status: Belum dikirim'
                              : 'Status: Terkirim ${DateFormat('dd/MM/yyyy HH:mm').format(slip.sentAt!)}',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: () => onEditSlip(slip),
                                child: const Text('Edit'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => onSendSlip(slip),
                                child: Text(slip.sentAt == null ? 'Kirim PDF' : 'Kirim Ulang PDF'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeManagementCard extends StatelessWidget {
  final List<_EmployeeData> employees;
  final VoidCallback onAdd;
  final ValueChanged<_EmployeeData> onEdit;
  final void Function(_EmployeeData, AdminRole) onChangeRole;
  final void Function(_EmployeeData, bool) onToggleActive;
  final ValueChanged<_EmployeeData> onResetPassword;
  final ValueChanged<_EmployeeData> onDelete;

  const _EmployeeManagementCard({
    required this.employees,
    required this.onAdd,
    required this.onEdit,
    required this.onChangeRole,
    required this.onToggleActive,
    required this.onResetPassword,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Manajemen Data Karyawan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Tambah'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _PaginatedSection<_EmployeeData>(
              items: employees,
              itemBuilder: (employee) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileAvatar(radius: 22, photoPath: employee.profilePhotoPath),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employee.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                Text('kode karyawan: ${employee.nik}', style: const TextStyle(fontSize: 12)),
                                Text('${employee.jobTitle} | ${employee.department}', style: const TextStyle(fontSize: 12)),
                                Text('Status: ${employee.employeeStatus}', style: const TextStyle(fontSize: 12)),
                                Text(
                                  'Gaji Pokok: Rp ${NumberFormat.decimalPattern('id_ID').format(employee.gajiPokok)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEdit(employee);
                              } else if (value == 'reset') {
                                onResetPassword(employee);
                              } else if (value == 'hapus') {
                                onDelete(employee);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit Karyawan')),
                              PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                              PopupMenuItem(value: 'hapus', child: Text('Hapus Data')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<AdminRole>(
                              value: employee.role,
                              decoration: const InputDecoration(
                                labelText: 'Role',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(value: AdminRole.admin, child: Text('Admin')),
                                DropdownMenuItem(value: AdminRole.user, child: Text('User')),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                onChangeRole(employee, value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final List<_ActivityLog> logs;
  final Color emptyTextColor;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _LogCard({
    required this.logs,
    required this.emptyTextColor,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Log Aktivitas Sistem',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh log',
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (logs.isEmpty && !isLoading)
              Text('Belum ada aktivitas.', style: TextStyle(color: emptyTextColor))
            else
              _PaginatedSection<_ActivityLog>(
                items: logs,
                itemBuilder: (log) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: const Color(0xFFF8FAFF),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm:ss').format(log.time),
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(log.actor, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3EAFF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                log.module,
                                style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          log.target.isEmpty ? log.action : '${log.action} — ${log.target}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (log.detail != null && log.detail!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(log.detail!, style: TextStyle(fontSize: 12, color: cs.error)),
                        ],
                        if (log.before != null && log.before!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Sebelum: ${log.before!}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        ],
                        if (log.after != null && log.after!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('Sesudah: ${log.after!}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Pagination helpers ───────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  List<int?> _buildPages() {
    if (totalPages <= 1) return [];
    if (totalPages <= 5) return List.generate(totalPages, (i) => i + 1);
    final pages = <int>{1, totalPages};
    for (var i = currentPage - 1; i <= currentPage + 1; i++) {
      if (i >= 1 && i <= totalPages) pages.add(i);
    }
    final sorted = pages.toList()..sort();
    final result = <int?>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) result.add(null);
      result.add(sorted[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          ..._buildPages().map((p) {
            if (p == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('..', style: TextStyle(fontWeight: FontWeight.w600)),
              );
            }
            final active = p == currentPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () => onPageChanged(p),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? cs.primary : null,
                    borderRadius: BorderRadius.circular(6),
                    border: active ? null : Border.all(color: cs.outlineVariant),
                  ),
                  child: Text(
                    '$p',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                      color: active ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _PaginatedSection<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T) itemBuilder;
  static const pageSize = 10;

  const _PaginatedSection({required this.items, required this.itemBuilder});

  @override
  State<_PaginatedSection<T>> createState() => _PaginatedSectionState<T>();
}

class _PaginatedSectionState<T> extends State<_PaginatedSection<T>> {
  int _page = 1;

  int _totalPages(int count) =>
      count == 0 ? 1 : ((count - 1) ~/ _PaginatedSection.pageSize + 1);

  @override
  void didUpdateWidget(_PaginatedSection<T> old) {
    super.didUpdateWidget(old);
    final max = _totalPages(widget.items.length);
    if (_page > max) setState(() => _page = max.clamp(1, 999));
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalPages(widget.items.length);
    final page = _page.clamp(1, total);
    final paged = widget.items
        .skip((page - 1) * _PaginatedSection.pageSize)
        .take(_PaginatedSection.pageSize)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...paged.map(widget.itemBuilder),
        _PaginationBar(
          currentPage: page,
          totalPages: total,
          onPageChanged: (p) => setState(() => _page = p),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
