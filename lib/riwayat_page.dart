import 'package:absensi_king_royal/services/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum AttendanceDayStatus { hadir, off, extraOff, cuti, sakit, alfa }

enum HistoryFilterType { bulanIni, bulanLalu, customTanggal }

class AttendanceHistoryItem {
  final DateTime date;
  final TimeOfDay? checkIn;
  final TimeOfDay? checkOut;
  final AttendanceDayStatus status;
  final String? checkInPhotoPath;
  final String? checkOutPhotoPath;
  final String? evidencePhotoPath;
  final int overtimeHours;

  const AttendanceHistoryItem({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    this.checkInPhotoPath,
    this.checkOutPhotoPath,
    this.evidencePhotoPath,
    this.overtimeHours = 0,
  });
}

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final _attendanceApi = AttendanceApi();

  HistoryFilterType _selectedFilter = HistoryFilterType.bulanIni;
  DateTimeRange? _customRange;
  List<AttendanceHistoryItem>? _history;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _history = null;
      _error = null;
    });

    final now = DateTime.now();
    DateTime? startDate, endDate;

    switch (_selectedFilter) {
      case HistoryFilterType.bulanIni:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
      case HistoryFilterType.bulanLalu:
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0);
      case HistoryFilterType.customTanggal:
        if (_customRange == null) {
          setState(() => _history = []);
          return;
        }
        startDate = _customRange!.start;
        endDate = _customRange!.end;
    }

    try {
      final logs = await _attendanceApi.getLogs(
        startDate: startDate,
        endDate: endDate,
      );
      if (!mounted) return;
      setState(() {
        _history = logs.map(_mapLog).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat riwayat absensi.');
    }
  }

  String? _resolveFileUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final serverHost = Uri.parse(kApiBaseUrl).host;
    final serverPort = Uri.parse(kApiBaseUrl).port;
    String resolved;
    if (url.startsWith('http')) {
      resolved = url
          .replaceAll('localhost', serverHost)
          .replaceAll('127.0.0.1', serverHost);
    } else {
      final base = kApiBaseUrl.replaceFirst(RegExp(r'/api/v\d+$'), '');
      resolved = '$base$url';
    }
    return resolved;
  }

  AttendanceHistoryItem _mapLog(AttendanceModel m) {
    final date = DateTime.tryParse(m.date) ?? DateTime.now();

    TimeOfDay? checkIn;
    if (m.checkInAt != null) {
      final dt = DateTime.tryParse(m.checkInAt!);
      if (dt != null) checkIn = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }

    TimeOfDay? checkOut;
    if (m.checkOutAt != null) {
      final dt = DateTime.tryParse(m.checkOutAt!);
      if (dt != null) checkOut = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }

    final status = switch (m.status) {
      'present' => AttendanceDayStatus.hadir,
      'off' => AttendanceDayStatus.off,
      'extra_off' => AttendanceDayStatus.extraOff,
      'leave' => AttendanceDayStatus.cuti,
      'sick' => AttendanceDayStatus.sakit,
      _ => AttendanceDayStatus.alfa,
    };

    print('[mapLog] date=${m.date} status=${m.status} evidenceFileUrl=${m.evidenceFileUrl} checkInFileUrl=${m.checkInFileUrl}');
    return AttendanceHistoryItem(
      date: date,
      checkIn: checkIn,
      checkOut: checkOut,
      status: status,
      checkInPhotoPath: _resolveFileUrl(m.checkInFileUrl),
      checkOutPhotoPath: _resolveFileUrl(m.checkOutFileUrl),
      evidencePhotoPath: _resolveFileUrl(m.evidenceFileUrl),
      overtimeHours: m.overtimeHours ?? 0,
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _customRange,
      helpText: 'Pilih Rentang Tanggal',
      saveText: 'Simpan',
      cancelText: 'Batal',
    );
    if (picked == null || !mounted) return;
    setState(() => _customRange = picked);
    _loadHistory();
  }

  Map<AttendanceDayStatus, int> get _summary {
    final map = <AttendanceDayStatus, int>{
      for (final s in AttendanceDayStatus.values) s: 0,
    };
    for (final item in _history ?? []) {
      map[item.status] = (map[item.status] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final history = _history;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Absensi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ringkasan', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SummaryChip(label: 'Hadir', total: _summary[AttendanceDayStatus.hadir] ?? 0),
                      _SummaryChip(label: 'Off', total: _summary[AttendanceDayStatus.off] ?? 0),
                      _SummaryChip(label: 'Extra Off', total: _summary[AttendanceDayStatus.extraOff] ?? 0),
                      _SummaryChip(label: 'Cuti', total: _summary[AttendanceDayStatus.cuti] ?? 0),
                      _SummaryChip(label: 'Sakit', total: _summary[AttendanceDayStatus.sakit] ?? 0),
                      _SummaryChip(label: 'Alfa', total: _summary[AttendanceDayStatus.alfa] ?? 0),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<HistoryFilterType>(
                    value: _selectedFilter,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: HistoryFilterType.bulanIni, child: Text('Bulan Ini')),
                      DropdownMenuItem(value: HistoryFilterType.bulanLalu, child: Text('Bulan Lalu')),
                      DropdownMenuItem(value: HistoryFilterType.customTanggal, child: Text('Custom Tanggal')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedFilter = value);
                      _loadHistory();
                    },
                  ),
                  if (_selectedFilter == HistoryFilterType.customTanggal) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _pickCustomRange,
                      icon: const Icon(Icons.date_range_rounded),
                      label: Text(
                        _customRange == null
                            ? 'Pilih Rentang Tanggal'
                            : '${DateFormat('dd MMM yyyy', 'id_ID').format(_customRange!.start)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_customRange!.end)}',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: TextStyle(color: cs.error)),
              ),
            )
          else if (history == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (history.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Tidak ada data pada periode ini.'),
              ),
            )
          else
            ...history.map((item) => _HistoryCard(item: item)),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int total;

  const _SummaryChip({required this.label, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $total', style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AttendanceHistoryItem item;

  const _HistoryCard({required this.item});

  String _timeLabel(TimeOfDay? value) {
    if (value == null) return '-';
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
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

  Widget _photoBox(BuildContext context, String title, String? photoPath) {
    final path = photoPath?.trim() ?? '';
    final hasPhoto = path.isNotEmpty && path.startsWith('http');
    Widget content;
    if (!hasPhoto) {
      content = const Center(child: Text('Tidak ada foto', style: TextStyle(fontSize: 12)));
    } else {
      content = _AuthImage(url: path);
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: hasPhoto ? () => _showPhotoPreview(context, path) : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 110,
                width: double.infinity,
                color: const Color(0xFFECEFF5),
                child: Stack(
                  children: [
                    Positioned.fill(child: content),
                    if (hasPhoto)
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

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(item.date);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text('Jam Masuk: ${_timeLabel(item.checkIn)}',
                    style: const TextStyle(fontWeight: FontWeight.w500))),
                Expanded(child: Text('Jam Pulang: ${_timeLabel(item.checkOut)}',
                    style: const TextStyle(fontWeight: FontWeight.w500))),
              ],
            ),
            if (item.overtimeHours > 0) ...[
              const SizedBox(height: 4),
              Text('Lembur: ${item.overtimeHours} jam',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
            const SizedBox(height: 10),
            if (item.status == AttendanceDayStatus.hadir)
              Row(
                children: [
                  _photoBox(context, 'Foto Masuk', item.checkInPhotoPath),
                  const SizedBox(width: 10),
                  _photoBox(context, 'Foto Pulang', item.checkOutPhotoPath),
                ],
              )
            else
              Row(
                children: [
                  _photoBox(context, 'Foto Bukti', item.evidencePhotoPath),
                ],
              ),
            const SizedBox(height: 10),
            _StatusBadge(status: item.status),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AttendanceDayStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      AttendanceDayStatus.hadir => ('Hadir', const Color(0xFF2E7D32), Colors.white),
      AttendanceDayStatus.off => ('Off', const Color(0xFFF9A825), const Color(0xFF3A2A00)),
      AttendanceDayStatus.extraOff => ('Extra Off', const Color(0xFF1565C0), Colors.white),
      AttendanceDayStatus.cuti => ('Cuti', const Color(0xFFF9A825), const Color(0xFF3A2A00)),
      AttendanceDayStatus.sakit => ('Sakit', const Color(0xFFE67E22), Colors.white),
      AttendanceDayStatus.alfa => ('Alfa', const Color(0xFFC62828), Colors.white),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _AuthImage extends StatelessWidget {
  final String url;
  const _AuthImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (_, __, ___) =>
          const Center(child: Text('Foto gagal dimuat', style: TextStyle(fontSize: 12))),
    );
  }
}
