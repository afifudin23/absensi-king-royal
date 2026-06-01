# Feature Summary — Absensi King Royal

Last updated: 2026-06-01 (rev 6)

---

## Keterangan

- ✅ Sudah ada & berfungsi
- ⚠️ Ada tapi belum sempurna / ada bug
- ❌ Belum ada

---

## 1. Auth

| Fitur                        | API                                 | Flutter                                       | Catatan                                                           |
| ---------------------------- | ----------------------------------- | --------------------------------------------- | ----------------------------------------------------------------- |
| Login (email + password)     | ✅`POST /api/v1/auth/login`       | ✅ Terhubung                                  |                                                                   |
| Logout                       | ✅`POST /api/v1/auth/logout`      | ✅ Terhubung                                  | Token tidak di-blacklist di server                                |
| Restore session (auto-login) | ✅`GET /api/v1/users/me`          | ✅ Terhubung (cek token saat app start)       |                                                                   |
| Register akun baru           | ✅`POST /api/v1/auth/register`    | ❌ Tidak ada halaman register                 | Karyawan dibuat oleh admin                                        |
| Ganti password               | ✅`PUT /api/v1/users/me/password` | ✅ Terhubung                                  | Min 3 karakter (dev), min 8 untuk production                      |
| Lupa password (dari login)   | ✅ `POST /auth/forgot-password` + `POST /auth/reset-password` | ✅ Terhubung (OTP 2-step) | OTP 6 digit, expire 10 menit. Min password 3 karakter (dev) |

---

## 2. Profil Karyawan

| Fitur                          | API                                 | Flutter                               | Catatan                            |
| ------------------------------ | ----------------------------------- | ------------------------------------- | ---------------------------------- |
| Lihat profil sendiri           | ✅`GET /api/v1/users/me`          | ✅ Terhubung                          | Data diambil saat login via `getMyProfile()` |
| Edit profil sendiri            | ✅`PUT /api/v1/users/me`          | ✅ Terhubung                          | Field: tempat/tgl lahir, gender, alamat, HP, rekening |
| Upload foto profil             | ✅`POST /api/v1/files`            | ✅ Terhubung                          | `FileApi.upload` + `UserApi.updateMyProfilePhoto` |
| Hapus foto profil              | ✅`PUT /api/v1/users/me`          | ✅ Terhubung                          | Set `profile_picture_file_id: null` via `updateMyProfilePhoto(null)` |
| Lihat riwayat slip gaji (user) | ✅ `GET /api/v1/payrolls/me`       | ✅ Terhubung                          | `_SlipHistoryPage` fetch dari `PayrollApi.getMyPayrolls()` |

---

## 3. Absen Masuk / Pulang

> Flow yang benar: Upload foto dulu → dapat `file_id` → kirim check-in/out dengan `file_id`

| Fitur                                          | API                                     | Flutter                                  | Catatan                                              |
| ---------------------------------------------- | --------------------------------------- | ---------------------------------------- | ---------------------------------------------------- |
| Upload foto absen                              | ✅`POST /api/v1/files`                | ✅ Terhubung                             | `FileApi.upload(XFile, 'check_in'/'check_out')` |
| Check-in dengan `file_id`                    | ✅`POST /api/v1/attendance/check-in`  | ✅ Terhubung                             | `AttendanceApi.checkIn(fileId)` dipanggil setelah upload |
| Check-out dengan `file_id`                   | ✅`POST /api/v1/attendance/check-out` | ✅ Terhubung                             | `AttendanceApi.checkOut(fileId)` dipanggil setelah upload |
| Cek status absen hari ini                      | ✅ `GET /attendance/logs?start_date=today&end_date=today` | ✅ Terhubung | Load saat `HomeScreen.initState` via `getTodayAttendance()` |
| Toast konfirmasi absen                         | —                                       | ✅ Ada                                   | Muncul saat absen masuk/pulang berhasil |
| Validasi duplikasi check-in                    | ✅ Ada di service (cek per tanggal)     | —                                       |                                                      |
| Foto masuk/pulang unik (1 foto = 1 attendance) | ✅ Unique constraint di DB              | —                                       |                                                      |

