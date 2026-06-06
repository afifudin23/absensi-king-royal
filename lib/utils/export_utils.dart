import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class RecapDailyDetail {
  final DateTime date;
  final String status;
  final String checkIn;
  final String checkOut;
  final int lemburJam;
  final String keterangan;

  const RecapDailyDetail({
    required this.date,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.lemburJam,
    required this.keterangan,
  });
}

class RecapExportRow {
  final String nama;
  final int hadir;
  final int off;
  final int tidakHadir;
  final int cuti;
  final int extraOff;
  final int sakit;
  final int alfa;
  final int lembur;
  final List<RecapDailyDetail> dailyDetails;

  const RecapExportRow({
    required this.nama,
    required this.hadir,
    required this.off,
    required this.tidakHadir,
    required this.cuti,
    required this.extraOff,
    required this.sakit,
    required this.alfa,
    required this.lembur,
    this.dailyDetails = const [],
  });
}

// ─── Color constants (app theme) ─────────────────────────────────────────────
const _cNavy      = '0D2B52'; // app primary
const _cNavyLight = '1A4F8C'; // lighter navy for sub-headers
const _cGold      = 'C9A548'; // app secondary / accent
const _cWhite     = 'FFFFFF';
const _cRowAlt    = 'F0F5FF'; // alternating data row
const _cYellow    = 'FFF9E0'; // non-hadir
const _cGreen     = 'E6F4EA'; // total / hadir
const _cGray      = 'F5F6FA'; // light neutral

// ─── Excel helpers ────────────────────────────────────────────────────────────

ExcelColor _c(String hex) => ExcelColor.fromHexString(hex);

CellStyle _style({
  bool bold = false,
  String bg = _cWhite,
  String fg = '1A1A2E',
  int? size,
  bool wrapText = false,
  HorizontalAlign hAlign = HorizontalAlign.Left,
}) =>
    CellStyle(
      bold: bold,
      fontSize: size,
      backgroundColorHex: _c(bg),
      fontColorHex: _c(fg),
      textWrapping: wrapText ? TextWrapping.WrapText : TextWrapping.Clip,
      horizontalAlign: hAlign,
    );

void _put(Sheet s, int col, int row, dynamic value,
    {CellStyle? style}) {
  final cell =
      s.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
  if (value is int) {
    cell.value = IntCellValue(value);
  } else {
    cell.value = TextCellValue(value?.toString() ?? '');
  }
  if (style != null) cell.cellStyle = style;
}

// Apply same style to a full row across [fromCol..toCol]
void _fillRow(Sheet s, int row, int toCol, CellStyle style,
    {int fromCol = 0}) {
  for (var c = fromCol; c <= toCol; c++) {
    final cell =
        s.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
    if (cell.value == null) cell.value = TextCellValue('');
    cell.cellStyle = style;
  }
}

// ─── Excel export ─────────────────────────────────────────────────────────────

