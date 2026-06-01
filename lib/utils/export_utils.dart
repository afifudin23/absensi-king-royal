import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
  });
}

Future<File> exportRecapExcel(
  List<RecapExportRow> rows,
  int month,
  int year,
) async {
  final excel = Excel.createExcel();
  final sheet = excel['Rekap Absensi'];
  excel.setDefaultSheet('Rekap Absensi');

  final period = DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month));

  // Title
  sheet.cell(CellIndex.indexByString('A1')).value =
      TextCellValue('Rekap Absensi - $period');

  // Header
  final headers = [
    'Nama', 'Hadir', 'Off', 'Tidak Hadir', 'Cuti',
    'Extra Off', 'Sakit', 'Alfa', 'Lembur (jam)',
  ];
  for (var i = 0; i < headers.length; i++) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2));
    cell.value = TextCellValue(headers[i]);
    cell.cellStyle = CellStyle(bold: true);
  }

  // Data rows
  for (var r = 0; r < rows.length; r++) {
    final row = rows[r];
    final values = [
      row.nama,
      row.hadir,
      row.off,
      row.tidakHadir,
      row.cuti,
      row.extraOff,
      row.sakit,
      row.alfa,
      row.lembur,
    ];
    for (var c = 0; c < values.length; c++) {
      final v = values[c];
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 3))
          .value = v is int ? IntCellValue(v) : TextCellValue(v.toString());
    }
  }

  final dir = await getApplicationDocumentsDirectory();
  final filename = 'rekap_absensi_${year}_${month.toString().padLeft(2, '0')}.xlsx';
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(excel.encode()!);
  return file;
}

Future<File> exportRecapPdf(
  List<RecapExportRow> rows,
  int month,
  int year,
) async {
  final period = DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month));
  final pdf = pw.Document();

  final headers = [
    'Nama', 'Hadir', 'Off', 'Tdk\nHadir', 'Cuti',
    'Ekstra\nOff', 'Sakit', 'Alfa', 'Lembur\n(jam)',
  ];

  final colWidths = [
    const pw.FlexColumnWidth(3),
    const pw.FlexColumnWidth(1),
    const pw.FlexColumnWidth(1),
    const pw.FlexColumnWidth(1),
    const pw.FlexColumnWidth(1),
    const pw.FlexColumnWidth(1.2),
    const pw.FlexColumnWidth(1),
    const pw.FlexColumnWidth(1),
    const pw.FlexColumnWidth(1.2),
  ];

  pw.Widget headerCell(String text) => pw.Container(
        padding: const pw.EdgeInsets.all(4),
        color: PdfColors.blueGrey800,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 8,
          ),
          textAlign: pw.TextAlign.center,
        ),
      );

  pw.Widget dataCell(String text, {bool isName = false}) => pw.Container(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: isName ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
          textAlign: isName ? pw.TextAlign.left : pw.TextAlign.center,
        ),
      );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => [
        pw.Text(
          'Rekap Absensi - $period',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          columnWidths: {for (var i = 0; i < colWidths.length; i++) i: colWidths[i]},
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(children: headers.map(headerCell).toList()),
            ...rows.map(
              (row) => pw.TableRow(
                children: [
                  dataCell(row.nama, isName: true),
                  dataCell('${row.hadir}'),
                  dataCell('${row.off}'),
                  dataCell('${row.tidakHadir}'),
                  dataCell('${row.cuti}'),
                  dataCell('${row.extraOff}'),
                  dataCell('${row.sakit}'),
                  dataCell('${row.alfa}'),
                  dataCell('${row.lembur}'),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Dicetak: ${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    ),
  );

  final dir = await getApplicationDocumentsDirectory();
  final filename = 'rekap_absensi_${year}_${month.toString().padLeft(2, '0')}.pdf';
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(await pdf.save());
  return file;
}
