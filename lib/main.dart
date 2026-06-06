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
          ? Scaffold(
              backgroundColor: const Color(0xFF0D2B52),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset('assets/icons/app_icon.jpg', width: 72, height: 72, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFC9A548)),
                    ),
                  ],
                ),
              ),
            )
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
          checkInAt = DateTime.tryParse(attendance.checkInAt!)?.toLocal();
          if (attendance.checkOutAt != null) {
            checkOutAt = DateTime.tryParse(attendance.checkOutAt!)?.toLocal();
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

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Aplikasi'),
        content: const Text('Apakah kamu yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await widget.onLogout();
    }
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
        .where((item) => _isLeaveInMonth(item, DateTime.now().year, DateTime.now().month))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 52,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Keluar',
              child: GestureDetector(
                onTap: _confirmLogout,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Icon(Icons.logout_rounded, size: 18, color: Colors.red.shade600),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
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
                    AttendanceSessionState.checkedOut => 'Sudah Absen Pulang',
                  },
                ),
                const SizedBox(height: 12),
                _MainMenuCard(
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
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'King Royal Hotel © 2025 · v1.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    const royalBlue = Color(0xFF0D2B52);
    const royalBlueDark = Color(0xFF071828);
    const royalGold = Color(0xFFC9A548);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [royalBlue, royalBlueDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: royalBlue.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                ProfileAvatar(radius: 38, photoPath: profilePhotoPath),
                const SizedBox(height: 10),
                Text(
                  'Selamat Datang,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  employeeName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$employeeJobTitle · $employeeDepartment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: royalGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: royalGold.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    employeeRole,
                    style: const TextStyle(
                      color: royalGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_rounded, size: 12, color: Colors.white.withValues(alpha: 0.65)),
                      const SizedBox(width: 5),
                      Text(
                        'Lihat Profil Lengkap',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 14, color: Colors.white.withValues(alpha: 0.65)),
                    ],
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
    const royalBlue = Color(0xFF0D2B52);
    final statItems = [
      _StatItem(Icons.check_circle_rounded, 'Hadir', '$totalHadir hari', const Color(0xFF1B5E20)),
      _StatItem(Icons.beach_access_rounded, 'Off', '$totalOff hari', const Color(0xFF455A64)),
      _StatItem(Icons.luggage_rounded, 'Cuti', '$totalCuti hari', const Color(0xFF6A1B9A)),
      _StatItem(Icons.event_available_rounded, 'Extra Off', '$totalExtraOff hari', const Color(0xFF1565C0)),
      _StatItem(Icons.local_hospital_rounded, 'Sakit', '$totalSakit hari', const Color(0xFFE65100)),
      _StatItem(Icons.more_time_rounded, 'Lembur', '$totalLembur jam', royalBlue),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_month_rounded, size: 17, color: royalBlue),
              ),
              const SizedBox(width: 10),
              const Text(
                'Info Bulan Ini',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: royalBlue),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Status absen chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: attendanceStatus.contains('Pulang')
                  ? const Color(0xFFE8F5E9)
                  : attendanceStatus.contains('Masuk')
                      ? const Color(0xFFE3F2FD)
                      : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  attendanceStatus.contains('Pulang')
                      ? Icons.check_circle_rounded
                      : attendanceStatus.contains('Masuk')
                          ? Icons.login_rounded
                          : Icons.access_time_rounded,
                  size: 15,
                  color: attendanceStatus.contains('Pulang')
                      ? const Color(0xFF1B5E20)
                      : attendanceStatus.contains('Masuk')
                          ? const Color(0xFF0D47A1)
                          : const Color(0xFFF57F17),
                ),
                const SizedBox(width: 6),
                Text(
                  attendanceStatus,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: attendanceStatus.contains('Pulang')
                        ? const Color(0xFF1B5E20)
                        : attendanceStatus.contains('Masuk')
                            ? const Color(0xFF0D47A1)
                            : const Color(0xFFF57F17),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Grid statistik
          GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 1.3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: statItems.map((s) => _MiniStatTile(item: s)).toList(),
          ),
          if (leaveHistory.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.assignment_rounded, size: 15, color: royalBlue),
                const SizedBox(width: 6),
                Text('Pengajuan Izin', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade700)),
              ],
            ),
            const SizedBox(height: 8),
            ...leaveHistory.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(item.date, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    _LeaveStatusBadge(
                      status: switch (item.status) {
                        LeaveHistoryStatus.approved => LeaveSubmissionStatus.approved,
                        LeaveHistoryStatus.pending => LeaveSubmissionStatus.pending,
                        LeaveHistoryStatus.rejected => LeaveSubmissionStatus.rejected,
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatItem(this.icon, this.label, this.value, this.color);
}

class _MiniStatTile extends StatelessWidget {
  final _StatItem item;
  const _MiniStatTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 14, color: item.color),
          const SizedBox(height: 4),
          Text(item.value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: item.color)),
          Text(item.label, style: TextStyle(fontSize: 10, color: item.color.withValues(alpha: 0.7))),
        ],
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

