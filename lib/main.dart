import 'dart:async';
import 'dart:io';

import 'package:absensi_king_royal/absen_masuk_page.dart';
import 'package:absensi_king_royal/absen_pulang_page.dart';
import 'package:absensi_king_royal/ajukan_izin_page.dart';
import 'package:absensi_king_royal/attendance_capture_page.dart';
import 'package:absensi_king_royal/admin_dashboard_section.dart';
import 'package:absensi_king_royal/auth_service.dart';
import 'package:absensi_king_royal/login_page.dart';
import 'package:absensi_king_royal/payroll_models.dart';
import 'package:absensi_king_royal/riwayat_page.dart';
import 'package:absensi_king_royal/reset_password_page.dart';
import 'package:absensi_king_royal/services/services.dart';
import 'package:absensi_king_royal/profile_page.dart';
import 'package:absensi_king_royal/utils/enum_mapper.dart';
import 'package:absensi_king_royal/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('id_ID');
  ApiClient.instance.init();
  runApp(const AbsensiKingRoyalApp());
}

class AbsensiKingRoyalApp extends StatefulWidget {
  const AbsensiKingRoyalApp({super.key});

  @override
  State<AbsensiKingRoyalApp> createState() => _AbsensiKingRoyalAppState();
}

class _AbsensiKingRoyalAppState extends State<AbsensiKingRoyalApp> {
  final AuthService _authService = AuthService();
  AppUser? _loggedInUser;
  bool _rememberMe = false;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final user = await _authService.restoreSession();
    if (!mounted) return;
    setState(() {
      _loggedInUser = user;
      _checkingSession = false;
    });
  }

  void _handleLoginSuccess(AppUser user, bool rememberMe) {
    setState(() {
      _loggedInUser = user;
      _rememberMe = rememberMe;
    });
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    setState(() {
      _loggedInUser = null;
      _rememberMe = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const royalBlue = Color(0xFF0D2B52);
    const royalGold = Color(0xFFC9A548);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Absensi King Royal',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: royalBlue,
          primary: royalBlue,
          secondary: royalGold,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FB),
      ),
      home: _checkingSession
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _loggedInUser == null
              ? LoginPage(
                  authService: _authService,
                  onLoginSuccess: _handleLoginSuccess,
                )
              : HomeScreen(
                  currentUser: _loggedInUser!,
                  authService: _authService,
                  onLogout: _handleLogout,
                ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final AppUser currentUser;
  final AuthService authService;
  final Future<void> Function() onLogout;

  const HomeScreen({
    super.key,
    required this.currentUser,
    required this.authService,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  String employeeName = '';
  String employeeNik = '';
  String employeePlaceOfBirth = '';
  DateTime employeeBirthDate = DateTime(2000);
  String employeeGender = '';
  String employeeAddress = '';
  String employeeJobTitle = '';
  String employeeRole = '';
  String employeeDepartment = '';
  String employeeStatus = '';
  DateTime employeeJoinDate = DateTime.now();
  String employeeBankAccountNumber = '';
  String employeePhone = '';
  String employeeEmail = '';
  String? employeeProfilePhotoPath;
  String? employeeProfilePhotoId;
  final _userApi = UserApi();
  final _adminRefreshTrigger = ValueNotifier<int>(0);

  int totalHadir = 0;
  int totalOff = 0;
  int totalCuti = 0;
  int totalExtraOff = 0;
  int totalSakit = 0;
  int totalLembur = 0;
  static const int annualLeaveQuota = 12;

  AttendanceSessionState attendanceState = AttendanceSessionState.notCheckedIn;
  DateTime? checkInAt;
  DateTime? checkOutAt;
  late DateTime _lastTimerDay;
  final List<LeaveHistoryItem> leaveHistory = [];
  final List<SentPayrollSlip> _sentPayrollSlips = [];

  @override
  void initState() {
    super.initState();
    employeeName = widget.currentUser.fullName;
    employeeNik = widget.currentUser.nik;
    employeePlaceOfBirth = widget.currentUser.placeOfBirth;
    employeeBirthDate = widget.currentUser.birthDate;
    employeeGender = widget.currentUser.gender;
    employeeAddress = widget.currentUser.address;
    employeeJobTitle = widget.currentUser.jobTitle;
    employeeRole = roleToDisplay(widget.currentUser.role);
    employeeDepartment = widget.currentUser.department;
    employeeStatus = employmentStatusToDisplay(widget.currentUser.employeeStatus);
    employeeJoinDate = widget.currentUser.joinDate;
    employeeBankAccountNumber = widget.currentUser.bankAccountNumber;
    employeePhone = widget.currentUser.phoneNumber;
    employeeEmail = widget.currentUser.email;
    employeeProfilePhotoPath = widget.currentUser.profilePhotoPath;
    _lastTimerDay = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      setState(() => _now = now);
      // Reset state absensi kalau hari sudah berganti
      if (now.day != _lastTimerDay.day ||
          now.month != _lastTimerDay.month ||
          now.year != _lastTimerDay.year) {
        _lastTimerDay = now;
        setState(() {
          attendanceState = AttendanceSessionState.notCheckedIn;
          checkInAt = null;
          checkOutAt = null;
        });
        _loadTodayAttendance();
        _loadMonthStats();
      }
    });
    _loadTodayAttendance();
    _loadMonthStats();
    _loadLeaveHistory();
  }

  Future<void> _loadMonthStats() async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    try {
      final logs = await AttendanceApi().getLogs(
        startDate: firstDay,
        endDate: lastDay,
      );
      if (!mounted) return;
      int hadir = 0, off = 0, cuti = 0, sakit = 0, extraOff = 0, lembur = 0;
      for (final log in logs) {
        switch (log.status) {
          case 'present':
            hadir++;
          case 'off':
            off++;
          case 'leave':
            cuti++;
          case 'sick':
            sakit++;
          case 'extra_off':
            extraOff++;
        }
        lembur += log.overtimeHours ?? 0;
      }
      setState(() {
        totalHadir = hadir;
        totalOff = off;
        totalCuti = cuti;
        totalSakit = sakit;
        totalExtraOff = extraOff;
        totalLembur = lembur;
      });
    } catch (_) {}
  }

  Future<void> _loadLeaveHistory() async {
    try {
      final requests = await AttendanceRequestApi().getMyRequests();
      if (!mounted) return;
      final items = requests.map((r) {
        final startDate = DateTime.tryParse(r.startDate) ?? DateTime.now();
        final endDate = DateTime.tryParse(r.endDate) ?? startDate;
        final dateStr = r.startDate == r.endDate
            ? DateFormat('dd/MM/yyyy').format(startDate)
            : '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}';
        final title = switch (r.type) {
          'sick' => 'Izin Sakit',
          'leave' => 'Cuti',
          'extra_off' => 'Extra Off',
          'overtime' => 'Lembur',
          _ => r.type,
        };
        final status = switch (r.status) {
          'approved' => LeaveHistoryStatus.approved,
          'rejected' => LeaveHistoryStatus.rejected,
          _ => LeaveHistoryStatus.pending,
        };
        return LeaveHistoryItem(title: title, date: dateStr, status: status);
      }).toList();
      setState(() {
        leaveHistory
          ..clear()
          ..addAll(items);
      });
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _userApi.getMyProfile();
      if (!mounted) return;
      setState(() {
        employeeName = profile.fullName;
        employeeNik = profile.employeeCode ?? '';
        employeePlaceOfBirth = profile.birthPlace ?? '';
        employeeBirthDate = profile.birthDate != null
            ? DateTime.tryParse(profile.birthDate!) ?? DateTime(2000)
            : DateTime(2000);
        employeeGender = profile.gender ?? '';
        employeeAddress = profile.address ?? '';
        employeeJobTitle = profile.position ?? '';
        employeeRole = roleToDisplay(profile.role);
        employeeDepartment = profile.department ?? '';
        employeeStatus = employmentStatusToDisplay(profile.employmentStatus);
        employeeJoinDate = profile.joinedAt != null
            ? DateTime.tryParse(profile.joinedAt!) ?? DateTime.now()
            : DateTime.now();
        employeeBankAccountNumber = profile.bankAccountNumber ?? '';
        employeePhone = profile.phoneNumber ?? '';
        employeeEmail = profile.email;
        employeeProfilePhotoPath = profile.profilePictureUrl;
        employeeProfilePhotoId = profile.profilePictureId;
      });
    } catch (_) {}
  }

  Future<void> _refresh() async {
    if (employeeRole.toLowerCase() == 'admin') {
      _adminRefreshTrigger.value++;
    }
    await Future.wait([
      _loadProfile(),
      _loadTodayAttendance(),
      _loadMonthStats(),
      _loadLeaveHistory(),
    ]);
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final attendance = await AttendanceApi().getTodayAttendance();
      if (!mounted || attendance == null) return;
      setState(() {
        if (attendance.checkInAt != null) {
          checkInAt = DateTime.tryParse(attendance.checkInAt!);
          if (attendance.checkOutAt != null) {
            checkOutAt = DateTime.tryParse(attendance.checkOutAt!);
            attendanceState = AttendanceSessionState.checkedOut;
          } else {
            attendanceState = AttendanceSessionState.checkedIn;
          }
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _adminRefreshTrigger.dispose();
    super.dispose();
  }

  Future<void> _openAbsenMasukPage() async {
    if (attendanceState != AttendanceSessionState.notCheckedIn) return;
    final result = await Navigator.of(context).push<AttendanceCaptureResult>(
      MaterialPageRoute(
        builder: (_) => AbsenMasukPage(
          employeeName: employeeName,
          employeeNik: employeeNik,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      checkInAt = result.capturedAt;
      checkOutAt = null;
      attendanceState = AttendanceSessionState.checkedIn;
    });
    _loadMonthStats();
  }

  Future<void> _openAbsenPulangPage() async {
    if (attendanceState != AttendanceSessionState.checkedIn) return;
    final result = await Navigator.of(context).push<AttendanceCaptureResult>(
      MaterialPageRoute(
        builder: (_) => AbsenPulangPage(
          employeeName: employeeName,
          employeeNik: employeeNik,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      checkOutAt = result.capturedAt;
      attendanceState = AttendanceSessionState.checkedOut;
    });
    _loadMonthStats();
  }

  Future<void> _openAjukanIzinPage({
    LeaveRequestType initialType = LeaveRequestType.sakit,
  }) async {
    final result = await Navigator.of(context).push<LeaveSubmissionPayload>(
      MaterialPageRoute(
        builder: (_) => AjukanIzinPage(
          leaveHistory: leaveHistory,
          initialType: initialType,
        ),
      ),
    );

    if (result == null || !mounted) return;
    _loadLeaveHistory();
    _loadMonthStats();
  }

  void _openProfilePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeProfilePage(
          fullName: employeeName,
          nik: employeeNik,
          placeOfBirth: employeePlaceOfBirth,
          birthDate: employeeBirthDate,
          gender: employeeGender,
          address: employeeAddress,
          phoneNumber: employeePhone,
          email: employeeEmail,
          jobTitle: employeeJobTitle,
          role: employeeRole,
          department: employeeDepartment,
          employeeStatus: employeeStatus,
          joinDate: employeeJoinDate,
          bankAccountNumber: employeeBankAccountNumber,
          profilePhotoPath: employeeProfilePhotoPath,
          profilePhotoId: employeeProfilePhotoId,
          onProfilePhotoChanged: (path) {
            setState(() => employeeProfilePhotoPath = path);
          },
          totalHadir: totalHadir,
          totalOff: totalOff,
          totalCuti: totalCuti,
          totalExtraOff: totalExtraOff,
          totalSakit: totalSakit,
          totalLembur: totalLembur,
          annualLeaveQuota: annualLeaveQuota,
          remainingLeave: (annualLeaveQuota - totalCuti).clamp(
            0,
            annualLeaveQuota,
          ),
          leaveHistory: leaveHistory,
          onResetPassword: _openResetPasswordPage,
          onLogout: () async {
            Navigator.of(context).pop();
            await widget.onLogout();
          },
        ),
      ),
    );
  }

  void _openResetPasswordPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(
          authService: widget.authService,
          user: widget.currentUser,
        ),
      ),
    );
  }

  void _openRiwayatPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RiwayatPage()));
  }

  DateTime? _parseDateLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy', 'id_ID').parseStrict(trimmed);
    } catch (_) {
      return null;
    }
  }

  bool _isLeaveInMonth(LeaveHistoryItem item, int year, int month) {
    final rangeParts = item.date.split(' - ');
    final start = _parseDateLabel(rangeParts.first);
    if (start == null) return false;
    final end = rangeParts.length > 1
        ? (_parseDateLabel(rangeParts.last) ?? start)
        : start;

    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);
    return !end.isBefore(monthStart) && !start.isAfter(monthEnd);
  }

  List<LeaveHistoryItem> get _leaveHistoryThisMonth {
    return leaveHistory
        .where((item) => _isLeaveInMonth(item, _now.year, _now.month))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final jam = DateFormat('HH:mm:ss', 'id_ID').format(_now);
    final hari = DateFormat('EEEE', 'id_ID').format(_now);
    final tanggal = DateFormat('dd MMMM yyyy', 'id_ID').format(_now);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.06,
                child: Center(
                  child: Image.asset(
                    'assets/icons/app_icon.jpg',
                    width: 320,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/icons/app_icon.jpg',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _HeaderCard(
                      employeeName: employeeName,
                      employeeNik: employeeNik,
                      employeeJobTitle: employeeJobTitle,
                      employeeRole: employeeRole,
                      employeeDepartment: employeeDepartment,
                      profilePhotoPath: employeeProfilePhotoPath,
                      onTap: _openProfilePage,
                    ),
                    const SizedBox(height: 12),
                    _InfoBulanIniCard(
                      totalHadir: totalHadir,
                      totalOff: totalOff,
                      totalCuti: totalCuti,
                      totalExtraOff: totalExtraOff,
                      totalSakit: totalSakit,
                      totalLembur: totalLembur,
                      leaveHistory: _leaveHistoryThisMonth,
                      attendanceStatus: switch (attendanceState) {
                        AttendanceSessionState.notCheckedIn => 'Belum Absen',
                        AttendanceSessionState.checkedIn => 'Sudah Absen Masuk',
                        AttendanceSessionState.checkedOut =>
                          'Sudah Absen Pulang',
                      },
                    ),
                    const SizedBox(height: 12),
                    _MainMenuCard(
                      jam: jam,
                      hari: hari,
                      tanggal: tanggal,
                      attendanceState: attendanceState,
                      checkInAt: checkInAt,
                      checkOutAt: checkOutAt,
                      onAbsenMasuk: _openAbsenMasukPage,
                      onAbsenPulang: _openAbsenPulangPage,
                      onAjukanIzin: () {
                        _openAjukanIzinPage();
                      },
                      onRiwayat: _openRiwayatPage,
                    ),
                    if (employeeRole.toLowerCase() == 'admin')
                      AdminDashboardSection(
                        currentUserName: employeeName,
                        refreshTrigger: _adminRefreshTrigger,
                        onSlipSent: (slip) {
                          setState(() {
                            _sentPayrollSlips.removeWhere(
                              (item) =>
                                  item.employeeId == slip.employeeId &&
                                  item.month == slip.month &&
                                  item.year == slip.year,
                            );
                            _sentPayrollSlips.insert(0, slip);
                          });
                        },
                      ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Copyright King Royal Hotel - v1.0',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
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

String? _resolveUrl(String? url) {
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

ImageProvider<Object> _resolveProfileImage(String? path) {
  final resolved = _resolveUrl(path);
  if (resolved == null) return const AssetImage('assets/icons/profile_empty.png');
  if (resolved.startsWith('http')) return NetworkImage(resolved);
  if (File(resolved).existsSync()) return FileImage(File(resolved));
  return const AssetImage('assets/icons/profile_empty.png');
}

class _HeaderCard extends StatelessWidget {
  final String employeeName;
  final String employeeNik;
  final String employeeJobTitle;
  final String employeeRole;
  final String employeeDepartment;
  final String? profilePhotoPath;
  final VoidCallback onTap;

  const _HeaderCard({
    required this.employeeName,
    required this.employeeNik,
    required this.employeeJobTitle,
    required this.employeeRole,
    required this.employeeDepartment,
    required this.profilePhotoPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfileAvatar(radius: 36, photoPath: profilePhotoPath),
              const SizedBox(height: 10),
              Text(
                'Selamat Datang',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                employeeName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'kode karyawan: $employeeNik',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              Text(
                employeeJobTitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              Text(
                'Role: $employeeRole',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              Text(
                employeeDepartment,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                'Ketuk untuk lihat profil',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBulanIniCard extends StatelessWidget {
  final int totalHadir;
  final int totalOff;
  final int totalCuti;
  final int totalExtraOff;
  final int totalSakit;
  final int totalLembur;
  final List<LeaveHistoryItem> leaveHistory;
  final String attendanceStatus;

  const _InfoBulanIniCard({
    required this.totalHadir,
    required this.totalOff,
    required this.totalCuti,
    required this.totalExtraOff,
    required this.totalSakit,
    required this.totalLembur,
    required this.leaveHistory,
    required this.attendanceStatus,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final infoItems = [
      _InfoLine(label: 'Total Hadir', value: '$totalHadir hari'),
      _InfoLine(label: 'Total Off', value: '$totalOff hari'),
      _InfoLine(label: 'Total Cuti', value: '$totalCuti hari'),
      _InfoLine(label: 'Total Extra Off', value: '$totalExtraOff hari'),
      _InfoLine(label: 'Total Sakit', value: '$totalSakit hari'),
      _InfoLine(label: 'Total Lembur', value: '$totalLembur jam'),
      _InfoLine(label: 'Status Absen Hari Ini', value: attendanceStatus),
    ];

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Info Bulan Ini',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...infoItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: item.label.contains('Status')
                            ? cs.primary
                            : cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Status Pengajuan Izin',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (leaveHistory.isEmpty)
              const _LeaveStatusBadge(status: LeaveSubmissionStatus.none)
            else
              ...leaveHistory.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ),
                          _LeaveStatusBadge(
                            status: switch (item.status) {
                              LeaveHistoryStatus.approved =>
                                LeaveSubmissionStatus.approved,
                              LeaveHistoryStatus.pending =>
                                LeaveSubmissionStatus.pending,
                              LeaveHistoryStatus.rejected =>
                                LeaveSubmissionStatus.rejected,
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tanggal: ${item.date}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum AttendanceSessionState { notCheckedIn, checkedIn, checkedOut }

enum LeaveSubmissionStatus { approved, pending, rejected, none }

extension LeaveSubmissionStatusX on LeaveSubmissionStatus {
  String get label {
    switch (this) {
      case LeaveSubmissionStatus.approved:
        return 'Approve';
      case LeaveSubmissionStatus.pending:
        return 'Pending';
      case LeaveSubmissionStatus.rejected:
        return 'Tolak';
      case LeaveSubmissionStatus.none:
        return 'Tidak Ada';
    }
  }
}

class _LeaveStatusBadge extends StatelessWidget {
  final LeaveSubmissionStatus status;

  const _LeaveStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = switch (status) {
      LeaveSubmissionStatus.approved => (const Color(0xFF2E7D32), Colors.white),
      LeaveSubmissionStatus.pending => (
        const Color(0xFFFBC02D),
        const Color(0xFF3A2A00),
      ),
      LeaveSubmissionStatus.rejected => (const Color(0xFFC62828), Colors.white),
      LeaveSubmissionStatus.none => (const Color(0xFF9E9E9E), Colors.white),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoLine {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});
}

class _MainMenuCard extends StatelessWidget {
  final String jam;
  final String hari;
  final String tanggal;
  final AttendanceSessionState attendanceState;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final VoidCallback onAbsenMasuk;
  final VoidCallback onAbsenPulang;
  final VoidCallback onAjukanIzin;
  final VoidCallback onRiwayat;

  const _MainMenuCard({
    required this.jam,
    required this.hari,
    required this.tanggal,
    required this.attendanceState,
    required this.checkInAt,
    required this.checkOutAt,
    required this.onAbsenMasuk,
    required this.onAbsenPulang,
    required this.onAjukanIzin,
    required this.onRiwayat,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final menus = [
      _MainMenuItem(
        title: 'Absen Masuk',
        icon: Icons.login_rounded,
        color: cs.primary,
        isEnabled: attendanceState == AttendanceSessionState.notCheckedIn,
        onTap: onAbsenMasuk,
      ),
      _MainMenuItem(
        title: 'Absen Pulang',
        icon: Icons.logout_rounded,
        color: cs.secondary,
        isEnabled: attendanceState == AttendanceSessionState.checkedIn,
        onTap: onAbsenPulang,
      ),
      _MainMenuItem(
        title: 'Ajukan Izin',
        icon: Icons.note_add_rounded,
        color: const Color(0xFF2A8F64),
        onTap: onAjukanIzin,
      ),
      _MainMenuItem(
        title: 'Riwayat',
        icon: Icons.history_rounded,
        color: const Color(0xFF8949B3),
        onTap: onRiwayat,
      ),
    ];

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Menu Utama',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              jam,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(hari, style: TextStyle(color: cs.onSurfaceVariant)),
            Text(tanggal, style: TextStyle(color: cs.onSurfaceVariant)),
            if (checkInAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Absen masuk pada ${DateFormat('HH:mm:ss', 'id_ID').format(checkInAt!)} WIB',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (checkOutAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Absen pulang pada ${DateFormat('HH:mm:ss', 'id_ID').format(checkOutAt!)} WIB',
                style: TextStyle(
                  color: cs.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.45,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: menus.map((item) => _MenuTile(item: item)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainMenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final bool isEnabled;
  final VoidCallback onTap;

  const _MainMenuItem({
    required this.title,
    required this.icon,
    required this.color,
    this.isEnabled = true,
    required this.onTap,
  });
}

class _MenuTile extends StatelessWidget {
  final _MainMenuItem item;

  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final tileColor = item.isEnabled
        ? item.color.withValues(alpha: 0.14)
        : const Color(0xFFE0E0E0);
    final iconColor = item.isEnabled ? item.color : const Color(0xFF9E9E9E);
    final textColor = item.isEnabled ? Colors.black87 : const Color(0xFF9E9E9E);

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.isEnabled ? item.onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: iconColor),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
