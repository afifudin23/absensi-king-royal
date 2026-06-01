import 'dart:io';

import 'package:absensi_king_royal/edit_profile_page.dart';
import 'package:absensi_king_royal/utils/image_utils.dart';
import 'package:absensi_king_royal/services/services.dart';
import 'package:absensi_king_royal/utils/enum_mapper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

enum LeaveHistoryStatus { approved, pending, rejected }

extension LeaveHistoryStatusX on LeaveHistoryStatus {
  String get label {
    switch (this) {
      case LeaveHistoryStatus.approved:
        return 'Approve';
      case LeaveHistoryStatus.pending:
        return 'Pending';
      case LeaveHistoryStatus.rejected:
        return 'Tolak';
    }
  }
}

class LeaveHistoryItem {
  final String title;
  final String date;
  final LeaveHistoryStatus status;

  const LeaveHistoryItem({
    required this.title,
    required this.date,
    required this.status,
  });
}

class EmployeeProfilePage extends StatefulWidget {
  final String fullName;
  final String nik;
  final String placeOfBirth;
  final DateTime birthDate;
  final String gender;
  final String address;
  final String phoneNumber;
  final String email;
  final String jobTitle;
  final String role;
  final String department;
  final String employeeStatus;
  final DateTime joinDate;
  final String bankAccountNumber;
  final String? profilePhotoPath;
  final String? profilePhotoId;
  final ValueChanged<String?> onProfilePhotoChanged;
  final int totalHadir;
  final int totalOff;
  final int totalCuti;
  final int totalExtraOff;
  final int totalSakit;
  final int totalLembur;
  final int annualLeaveQuota;
  final int remainingLeave;
  final List<LeaveHistoryItem> leaveHistory;
  final VoidCallback onResetPassword;
  final Future<void> Function() onLogout;

  const EmployeeProfilePage({
    super.key,
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
    required this.profilePhotoPath,
    this.profilePhotoId,
    required this.onProfilePhotoChanged,
    required this.totalHadir,
    required this.totalOff,
    required this.totalCuti,
    required this.totalExtraOff,
    required this.totalSakit,
    required this.totalLembur,
    required this.annualLeaveQuota,
    required this.remainingLeave,
    required this.leaveHistory,
    required this.onResetPassword,
    required this.onLogout,
  });

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  final _userApi = UserApi();
  final _fileApi = FileApi();

  String? _profilePhotoPath;
  String? _profilePhotoId;
  bool _isPickingPhoto = false;

  // Field yang bisa diedit user
  late String _placeOfBirth;
  late DateTime _birthDate;
  late String _gender;
  late String _address;
  late String _phoneNumber;
  late String _bankAccountNumber;

  @override
  void initState() {
    super.initState();
    _profilePhotoPath = widget.profilePhotoPath;
    _profilePhotoId = widget.profilePhotoId;
    _placeOfBirth = widget.placeOfBirth;
    _birthDate = widget.birthDate;
    _gender = widget.gender;
    _address = widget.address;
    _phoneNumber = widget.phoneNumber;
    _bankAccountNumber = widget.bankAccountNumber;
  }

  Future<void> _pickProfilePhoto() async {
    setState(() => _isPickingPhoto = true);
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (!mounted) return;
    if (result == null) {
      setState(() => _isPickingPhoto = false);
      return;
    }
    try {
      if (_profilePhotoId != null) {
        await _fileApi.delete(_profilePhotoId!);
      }
      final fileModel = await _fileApi.upload(result, 'profile_picture');
      await _userApi.updateMyProfilePhoto(fileModel.id);
      if (!mounted) return;
      setState(() {
        _profilePhotoPath = fileModel.fileUrl;
        _profilePhotoId = fileModel.id;
        _isPickingPhoto = false;
      });
      widget.onProfilePhotoChanged(fileModel.fileUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diubah.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPickingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengunggah foto profil.')),
      );
    }
  }

