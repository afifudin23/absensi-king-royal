import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:absensi_king_royal/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('renders home screen content', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AbsensiKingRoyalApp());

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Nama Karyawan'), findsOneWidget);
    expect(find.textContaining('kode karyawan:'), findsOneWidget);
    expect(find.text('Jabatan'), findsOneWidget);
    expect(find.text('Departemen'), findsOneWidget);
    expect(find.text('Info Bulan Ini'), findsOneWidget);
    expect(find.text('Status Pengajuan Izin'), findsOneWidget);
    expect(find.text('Status Absen Hari Ini'), findsOneWidget);
    expect(find.text('Menu Utama'), findsOneWidget);
    expect(find.text('Absen Masuk'), findsOneWidget);
    expect(find.text('Absen Pulang'), findsOneWidget);
    expect(find.text('Ajukan Izin'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Menu Cepat'), findsNothing);
  });

  testWidgets('menu actions update status text', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AbsensiKingRoyalApp());

    await tester.tap(find.text('Absen Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Absen Masuk'), findsWidgets);
    expect(find.text('Konfirmasi Absen Masuk'), findsOneWidget);

    await tester.tap(find.text('Gunakan Foto Simulasi'));
    await tester.pump();
    await tester.tap(find.text('Konfirmasi Absen Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Sudah Absen Masuk'), findsOneWidget);
    expect(find.textContaining('Absen masuk pada'), findsOneWidget);

    await tester.tap(find.text('Ajukan Izin'));
    await tester.pump();

    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('header tap opens employee profile page', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AbsensiKingRoyalApp());

    await tester.tap(find.text('Selamat Datang'));
    await tester.pumpAndSettle();

    expect(find.text('Profil Karyawan'), findsOneWidget);
    expect(find.text('Nomor HP'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Tanggal Bergabung'), findsOneWidget);
    expect(find.text('Riwayat Pengajuan Izin'), findsOneWidget);
    expect(find.text('Lihat Slip Gaji'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
  });
}
