import 'dart:io';

import 'package:absensi_king_royal/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AttendanceCaptureResult {
  final DateTime capturedAt;

  const AttendanceCaptureResult({required this.capturedAt});
}

class AttendanceCapturePage extends StatefulWidget {
  final String pageTitle;
  final String attendanceLabel;
  final String confirmButtonLabel;
  final String employeeName;
  final String employeeNik;
  final String attendanceType; // 'check_in' atau 'check_out'

  const AttendanceCapturePage({
    super.key,
    required this.pageTitle,
    required this.attendanceLabel,
    required this.confirmButtonLabel,
    required this.employeeName,
    required this.employeeNik,
    required this.attendanceType,
  });

  @override
  State<AttendanceCapturePage> createState() => _AttendanceCapturePageState();
}

class _AttendanceCapturePageState extends State<AttendanceCapturePage> {
  final _fileApi = FileApi();
  final _attendanceApi = AttendanceApi();
  final ImagePicker _picker = ImagePicker();

  XFile? _xFile;
  Uint8List? _imageBytes;
  DateTime? _capturedAt;
  String? _cameraMessage;
  bool _isOpeningCamera = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openCamera());
  }

  Future<void> _openCamera() async {
    if (_isOpeningCamera) return;
    setState(() {
      _isOpeningCamera = true;
      _cameraMessage = null;
    });

    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70,
      );

      if (!mounted) return;
      if (file == null) {
        setState(() {
          _cameraMessage = 'Pengambilan foto dibatalkan.';
          _isOpeningCamera = false;
        });
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _xFile = file;
        _imageBytes = bytes;
        _capturedAt = DateTime.now();
        _isOpeningCamera = false;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _cameraMessage = 'Kamera belum tersedia di device ini.';
        _isOpeningCamera = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        final code = e.code.toLowerCase();
        _cameraMessage = code.contains('denied')
            ? 'Izin kamera ditolak. Aktifkan izin kamera di pengaturan aplikasi.'
            : 'Gagal membuka kamera (${e.code}).';
        _isOpeningCamera = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraMessage = 'Gagal membuka kamera.';
        _isOpeningCamera = false;
      });
    }
  }

  Future<void> _useMockPhoto() async {
    const mockPng = <int>[
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
      0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0,
      0, 11, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13,
      10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
    ];
    final bytes = Uint8List.fromList(mockPng);
    final tempFile = File('${Directory.systemTemp.path}/mock_absen_${widget.attendanceType}.png');
    await tempFile.writeAsBytes(bytes);
    if (!mounted) return;
    setState(() {
      _xFile = XFile(tempFile.path);
      _imageBytes = bytes;
      _capturedAt = DateTime.now();
      _cameraMessage = 'Menggunakan foto simulasi.';
    });
  }

  Future<void> _submit() async {
    if (_xFile == null || _capturedAt == null) return;
    setState(() => _isSubmitting = true);

    try {
      final fileModel = await _fileApi.upload(_xFile!, widget.attendanceType);
      final AttendanceModel attendance;
      if (widget.attendanceType == 'check_in') {
        attendance = await _attendanceApi.checkIn(fileModel.id);
      } else {
        attendance = await _attendanceApi.checkOut(fileModel.id);
      }
      if (!mounted) return;
      final timeStr = widget.attendanceType == 'check_in'
          ? attendance.checkInAt
          : attendance.checkOutAt;
      final capturedAt = timeStr != null
          ? (DateTime.tryParse(timeStr)?.toLocal()) ?? _capturedAt!
          : _capturedAt!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.attendanceType == 'check_in'
              ? 'Absen masuk berhasil dicatat.'
              : 'Absen pulang berhasil dicatat.'),
        ),
      );
      Navigator.of(context).pop(AttendanceCaptureResult(capturedAt: capturedAt));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim absensi. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewTime = _capturedAt ?? DateTime.now();
    final dateLabel = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(previewTime);
    final timeLabel = DateFormat('HH:mm:ss', 'id_ID').format(previewTime);

    const royalBlue = Color(0xFF0D2B52);
    const royalBlueDark = Color(0xFF071828);
    const royalGold = Color(0xFFC9A548);
    final isCheckIn = widget.attendanceType == 'check_in';
    final accentColor = isCheckIn ? royalBlue : const Color(0xFF1B5E20);

    return Scaffold(
      body: Column(
        children: [
          // ── Gradient header ──────────────────────────────────────────
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
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
                          child: Text(
                            widget.pageTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isCheckIn
                                ? royalGold.withValues(alpha: 0.2)
                                : const Color(0xFF4CAF50).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCheckIn
                                  ? royalGold.withValues(alpha: 0.5)
                                  : const Color(0xFF4CAF50).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
                                size: 13,
                                color: isCheckIn ? royalGold : const Color(0xFF81C784),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isCheckIn ? 'Masuk' : 'Pulang',
                                style: TextStyle(
                                  color: isCheckIn ? royalGold : const Color(0xFF81C784),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Colors.white60),
                        const SizedBox(width: 6),
                        Text(
                          '$timeLabel WIB',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          dateLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.04,
                    child: Center(
                      child: Image.asset(
                        'assets/icons/app_icon.jpg',
                        width: 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: _imageBytes == null
                                ? Container(
                                    width: double.infinity,
                                    height: 240,
                                    color: const Color(0xFFECEFF5),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: royalBlue.withValues(alpha: 0.08),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_outlined,
                                            color: royalBlue,
                                            size: 30,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _isOpeningCamera
                                              ? 'Membuka kamera...'
                                              : (_cameraMessage ?? 'Kamera belum dibuka'),
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 13,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : Image.memory(
                                    _imageBytes!,
                                    width: double.infinity,
                                    height: 240,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_imageBytes != null && _cameraMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.info_outline_rounded, size: 14, color: Colors.amber.shade700),
                                        const SizedBox(width: 6),
                                        Text(
                                          _cameraMessage!,
                                          style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _isSubmitting ? null : _openCamera,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: royalBlue,
                                          side: BorderSide(color: royalBlue.withValues(alpha: 0.35)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        icon: const Icon(Icons.camera_alt_rounded, size: 16),
                                        label: const Text('Ambil Ulang', style: TextStyle(fontSize: 13)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _isSubmitting ? null : _useMockPhoto,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.grey.shade600,
                                          side: BorderSide(color: Colors.grey.shade300),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        icon: const Icon(Icons.image_outlined, size: 16),
                                        label: const Text('Simulasi', style: TextStyle(fontSize: 13)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 14),
                                _buildInfoRow('Keterangan', widget.attendanceLabel, valueColor: accentColor),
                                _buildInfoRow('Nama', widget.employeeName),
                                _buildInfoRow('Kode Karyawan', widget.employeeNik),
                                _buildInfoRow('Hari / Tanggal', dateLabel),
                                _buildInfoRow(
                                  widget.pageTitle.contains('Masuk') ? 'Jam Masuk' : 'Jam Pulang',
                                  '$timeLabel WIB',
                                  valueColor: accentColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: (_xFile == null || _capturedAt == null || _isSubmitting)
                            ? null
                            : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          disabledBackgroundColor: accentColor.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Icon(Icons.verified_rounded, size: 20),
                        label: Text(
                          _isSubmitting ? 'Mengirim...' : widget.confirmButtonLabel,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