  Future<void> _removeProfilePhoto() async {
    try {
      if (_profilePhotoId != null) {
        await _fileApi.delete(_profilePhotoId!);
      }
      await _userApi.updateMyProfilePhoto(null);
      if (!mounted) return;
      setState(() {
        _profilePhotoPath = null;
        _profilePhotoId = null;
      });
      widget.onProfilePhotoChanged(null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil dihapus.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus foto profil.')),
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

  Future<void> _openEditProfilePage() async {
    final result = await Navigator.of(context).push<EditProfileResult>(
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          fullName: widget.fullName,
          placeOfBirth: _placeOfBirth,
          birthDate: _birthDate,
          gender: _gender,
          profilePhotoPath: _profilePhotoPath,
          profilePhotoId: _profilePhotoId,
          address: _address,
          phoneNumber: _phoneNumber,
          bankAccountNumber: _bankAccountNumber,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _placeOfBirth = result.placeOfBirth;
      _birthDate = result.birthDate;
      _gender = result.gender;
      _address = result.address;
      _phoneNumber = result.phoneNumber;
      _bankAccountNumber = result.bankAccountNumber;
      if (result.profilePhotoPath != _profilePhotoPath) {
        evictImageCache(_profilePhotoPath);
      }
      _profilePhotoPath = result.profilePhotoPath;
    });
    if (result.profilePhotoPath != widget.profilePhotoPath) {
      widget.onProfilePhotoChanged(result.profilePhotoPath);
    }
  }

  void _openSlipHistoryPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SlipHistoryPage(employeeName: widget.fullName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ImageProvider<Object> profileImage = _resolveProfileImage(_profilePhotoPath);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Karyawan')),
      body: Stack(
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
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ProfileAvatar(radius: 44, photoPath: _profilePhotoPath),
                      const SizedBox(height: 12),
                      Text(
                        widget.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      _InfoText(label: 'Nama Lengkap', value: widget.fullName),
                      _InfoText(label: 'kode karyawan', value: widget.nik),
                      _InfoText(
                        label: 'Tempat, Tanggal Lahir',
                        value:
                            '$_placeOfBirth, ${DateFormat('dd MMMM yyyy', 'id_ID').format(_birthDate)}',
                      ),
                      _InfoText(label: 'Jenis Kelamin', value: genderToDisplay(_gender)),
                      _InfoText(label: 'Alamat', value: _address),
                      _InfoText(label: 'Nomor HP', value: _phoneNumber),
                      _InfoText(label: 'Email', value: widget.email),
                      _InfoText(label: 'Jabatan', value: widget.jobTitle),
                      _InfoText(label: 'Role', value: widget.role),
                      _InfoText(label: 'Departemen', value: widget.department),
                      _InfoText(
                        label: 'Status Karyawan',
                        value: widget.employeeStatus,
                      ),
                      _InfoText(
                        label: 'Tanggal Masuk',
                        value: DateFormat(
                          'dd MMMM yyyy',
                          'id_ID',
                        ).format(widget.joinDate),
                      ),
                      _InfoText(
                        label: 'No Rekening',
                        value: _bankAccountNumber,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistik Kehadiran',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _StatChip(
                            label: 'Total Hadir',
                            value: '${widget.totalHadir} hari',
                          ),
                          _StatChip(
                            label: 'Total Off',
                            value: '${widget.totalOff} hari',
                          ),
                          _StatChip(
                            label: 'Total Cuti',
                            value: '${widget.totalCuti} hari',
                          ),
                          _StatChip(
                            label: 'Total Extra Off',
                            value: '${widget.totalExtraOff} hari',
                          ),
                          _StatChip(
                            label: 'Total Sakit',
                            value: '${widget.totalSakit} hari',
                          ),
                          _StatChip(
                            label: 'Total Lembur',
                            value: '${widget.totalLembur} jam',
                          ),
                          _StatChip(
                            label: 'Sisa Cuti',
                            value:
                                '${widget.remainingLeave} dari ${widget.annualLeaveQuota} hari',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Riwayat Pengajuan Izin',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      ...widget.leaveHistory.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('${item.title} (${item.date})'),
                              ),
                              _StatusBadge(status: item.status),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _openEditProfilePage,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Profil'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: widget.onResetPassword,
                icon: const Icon(Icons.lock_reset_rounded),
                label: const Text('Reset Password'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _openSlipHistoryPage,
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('Lihat Slip Gaji'),
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: cs.error,
                ),
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log Out'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlipHistoryPage extends StatefulWidget {
  final String employeeName;

  const _SlipHistoryPage({required this.employeeName});

  @override
  State<_SlipHistoryPage> createState() => _SlipHistoryPageState();
}

class _SlipHistoryPageState extends State<_SlipHistoryPage> {
  final _payrollApi = PayrollApi();
  List<PayrollModel>? _slips;
  String? _error;
  final Set<String> _sendingIds = {};

  @override
  void initState() {
    super.initState();
    _loadSlips();
  }

  Future<void> _loadSlips() async {
    try {
      final data = await _payrollApi.getMyPayrolls();
      if (!mounted) return;
      setState(() => _slips = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat slip gaji.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Slip Gaji Terkirim')),
      body: Builder(builder: (_) {
        if (_error != null) {
          return Center(child: Text(_error!, style: TextStyle(color: cs.error)));
        }
        if (_slips == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.employeeName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ..._slips!.map(
              (slip) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    DateFormat('MMMM yyyy', 'id_ID')
                        .format(DateTime(slip.year, slip.month)),
                  ),
                  subtitle: Text(
                    'Terkirim ${slip.sentAt != null ? DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(DateTime.parse(slip.sentAt!)) : '-'} | Total ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(slip.netSalary)}',
                  ),
                ),
              ),
            ),
            if (_slips!.isEmpty)
              Text(
                'Belum ada slip gaji yang dikirim.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
          ],
        );
      }),
    );
  }
}

class _InfoText extends StatelessWidget {
  final String label;
  final String value;

  const _InfoText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLongValue = value.length > 24;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              overflow: TextOverflow.visible,
              maxLines: 4,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isLongValue ? 13 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 52) / 2;
    return Container(
      width: width.clamp(140, 260),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
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

class _StatusBadge extends StatelessWidget {
  final LeaveHistoryStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = switch (status) {
      LeaveHistoryStatus.approved => (const Color(0xFF2E7D32), Colors.white),
      LeaveHistoryStatus.pending => (
        const Color(0xFFFBC02D),
        const Color(0xFF3A2A00),
      ),
      LeaveHistoryStatus.rejected => (const Color(0xFFC62828), Colors.white),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
