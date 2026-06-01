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
          ? DateTime.tryParse(timeStr) ?? _capturedAt!
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.pageTitle)),
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
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.attendanceLabel,
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            height: 220,
                            color: const Color(0xFFECEFF5),
                            alignment: Alignment.center,
                            child: _imageBytes == null
                                ? const Text('Kamera otomatis sedang dibuka...')
                                : Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_cameraMessage != null)
                          Text(
                            _cameraMessage!,
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : _openCamera,
                              icon: const Icon(Icons.camera_alt_rounded),
                              label: const Text('Ambil Ulang Foto'),
                            ),
                            OutlinedButton(
                              onPressed: _isSubmitting ? null : _useMockPhoto,
                              child: const Text('Gunakan Foto Simulasi'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Keterangan', value: widget.attendanceLabel),
                        _InfoRow(label: 'Nama', value: widget.employeeName),
                        _InfoRow(label: 'kode karyawan', value: widget.employeeNik),
                        _InfoRow(label: 'Hari / Tanggal', value: dateLabel),
                        _InfoRow(
                          label: widget.pageTitle.contains('Masuk')
                              ? 'Jam Masuk'
                              : 'Jam Pulang',
                          value: '$timeLabel WIB',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: (_xFile == null || _capturedAt == null || _isSubmitting)
                      ? null
                      : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.verified_rounded),
                  label: Text(_isSubmitting ? 'Mengirim...' : widget.confirmButtonLabel),
                ),
              ],
            ),
          ],
        ),
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