Future<File> exportRecapExcel(
  List<RecapExportRow> rows,
  int month,
  int year,
) async {
  final excel = Excel.createExcel();
  final period =
      DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month));

  // ── Sheet 1: Ringkasan ──────────────────────────────────────────────────────
  final sum = excel['Ringkasan'];
  excel.setDefaultSheet('Ringkasan');

  // Column widths
  sum.setColumnWidth(0, 28); // Nama
  for (var i = 1; i <= 8; i++) {
    sum.setColumnWidth(i, 13);
  }

  // Title row
  _put(sum, 0, 0, 'Rekap Absensi - $period',
      style: _style(bold: true, bg: _cNavy, fg: _cGold, size: 13));
  _fillRow(sum, 0, 8, _style(bg: _cNavy, fg: _cGold), fromCol: 1);

  // Sub-title row
  _put(sum, 0, 1, 'Periode: $period',
      style: _style(bg: _cNavyLight, fg: _cWhite));
  _fillRow(sum, 1, 8, _style(bg: _cNavyLight, fg: _cWhite), fromCol: 1);

  // Header row
  const sumHdrs = [
    'Nama', 'Hadir', 'Off', 'Tidak Hadir', 'Cuti',
    'Extra Off', 'Sakit', 'Alfa', 'Lembur (jam)',
  ];
  final hdrStyle = _style(bold: true, bg: _cNavyLight, fg: _cWhite,
      hAlign: HorizontalAlign.Center);
  for (var i = 0; i < sumHdrs.length; i++) {
    _put(sum, i, 3, sumHdrs[i], style: i == 0
        ? _style(bold: true, bg: _cNavyLight, fg: _cWhite)
        : hdrStyle);
  }

  // Data rows (alternating)
  for (var r = 0; r < rows.length; r++) {
    final row = rows[r];
    final bg = r.isOdd ? _cRowAlt : _cWhite;
    final numStyle = _style(bg: bg, hAlign: HorizontalAlign.Center);
    _put(sum, 0, r + 4, row.nama, style: _style(bold: true, bg: bg));
    _put(sum, 1, r + 4, row.hadir,   style: numStyle);
    _put(sum, 2, r + 4, row.off,     style: numStyle);
    _put(sum, 3, r + 4, row.tidakHadir, style: numStyle);
    _put(sum, 4, r + 4, row.cuti,    style: numStyle);
    _put(sum, 5, r + 4, row.extraOff, style: numStyle);
    _put(sum, 6, r + 4, row.sakit,   style: numStyle);
    _put(sum, 7, r + 4, row.alfa,    style: numStyle);
    _put(sum, 8, r + 4, row.lembur,  style: numStyle);
  }

  // ── Sheet 2: Detail Harian ──────────────────────────────────────────────────
  final det = excel['Detail Harian'];

  det.setColumnWidth(0, 13); // Tanggal
  det.setColumnWidth(1, 10); // Hari
  det.setColumnWidth(2, 12); // Jam Masuk
  det.setColumnWidth(3, 12); // Jam Pulang
  det.setColumnWidth(4, 12); // Status
  det.setColumnWidth(5, 12); // Lembur
  det.setColumnWidth(6, 24); // Keterangan

  const detHdrs = [
    'Tanggal', 'Hari', 'Jam Masuk', 'Jam Pulang',
    'Status', 'Lembur (jam)', 'Keterangan',
  ];
  final detHdrStyle = _style(bold: true, bg: _cNavyLight, fg: _cWhite,
      hAlign: HorizontalAlign.Center);

  int curRow = 0;
  for (final row in rows) {
    // ── Employee banner (navy bg, gold name) ──
    _put(det, 0, curRow, row.nama,
        style: _style(bold: true, bg: _cNavy, fg: _cGold, size: 10));
    _fillRow(det, curRow, 6, _style(bg: _cNavy, fg: _cGold), fromCol: 1);
    curRow++;

    // ── Column headers ──
    for (var i = 0; i < detHdrs.length; i++) {
      _put(det, i, curRow, detHdrs[i], style: detHdrStyle);
    }
    curRow++;

    // ── Daily rows ──
    if (row.dailyDetails.isEmpty) {
      _put(det, 0, curRow, 'Tidak ada data absensi',
          style: _style(bg: _cGray));
      _fillRow(det, curRow, 6, _style(bg: _cGray), fromCol: 1);
      curRow++;
    } else {
      final sorted = [...row.dailyDetails]
        ..sort((a, b) => a.date.compareTo(b.date));
      for (var i = 0; i < sorted.length; i++) {
        final d = sorted[i];
        final isHadir = d.status == 'Hadir';
        final bg = isHadir ? (i.isEven ? _cWhite : _cRowAlt) : _cYellow;
        final textStyle = _style(bg: bg);
        final numStyle  = _style(bg: bg, hAlign: HorizontalAlign.Center);
        final statusStyle = _style(
          bold: !isHadir,
          bg: bg,
          fg: isHadir ? '1A1A2E' : _cNavy,
          hAlign: HorizontalAlign.Center,
        );
        _put(det, 0, curRow, DateFormat('dd/MM/yyyy').format(d.date), style: textStyle);
        _put(det, 1, curRow, DateFormat('EEEE', 'id_ID').format(d.date), style: textStyle);
        _put(det, 2, curRow, d.checkIn,  style: numStyle);
        _put(det, 3, curRow, d.checkOut, style: numStyle);
        _put(det, 4, curRow, d.status,   style: statusStyle);
        _put(det, 5, curRow, d.lemburJam, style: numStyle);
        _put(det, 6, curRow, d.keterangan, style: textStyle);
        curRow++;
      }
    }

    // ── Total row ──
    final totStyle   = _style(bold: true, bg: _cGreen);
    final totNumStyle = _style(bold: true, bg: _cGreen, hAlign: HorizontalAlign.Center);
    _put(det, 0, curRow, 'TOTAL', style: totStyle);
    _put(det, 1, curRow, '', style: totStyle);
    _put(det, 2, curRow, '', style: totStyle);
    _put(det, 3, curRow, '', style: totStyle);
    _put(det, 4, curRow,
        'Hadir:${row.hadir} Off:${row.off} Sakit:${row.sakit} Cuti:${row.cuti} EO:${row.extraOff} Alfa:${row.alfa}',
        style: totStyle);
    _put(det, 5, curRow, row.lembur, style: totNumStyle);
    _put(det, 6, curRow, '', style: totStyle);
    curRow += 2; // spacer
  }

  // Remove default empty sheet
  if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');

  final dir = await getApplicationDocumentsDirectory();
  final filename =
      'rekap_absensi_${year}_${month.toString().padLeft(2, '0')}.xlsx';
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(excel.encode()!);
  return file;
}
