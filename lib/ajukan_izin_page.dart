import 'package:absensi_king_royal/profile_page.dart';
import 'package:absensi_king_royal/services/services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

enum LeaveRequestType { sakit, cuti, extraOff, lembur }

extension LeaveRequestTypeX on LeaveRequestType {
  String get label {
    switch (this) {
      case LeaveRequestType.sakit:
        return 'Sakit';
      case LeaveRequestType.cuti:
        return 'Cuti';
      case LeaveRequestType.extraOff:
        return 'Extra Off';
      case LeaveRequestType.lembur:
        return 'Lembur';
    }
  }
}

class LeaveSubmissionPayload {
  final LeaveHistoryItem historyItem;
  final LeaveRequestType type;
  final bool includesToday;
  final int requestedDays;

  const LeaveSubmissionPayload({
    required this.historyItem,
    required this.type,
    required this.includesToday,
    required this.requestedDays,
  });
}

class AjukanIzinPage extends StatefulWidget {
  final List<LeaveHistoryItem> leaveHistory;
  final LeaveRequestType initialType;

  const AjukanIzinPage({
    super.key,
    required this.leaveHistory,
    this.initialType = LeaveRequestType.sakit,
  });

  @override
  State<AjukanIzinPage> createState() => _AjukanIzinPageState();
}

