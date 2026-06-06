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

  final _scrollController = ScrollController();
  static const double _kExpandedContent = 236.0;

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    const royalBlue = Color(0xFF0D2B52);
    const royalBlueDark = Color(0xFF071828);
    const royalGold = Color(0xFFC9A548);

    return Scaffold(
      body: Column(
        children: [
          // ── Collapsing gradient header ──────────────────────────
          AnimatedBuilder(
            animation: _scrollController,
            builder: (context, _) {
              final safeTop = MediaQuery.of(context).padding.top;
              final offset = _scrollController.hasClients
                  ? _scrollController.offset.clamp(0.0, _kExpandedContent)
                  : 0.0;
              final p = offset / _kExpandedContent;
              final contentOpacity = (1.0 - p * 2.0).clamp(0.0, 1.0);
              final collapsedOpacity = (p * 2.0 - 0.8).clamp(0.0, 1.0);
              return SizedBox(
                height: safeTop + kToolbarHeight + (1.0 - p) * _kExpandedContent,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Background gradient
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [royalBlue, royalBlueDark],
                          ),
                        ),
                      ),
                    ),

                    // Back button row + collapsed title (always visible)
                    Positioned(
                      top: safeTop,
                      left: 0,
                      right: 0,
                      height: kToolbarHeight,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          Expanded(
                            child: Opacity(
                              opacity: collapsedOpacity,
                              child: Row(
                                children: [
                                  ProfileAvatar(radius: 14, photoPath: _profilePhotoPath),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      widget.fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expanded profile content (fades out as header collapses)
                    Positioned(
                      top: safeTop + kToolbarHeight,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: contentOpacity,
                        child: Transform.translate(
                          offset: Offset(0, -p * 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ProfileAvatar(radius: 48, photoPath: _profilePhotoPath),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  widget.fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.jobTitle} · ${widget.department}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: royalGold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: royalGold.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  widget.role,
                                  style: const TextStyle(
                                    color: royalGold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Content ────────────────────────────────────────────
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                // Info pribadi
                _SectionCard(
                  title: 'Informasi Pribadi',
                  icon: Icons.person_outline_rounded,
                  children: [
                    _InfoRow(label: 'Kode Karyawan', value: widget.nik),
                    _InfoRow(
                      label: 'Tempat, Tgl Lahir',
                      value: '$_placeOfBirth, ${DateFormat('dd MMMM yyyy', 'id_ID').format(_birthDate)}',
                    ),
                    _InfoRow(label: 'Jenis Kelamin', value: genderToDisplay(_gender)),
                    _InfoRow(label: 'Alamat', value: _address),
                    _InfoRow(label: 'Nomor HP', value: _phoneNumber),
                    _InfoRow(label: 'Email', value: widget.email),
                  ],
                ),
                const SizedBox(height: 12),

                // Info kepegawaian
                _SectionCard(
                  title: 'Kepegawaian',
                  icon: Icons.work_outline_rounded,
                  children: [
                    _InfoRow(label: 'Status', value: widget.employeeStatus),
                    _InfoRow(
                      label: 'Tanggal Masuk',
                      value: DateFormat('dd MMMM yyyy', 'id_ID').format(widget.joinDate),
                    ),
                    _InfoRow(label: 'No Rekening', value: _bankAccountNumber),
                  ],
                ),
                const SizedBox(height: 12),

                // Statistik
                _SectionCard(
                  title: 'Statistik Kehadiran Bulan Ini',
                  icon: Icons.bar_chart_rounded,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: GridView.count(
                        crossAxisCount: 3,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _StatChip(label: 'Hadir', value: '${widget.totalHadir}', unit: 'hari', color: const Color(0xFF1B5E20)),
                          _StatChip(label: 'Off', value: '${widget.totalOff}', unit: 'hari', color: const Color(0xFF455A64)),
                          _StatChip(label: 'Cuti', value: '${widget.totalCuti}', unit: 'hari', color: const Color(0xFF6A1B9A)),
                          _StatChip(label: 'Extra Off', value: '${widget.totalExtraOff}', unit: 'hari', color: const Color(0xFF1565C0)),
                          _StatChip(label: 'Sakit', value: '${widget.totalSakit}', unit: 'hari', color: const Color(0xFFE65100)),
                          _StatChip(label: 'Lembur', value: '${widget.totalLembur}', unit: 'jam', color: royalBlue),
                          _StatChip(
                            label: 'Sisa Cuti',
                            value: '${widget.remainingLeave}/${widget.annualLeaveQuota}',
                            unit: 'hari',
                            color: const Color(0xFF00695C),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Riwayat izin
                if (widget.leaveHistory.isNotEmpty)
                  _SectionCard(
                    title: 'Riwayat Pengajuan Izin',
                    icon: Icons.history_rounded,
                    children: widget.leaveHistory
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        item.date,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _StatusBadge(status: item.status),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                if (widget.leaveHistory.isNotEmpty) const SizedBox(height: 12),

                // Action buttons
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ProfileNavItem(
                        icon: Icons.edit_rounded,
                        label: 'Edit Profil',
                        color: royalBlue,
                        onTap: _openEditProfilePage,
                        isFirst: true,
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileNavItem(
                        icon: Icons.lock_reset_rounded,
                        label: 'Ubah Password',
                        color: const Color(0xFF4A148C),
                        onTap: widget.onResetPassword,
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileNavItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Lihat Slip Gaji',
                        color: const Color(0xFF1B5E20),
                        onTap: _openSlipHistoryPage,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
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
    const royalBlue = Color(0xFF0D2B52);
    const royalBlueDark = Color(0xFF071828);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [royalBlue, royalBlueDark],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                    const Expanded(
                      child: Text(
                        'Slip Gaji',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.receipt_long_rounded, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Builder(builder: (_) {
              if (_error != null) {
                return Center(child: Text(_error!, style: TextStyle(color: cs.error)));
              }
              if (_slips == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_slips!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Belum ada slip gaji.', style: TextStyle(color: Colors.grey.shade400)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _slips!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final slip = _slips![i];
                  final net = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(slip.netSalary);
                  final sentStr = slip.sentAt != null
                      ? DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(slip.sentAt!))
                      : null;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF0FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_rounded, color: royalBlue, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('MMMM yyyy', 'id_ID').format(DateTime(slip.year, slip.month)),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              if (sentStr != null) ...[
                                const SizedBox(height: 2),
                                Text('Terkirim $sentStr', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          net,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: royalBlue),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── New helper widgets ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 17, color: const Color(0xFF0D2B52)),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF0D2B52),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 4,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _ProfileNavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(18) : Radius.zero,
          bottom: isLast ? const Radius.circular(18) : Radius.zero,
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
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
