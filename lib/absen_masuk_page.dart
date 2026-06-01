import 'package:absensi_king_royal/attendance_capture_page.dart';
import 'package:flutter/material.dart';

class AbsenMasukPage extends StatelessWidget {
  final String employeeName;
  final String employeeNik;

  const AbsenMasukPage({
    super.key,
    required this.employeeName,
    required this.employeeNik,
  });

  @override
  Widget build(BuildContext context) {
    return AttendanceCapturePage(
      pageTitle: 'Absen Masuk',
      attendanceLabel: 'Keterangan Absen Masuk',
      confirmButtonLabel: 'Konfirmasi Absen Masuk',
      employeeName: employeeName,
      employeeNik: employeeNik,
      attendanceType: 'check_in',
    );
  }
}