---

## 4. Dashboard — Info Bulan Ini

| Fitur                                       | API                                      | Flutter              | Catatan                                      |
| ------------------------------------------- | ---------------------------------------- | -------------------- | -------------------------------------------- |
| Total hadir/off/cuti/sakit/lembur bulan ini | ✅ `GET /attendance/logs?start_date=&end_date=` | ✅ Terhubung | Hitung client-side, group by status |
| Status absen hari ini                       | ✅ `GET /attendance/logs?start_date=today&end_date=today` | ✅ Terhubung | Load saat `HomeScreen.initState` |
| Daftar pengajuan izin bulan ini             | ✅ `GET /api/v1/attendance-requests/me` | ✅ Terhubung | Load semua, filter bulan ini di client |

---

## 5. Riwayat Absensi

| Fitur                                                    | API                                             | Flutter                 | Catatan                               |
| -------------------------------------------------------- | ----------------------------------------------- | ----------------------- | ------------------------------------- |
| List riwayat absensi sendiri (hadir + izin dalam 1 list) | ✅`GET /api/v1/attendance/logs`               | ✅ Terhubung            | Load per filter (bulan ini/lalu/custom) |
| Filter per bulan/tahun                                   | ✅ `?start_date=&end_date=`                   | ✅ Terhubung            | Setiap ganti filter reload dari API |
| Foto check-in/out di riwayat                             | ✅`check_in_file_url`, `check_out_file_url` | ✅ Terhubung            | Tampil via `NetworkImage` |
| File bukti izin di riwayat                               | ✅`evidence_file_url` di response             | ⚠️ Tidak ditampilkan  | Riwayat absen tidak menampilkan bukti izin |
| Jam lembur di riwayat                                    | ✅`overtime_hours` di response                | ✅ Terhubung            | Ditampilkan di kartu riwayat |

> **Catatan**: Flutter pakai enum `hadir/off/cuti/sakit/alfa/extraOff`, API pakai `present/off/leave/sick/absent/extra_off` — sudah di-mapping.

---

## 6. Ajukan Izin / Cuti / Lembur

| Fitur                           | API                                       | Flutter                   | Catatan                                           |
| ------------------------------- | ----------------------------------------- | ------------------------- | ------------------------------------------------- |
| Buat pengajuan                  | ✅`POST /api/v1/attendance-requests`    | ✅ Terhubung              | Upload bukti dulu jika ada, lalu create request |
| Tipe pengajuan                  | ✅ sick, leave, extra_off, overtime       | ✅ Terhubung              | Mapping Flutter → API sudah dilakukan |
| Upload bukti (foto dokter dll)  | ✅`POST /api/v1/files`                  | ✅ Terhubung              | `FileApi.upload` sebelum submit |
| Toast sukses pengajuan          | —                                         | ✅ Ada                    | "Pengajuan [jenis] berhasil dikirim." |
| Lihat riwayat pengajuan sendiri | ✅`GET /api/v1/attendance-requests/me`  | ✅ Terhubung              | Load via `_loadLeaveHistory()` di HomeScreen |
| Edit pengajuan                  | ✅`PUT /api/v1/attendance-requests/:id` | ❌ Tidak ada halaman edit |                                                   |
| Hapus pengajuan (bulk)          | ✅`DELETE /api/v1/attendance-requests`  | ❌ Tidak ada tombol       | Kirim `{ "ids": [...] }`                        |

---

## 7. Admin — Manajemen Karyawan