class _MainMenuCard extends StatefulWidget {
  final AttendanceSessionState attendanceState;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final VoidCallback onAbsenMasuk;
  final VoidCallback onAbsenPulang;
  final VoidCallback onAjukanIzin;
  final VoidCallback onRiwayat;

  const _MainMenuCard({
    required this.attendanceState,
    required this.checkInAt,
    required this.checkOutAt,
    required this.onAbsenMasuk,
    required this.onAbsenPulang,
    required this.onAjukanIzin,
    required this.onRiwayat,
  });

  @override
  State<_MainMenuCard> createState() => _MainMenuCardState();
}

class _MainMenuCardState extends State<_MainMenuCard> {
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jam = DateFormat('HH:mm:ss', 'id_ID').format(_now);
    final hari = DateFormat('EEEE', 'id_ID').format(_now);
    final tanggal = DateFormat('dd MMMM yyyy', 'id_ID').format(_now);
    final cs = Theme.of(context).colorScheme;
    final menus = [
      _MainMenuItem(
        title: 'Absen Masuk',
        icon: Icons.login_rounded,
        color: cs.primary,
        isEnabled: widget.attendanceState == AttendanceSessionState.notCheckedIn,
        onTap: widget.onAbsenMasuk,
      ),
      _MainMenuItem(
        title: 'Absen Pulang',
        icon: Icons.logout_rounded,
        color: cs.secondary,
        isEnabled: widget.attendanceState == AttendanceSessionState.checkedIn,
        onTap: widget.onAbsenPulang,
      ),
      _MainMenuItem(
        title: 'Ajukan Izin',
        icon: Icons.note_add_rounded,
        color: const Color(0xFF2A8F64),
        onTap: widget.onAjukanIzin,
      ),
      _MainMenuItem(
        title: 'Riwayat',
        icon: Icons.history_rounded,
        color: const Color(0xFF8949B3),
        onTap: widget.onRiwayat,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.grid_view_rounded, size: 17, color: Color(0xFF0D2B52)),
              ),
              const SizedBox(width: 10),
              const Text(
                'Menu Utama',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF0D2B52),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    jam,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D2B52),
                    ),
                  ),
                  Text(
                    '$hari, $tanggal',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          if (widget.checkInAt != null || widget.checkOutAt != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.checkInAt != null)
                    Row(children: [
                      const Icon(Icons.login_rounded, size: 14, color: Color(0xFF0D2B52)),
                      const SizedBox(width: 6),
                      Text(
                        'Masuk: ${DateFormat('HH:mm:ss', 'id_ID').format(widget.checkInAt!)} WIB',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D2B52)),
                      ),
                    ]),
                  if (widget.checkInAt != null && widget.checkOutAt != null) const SizedBox(height: 4),
                  if (widget.checkOutAt != null)
                    Row(children: [
                      const Icon(Icons.logout_rounded, size: 14, color: Color(0xFF2A8F64)),
                      const SizedBox(width: 6),
                      Text(
                        'Pulang: ${DateFormat('HH:mm:ss', 'id_ID').format(widget.checkOutAt!)} WIB',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2A8F64)),
                      ),
                    ]),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: menus.map((item) => _MenuTile(item: item)).toList(),
          ),
        ],
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
    final isEnabled = item.isEnabled;
    final bgColor = isEnabled
        ? item.color.withValues(alpha: 0.1)
        : const Color(0xFFF0F0F0);
    final iconBg = isEnabled
        ? item.color.withValues(alpha: 0.18)
        : const Color(0xFFE0E0E0);
    final iconColor = isEnabled ? item.color : const Color(0xFFBDBDBD);
    final textColor = isEnabled ? const Color(0xFF1A1A2E) : const Color(0xFFBDBDBD);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isEnabled ? item.onTap : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
