import 'package:absensi_king_royal/attendance_capture_page.dart';
import 'package:flutter/material.dart';

class AbsenPulangPage extends StatelessWidget {
  final String employeeName;
  final String employeeNik;

  const AbsenPulangPage({
    super.key,
    required this.employeeName,
    required this.employeeNik,
  });

  @override
  Widget build(BuildContext context) {
    return AttendanceCapturePage(
      pageTitle: 'Absen Pulang',
      attendanceLabel: 'Keterangan Absen Pulang',
      confirmButtonLabel: 'Konfirmasi Absen Pulang',
      employeeName: employeeName,
      employeeNik: employeeNik,
      attendanceType: 'check_out',
    );
  }
}