| Fitur                   | API                                 | Flutter                              | Catatan |
| ----------------------- | ----------------------------------- | ------------------------------------ | ------- |
| List semua karyawan     | ✅`GET /api/v1/users`             | ✅ Terhubung                         | Load saat init & setelah CRUD |
| Tambah karyawan baru    | ✅`POST /api/v1/users`            | ✅ Terhubung                         | Password default `Password123!` |
| Edit data karyawan      | ✅`PUT /api/v1/users/:user_id`    | ✅ Terhubung                         |         |
| Hapus karyawan          | ✅`DELETE /api/v1/users/:user_id` | ✅ Terhubung                         |         |
| Toggle aktif/nonaktif   | ❌ Field `is_active` tidak ada di model User | ⚠️ Ada di UI tapi API mengabaikannya | Perlu migration untuk tambah kolom `is_active` |
| Reset password karyawan | ✅ `POST /api/v1/users/:user_id/reset-password` | ✅ Terhubung | Password default `Password123!` |
| Status kepegawaian      | ✅ `employment_status` (permanent/contract/internship/freelance) | ✅ Terhubung | Ditampilkan & bisa diedit |
| Filter/search karyawan  | ✅ `?search=&role=`               | ⚠️ Filter client-side              | API support ada, UI pakai client-side |

---

## 8. Admin — Rekap Absensi

| Fitur                                                     | API                                           | Flutter                      | Catatan                                      |
| --------------------------------------------------------- | --------------------------------------------- | ---------------------------- | -------------------------------------------- |
| Rekap absensi semua karyawan per bulan                    | ✅ `GET /api/v1/attendance/recap?month=&year=` | ✅ Terhubung          | Reload otomatis saat ganti bulan/tahun |
| Edit absensi manual (status, jam, catatan, lembur)        | ✅`PATCH /api/v1/attendance/:attendance_id` | ✅ Terhubung           | Admin only, pakai `attendanceId` dari daily detail |
| Pindah status (hadir → izin) via admin edit              | ✅ Tersupport di PATCH                        | ✅ Terhubung           |         |
| Filter rekap per bulan/karyawan                           | ✅ `/recap?month=&year=`                      | ⚠️ Filter nama client-side | Filter nama masih di client |
| ~~Tombol Edit Rekap~~                                     | —                                             | ❌ Dihapus                   | Dihapus dari UI — edit via Detail Lengkap |

---

## 9. Admin — Approval Pengajuan Izin

| Fitur                                      | API                                                | Flutter                 | Catatan                        |
| ------------------------------------------ | -------------------------------------------------- | ----------------------- | ------------------------------ |
| List semua pengajuan                       | ✅`GET /api/v1/attendance-requests`              | ✅ Terhubung            | Load saat init |
| Approve pengajuan                          | ✅`PATCH /api/v1/attendance-requests/:id/status` | ✅ Terhubung            |                                |
| Reject pengajuan                           | ✅`PATCH /api/v1/attendance-requests/:id/status` | ✅ Terhubung            |                                |
| Update absensi otomatis saat approved      | ✅`applyApprovedRequestToAttendance` dipanggil   | —                      |                                |
| Bukti izin otomatis tersalin ke attendance | ✅`evidence_file_id` disalin saat approve        | —                      |                                |
| Admin tidak bisa approve pengajuan sendiri | ✅ Validasi ada di service                         | —                      |                                |
| Filter per status/tanggal                  | ✅ `?status=&type=&start_date=&end_date=`        | ⚠️ Filter client-side | API support ada, UI belum pakai |

---

## 10. Admin — Payroll (Slip Gaji)

| Fitur                        | API                                               | Flutter              | Catatan |
| ---------------------------- | ------------------------------------------------- | -------------------- | ------- |
| List semua slip gaji         | ✅`GET /api/v1/payrolls`                        | ✅ Terhubung         | Load saat init & ganti periode |
| Generate slip 1 karyawan     | ✅`POST /api/v1/payrolls/generate/:employee_id` | ✅ Terhubung         |         |
| Generate slip semua karyawan | ✅`POST /api/v1/payrolls/generate-all`          | ✅ Terhubung         |         |
| Edit komponen slip gaji      | ✅`PUT /api/v1/payrolls/:payroll_id`            | ✅ Terhubung         |         |
| Kirim slip via email         | ✅`POST /api/v1/payrolls/:payroll_id/send`      | ✅ Terhubung         |         |
| Konfigurasi komponen gaji    | ✅`GET/POST/PUT /api/v1/payroll-settings`       | ❌ Tidak ada halaman | Tidak ada UI untuk ini |