class _AjukanIzinPageState extends State<AjukanIzinPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _picker = ImagePicker();
  final _requestApi = AttendanceRequestApi();
  final _fileApi = FileApi();

  late LeaveRequestType _selectedType;
  DateTimeRange? _selectedRange;
  DateTime? _selectedDate;
  int _selectedOvertimeHours = 1;
  XFile? _proofFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  Future<void> _pickRangeDate() async {
    final now = DateTime.now();
    final initial =
        _selectedRange ??
        DateTimeRange(start: now, end: now.add(const Duration(days: 1)));
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
      helpText: 'Pilih Tanggal Izin',
      saveText: 'Simpan',
      cancelText: 'Batal',
    );
    if (picked == null) return;
    setState(() => _selectedRange = picked);
  }

  Future<void> _pickSingleDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDate: _selectedDate ?? now,
      helpText: 'Pilih Tanggal Lembur',
      cancelText: 'Batal',
      confirmText: 'Simpan',
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _pickProofFile() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (!mounted || file == null) return;
      setState(() => _proofFile = file);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memilih file bukti.')),
      );
    }
  }

  bool _validateDateInput() {
    if (_selectedType == LeaveRequestType.lembur) {
      return _selectedDate != null;
    }
    return _selectedRange != null;
  }

  bool get _requiresReason => true;

  String _buildTitle() {
    final reason = _reasonController.text.trim();
    if (_selectedType == LeaveRequestType.lembur) {
      if (reason.isEmpty) {
        return 'Lembur $_selectedOvertimeHours jam';
      }
      return 'Lembur $_selectedOvertimeHours jam - $reason';
    }
    if (reason.isEmpty) return _selectedType.label;
    return '${_selectedType.label} - $reason';
  }

  String _buildDateLabel() {
    if (_selectedType == LeaveRequestType.lembur) {
      return DateFormat('dd/MM/yyyy', 'id_ID').format(_selectedDate!);
    }
    final start = DateFormat(
      'dd/MM/yyyy',
      'id_ID',
    ).format(_selectedRange!.start);
    final end = DateFormat('dd/MM/yyyy', 'id_ID').format(_selectedRange!.end);
    return start == end ? start : '$start - $end';
  }

  bool _includesToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedType == LeaveRequestType.lembur) {
      if (_selectedDate == null) return false;
      final selected = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      return selected.isAtSameMomentAs(today);
    }

    if (_selectedRange == null) return false;
    final start = DateTime(
      _selectedRange!.start.year,
      _selectedRange!.start.month,
      _selectedRange!.start.day,
    );
    final end = DateTime(
      _selectedRange!.end.year,
      _selectedRange!.end.month,
      _selectedRange!.end.day,
    );
    return !today.isBefore(start) && !today.isAfter(end);
  }

  int _requestedDays() {
    if (_selectedType == LeaveRequestType.lembur || _selectedRange == null) {
      return 0;
    }
    final start = DateTime(
      _selectedRange!.start.year,
      _selectedRange!.start.month,
      _selectedRange!.start.day,
    );
    final end = DateTime(
      _selectedRange!.end.year,
      _selectedRange!.end.month,
      _selectedRange!.end.day,
    );
    return end.difference(start).inDays + 1;
  }

  String _formatDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  String _apiType() => switch (_selectedType) {
        LeaveRequestType.sakit => 'sick',
        LeaveRequestType.cuti => 'leave',
        LeaveRequestType.extraOff => 'extra_off',
        LeaveRequestType.lembur => 'overtime',
      };

  Future<void> _submit() async {
    final isValidForm = _formKey.currentState?.validate() ?? false;
    if (!isValidForm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan pengajuan wajib diisi.')),
      );
      return;
    }
    if (!_validateDateInput()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal izin harus diisi.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? evidenceFileId;
      if (_proofFile != null) {
        final uploaded = await _fileApi.upload(_proofFile!, _apiType());
        evidenceFileId = uploaded.id;
      }

      final startDate = _selectedType == LeaveRequestType.lembur
          ? _formatDate(_selectedDate!)
          : _formatDate(_selectedRange!.start);
      final endDate = _selectedType == LeaveRequestType.lembur
          ? _formatDate(_selectedDate!)
          : _formatDate(_selectedRange!.end);

      await _requestApi.create(
        type: _apiType(),
        startDate: startDate,
        endDate: endDate,
        reason: _reasonController.text.trim(),
        requestedOvertimeHours: _selectedType == LeaveRequestType.lembur
            ? _selectedOvertimeHours
            : null,
        evidenceFileId: evidenceFileId,
      );

      if (!mounted) return;

      final item = LeaveHistoryItem(
        title: _buildTitle(),
        date: _buildDateLabel(),
        status: LeaveHistoryStatus.pending,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengajuan ${_selectedType.label} berhasil dikirim.')),
      );
      Navigator.of(context).pop(
        LeaveSubmissionPayload(
          historyItem: item,
          type: _selectedType,
          includesToday: _includesToday(),
          requestedDays: _requestedDays(),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOvertime = _selectedType == LeaveRequestType.lembur;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Izin')),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Form Pengajuan',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<LeaveRequestType>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Jenis Izin',
                            border: OutlineInputBorder(),
                          ),
                          items: LeaveRequestType.values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedType = value;
                              _selectedRange = null;
                              _selectedDate = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        if (isOvertime) ...[
                          OutlinedButton.icon(
                            onPressed: _pickSingleDate,
                            icon: const Icon(Icons.date_range_rounded),
                            label: Text(
                              _selectedDate == null
                                  ? 'Pilih Tanggal Lembur'
                                  : DateFormat(
                                      'dd MMM yyyy',
                                      'id_ID',
                                    ).format(_selectedDate!),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _selectedOvertimeHours,
                            decoration: const InputDecoration(
                              labelText: 'Berapa Jam',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(
                              8,
                              (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text('${index + 1} jam'),
                              ),
                            ),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedOvertimeHours = value);
                            },
                          ),
                        ] else ...[
                          OutlinedButton.icon(
                            onPressed: _pickRangeDate,
                            icon: const Icon(Icons.calendar_month_rounded),
                            label: Text(
                              _selectedRange == null
                                  ? 'Pilih Tanggal Izin'
                                  : '${DateFormat('dd MMM yyyy', 'id_ID').format(_selectedRange!.start)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_selectedRange!.end)}',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bisa pilih 1 hari atau lebih.',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _reasonController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Alasan',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Alasan wajib diisi.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickProofFile,
                                icon: const Icon(Icons.upload_file_rounded),
                                label: Text(
                                  _proofFile == null
                                      ? 'Upload Bukti (Opsional)'
                                      : 'Bukti: ${_proofFile!.name}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contoh: surat dokter.',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: const Icon(Icons.send_rounded),
                          label: Text(
                            _isSubmitting ? 'Menyimpan...' : 'Submit',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'List Data Status',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      if (widget.leaveHistory.isEmpty)
                        Text(
                          'Belum ada data pengajuan.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
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
            ],
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