> **Catatan overtime**: API menyimpan `overtime_hours` di `attendances` saat request lembur diapprove. Payroll menggunakan nilai ini dikalikan rate dari `payroll_settings`.

---

## 11. Admin — Log Aktivitas

| Fitur                          | API                              | Flutter                        | Catatan                                              |
| ------------------------------ | -------------------------------- | ------------------------------ | ---------------------------------------------------- |
| List log aktivitas             | ✅ `GET /api/v1/activity-logs`  | ✅ Terhubung                   | Fetch 100 log terbaru, auto-refresh dengan tombol ↺  |
| Filter hanya POST/PUT/PATCH/DELETE | ✅ Middleware skip GET       | ✅ Filter client-side juga     | GET tidak disimpan ke DB sama sekali                 |
| Deskripsi human-readable (ID)  | ✅ `describeActivity()` di Go   | ✅ Pakai `m.description` dari API | "Absen masuk", "Generate slip gaji", dll.          |
| Pagination                     | ✅ `?page=&limit=`              | ⚠️ Load 100 sekaligus          | Belum ada infinite scroll / load more                |
| Filter per user/method/search  | ✅ Query params tersedia         | ❌ Belum dipakai di UI          |                                                      |
| Tampilan module sebagai chip   | —                                | ✅ Ada                          | Chip biru kecil di kanan nama actor                  |

---

## 12. File / Foto

| Fitur                    | API                                 | Flutter            | Catatan                   |
| ------------------------ | ----------------------------------- | ------------------ | ------------------------- |
| Upload gambar (JPEG/PNG) | ✅`POST /api/v1/files`            | ✅ Terhubung       | Dipakai di foto profil & foto absen masuk/pulang |
| Hapus file               | ✅`DELETE /api/v1/files/:file_id` | ✅ Terhubung       | Dipanggil saat ganti/hapus foto profil |
| Validasi hanya gambar    | ✅ Ada (sniff content-type)         | —                 |                           |
| Batas ukuran file        | ✅ Maks 5 MB                        | —                 |                           |
| Unique per attachment    | ✅ DB unique constraint per kolom   | —                 |                           |

---

## 13. UX — Toast & Feedback

| Action                        | Toast Sukses                              | Toast Error     |
| ----------------------------- | ----------------------------------------- | --------------- |
| Absen masuk                   | ✅ "Absen masuk berhasil dicatat."        | ✅ Ada          |
| Absen pulang                  | ✅ "Absen pulang berhasil dicatat."       | ✅ Ada          |
| Ajukan izin/cuti/lembur       | ✅ "Pengajuan [jenis] berhasil dikirim."  | ✅ Ada          |
| Edit profil                   | ✅ "Profil berhasil disimpan."            | ✅ Ada          |
| Ganti foto profil             | ✅ "Foto profil berhasil diubah."         | ✅ Ada          |
| Hapus foto profil             | ✅ "Foto profil berhasil dihapus."        | ✅ Ada          |
| Kirim OTP lupa password       | ✅ "Kode OTP telah dikirim ke [email]."   | ✅ Ada (inline) |
| Reset password via OTP        | ✅ "Password berhasil direset."           | ✅ Ada (inline) |
| Ganti password (reset page)   | ✅ "Password berhasil direset."           | ✅ Ada (inline) |
| Generate/edit/kirim slip gaji | ✅ Ada                                    | ✅ Ada          |
| Approve/reject pengajuan      | ✅ Ada                                    | ✅ Ada          |
| Tambah/edit/hapus karyawan    | ✅ Ada                                    | ✅ Ada          |

---

## Ringkasan: Yang Belum Ada / Perlu Dikerjakan

| # | Item                                             | Prioritas |
| - | ------------------------------------------------ | --------- |
| 1 | Field `is_active` di User model (migration)      | 🟡 Sedang |
| 2 | UI konfigurasi payroll settings                  | 🟢 Rendah |
| 3 | Pagination / load more di log aktivitas          | 🟢 Rendah |
| 4 | Filter nama/method di UI log aktivitas           | 🟢 Rendah |
| 5 | Edit / hapus pengajuan izin (user)               | 🟢 Rendah |
| 6 | Bukti izin tampil di riwayat absensi user        | 🟢 Rendah |

---

## Bug yang Masih Ada

| # | Bug                                          | File               | Dampak                                | Status |
| - | -------------------------------------------- | ------------------ | ------------------------------------- | ------ |
| 1 | Token tidak di-blacklist saat logout         | `auth_service.go` | Token lama masih valid sampai expired | ⏸️ By design — butuh Redis blacklist |
| 2 | Toggle aktif/nonaktif karyawan tidak berfungsi | `user_model.go` | `is_active` dikirim tapi diabaikan API | ❌ Field belum ada di DB |
| 3 | Min password 3 karakter (harusnya 8 di prod) | `auth_request.go` | Password lemah bisa diterima | ⚠️ Development only — kembalikan ke 8 sebelum production |

---

## Mapping Enum Flutter ↔ API

### Tipe Absensi

| Flutter      | API           |
| ------------ | ------------- |
| `hadir`    | `present`   |
| `off`      | `off`       |
| `cuti`     | `leave`     |
| `sakit`    | `sick`      |
| `alfa`     | `absent`    |
| `extraOff` | `extra_off` |

### Tipe Pengajuan Izin

| Flutter      | API           |
| ------------ | ------------- |
| `sakit`    | `sick`      |
| `cuti`     | `leave`     |
| `extraOff` | `extra_off` |
| `lembur`   | `overtime`  |

### Status Pengajuan

| Flutter      | API          |
| ------------ | ------------ |
| `pending`  | `pending`  |
| `approved` | `approved` |
| `rejected` | `rejected` |

### Role

| Tampilan Flutter | API     |
| ---------------- | ------- |
| `Admin`        | `admin` |
| `User`         | `user`  |

### Status Kepegawaian

| Tampilan Flutter | API           |
| ---------------- | ------------- |
| `Tetap`        | `permanent`  |
| `Kontrak`      | `contract`   |
| `Magang`       | `internship` |
| `Freelance`    | `freelance`  |

---

## Status Integrasi Keseluruhan

| Modul                       | API | Flutter   | Integrasi                    |
| --------------------------- | --- | --------- | ---------------------------- |
| Auth (login/logout/session) | ✅  | ✅        | ✅ Selesai                   |
| Lupa & reset password       | ✅  | ✅        | ✅ Selesai                   |
| Ganti password              | ✅  | ✅        | ✅ Selesai                   |
| Profil (lihat)              | ✅  | ✅        | ✅ Selesai                   |
| Profil (edit + foto)        | ✅  | ✅        | ✅ Selesai                   |
| Slip gaji (lihat sendiri)   | ✅  | ✅        | ✅ Selesai                   |
| Absen masuk/pulang          | ✅  | ✅        | ✅ Selesai                   |
| Status absen hari ini       | ✅  | ✅        | ✅ Selesai                   |
| Dashboard stats bulan ini   | ✅  | ✅        | ✅ Selesai                   |
| Riwayat absensi             | ✅  | ✅        | ✅ Selesai                   |
| Ajukan izin/lembur          | ✅  | ✅        | ✅ Selesai                   |
| Admin - karyawan            | ✅  | ✅        | ✅ Selesai (kecuali is_active)|
| Admin - rekap absensi       | ✅  | ✅        | ✅ Selesai                   |
| Admin - approval            | ✅  | ✅        | ✅ Selesai                   |
| Admin - payroll             | ✅  | ✅        | ✅ Selesai (kecuali config)  |
| Admin - log aktivitas       | ✅  | ✅        | ✅ Selesai                   |
| File upload                 | ✅  | ✅        | ✅ Selesai (foto profil + absen) |
