import 'dart:io';

import 'package:absensi_king_royal/services/services.dart';
import 'package:absensi_king_royal/utils/enum_mapper.dart';
import 'package:absensi_king_royal/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class EditProfileResult {
  final String fullName;
  final String placeOfBirth;
  final DateTime birthDate;
  final String gender;
  final String address;
  final String phoneNumber;
  final String bankAccountNumber;
  final String? profilePhotoPath;

  const EditProfileResult({
    required this.fullName,
    required this.placeOfBirth,
    required this.birthDate,
    required this.gender,
    required this.address,
    required this.phoneNumber,
    required this.bankAccountNumber,
    this.profilePhotoPath,
  });
}

class EditProfilePage extends StatefulWidget {
  final String fullName;
  final String placeOfBirth;
  final DateTime birthDate;
  final String gender;
  final String address;
  final String phoneNumber;
  final String bankAccountNumber;
  final String? profilePhotoPath;
  final String? profilePhotoId;

  const EditProfilePage({
    super.key,
    required this.fullName,
    required this.placeOfBirth,
    required this.birthDate,
    required this.gender,
    required this.address,
    required this.phoneNumber,
    required this.bankAccountNumber,
    this.profilePhotoPath,
    this.profilePhotoId,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _userApi = UserApi();
  final _fileApi = FileApi();
  final _picker = ImagePicker();

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _placeOfBirthCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bankCtrl;

  late DateTime _birthDate;
  late String _gender;
  bool _isSaving = false;
  bool _isPickingPhoto = false;
  bool _pendingPhotoRemove = false;

  String? _profilePhotoPath;
  String? _currentPhotoId;
  XFile? _pickedPhoto;

  static const _genderOptions = genderOptions;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController(text: widget.fullName);
    _placeOfBirthCtrl = TextEditingController(text: widget.placeOfBirth);
    _addressCtrl = TextEditingController(text: widget.address);
    _phoneCtrl = TextEditingController(text: widget.phoneNumber);
    _bankCtrl = TextEditingController(text: widget.bankAccountNumber);
    _birthDate = widget.birthDate;
    _profilePhotoPath = widget.profilePhotoPath;
    _currentPhotoId = widget.profilePhotoId;
    final displayGender = genderToDisplay(widget.gender);
    _gender = _genderOptions.contains(displayGender)
        ? displayGender
        : _genderOptions.first;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _placeOfBirthCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  ImageProvider<Object> get _photoProvider {
    if (_profilePhotoPath == null) {
      return const AssetImage('assets/icons/profile_empty.png');
    }
    if (_profilePhotoPath!.startsWith('http')) {
      return NetworkImage(_profilePhotoPath!);
    }
    if (File(_profilePhotoPath!).existsSync()) {
      return FileImage(File(_profilePhotoPath!));
    }
    return const AssetImage('assets/icons/profile_empty.png');
  }

  Future<void> _pickPhoto() async {
    setState(() => _isPickingPhoto = true);
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (!mounted) return;
    if (picked == null) {
      setState(() => _isPickingPhoto = false);
      return;
    }
    if (_currentPhotoId != null) {
      try {
        await _fileApi.delete(_currentPhotoId!);
      } catch (_) {}
      _currentPhotoId = null;
    }
    evictImageCache(_profilePhotoPath);
    setState(() {
      _pickedPhoto = picked;
      _profilePhotoPath = picked.path;
      _pendingPhotoRemove = false;
      _isPickingPhoto = false;
    });
  }

  void _removePhoto() {
    evictImageCache(_profilePhotoPath);
    setState(() {
      _pendingPhotoRemove = true;
      _pickedPhoto = null;
      _profilePhotoPath = null;
    });
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    try {
      String? finalPhotoPath = _profilePhotoPath;

      if (_pendingPhotoRemove && _pickedPhoto == null) {
        if (_currentPhotoId != null) {
          try { await _fileApi.delete(_currentPhotoId!); } catch (_) {}
        }
        await _userApi.updateMyProfilePhoto(null);
        finalPhotoPath = null;
      } else if (_pickedPhoto != null) {
        final fileModel = await _fileApi.upload(_pickedPhoto!, 'profile_picture');
        await _userApi.updateMyProfilePhoto(fileModel.id);
        finalPhotoPath = fileModel.fileUrl;
      }

      await _userApi.updateMyProfile(
        fullName: _fullNameCtrl.text.trim(),
        birthPlace: _placeOfBirthCtrl.text.trim().isNotEmpty
            ? _placeOfBirthCtrl.text.trim()
            : null,
        birthDate: _birthDate,
        gender: genderToApi(_gender),
        address: _addressCtrl.text.trim().isNotEmpty
            ? _addressCtrl.text.trim()
            : null,
        phoneNumber: _phoneCtrl.text.trim().isNotEmpty
            ? _phoneCtrl.text.trim()
            : null,
        bankAccountNumber: _bankCtrl.text.trim().isNotEmpty
            ? _bankCtrl.text.trim()
            : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil disimpan.')),
      );
      Navigator.of(context).pop(
        EditProfileResult(
          fullName: _fullNameCtrl.text.trim(),
          placeOfBirth: _placeOfBirthCtrl.text.trim(),
          birthDate: _birthDate,
          gender: genderToApi(_gender),
          address: _addressCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          bankAccountNumber: _bankCtrl.text.trim(),
          profilePhotoPath: finalPhotoPath,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapApiError(e.message))),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan profil. Coba lagi.')),
      );
    }
  }

  String _mapApiError(String raw) {
    if (raw.contains('full_name')) return 'Nama lengkap tidak valid.';
    if (raw.contains('gender')) return 'Jenis kelamin tidak valid.';
    if (raw.contains('phone_number')) return 'Nomor HP tidak valid.';
    if (raw.contains('bank_account_number')) return 'Nomor rekening tidak valid.';
    if (raw.contains('birth_date')) return 'Format tanggal lahir tidak valid.';
    if (raw.contains('birth_place')) return 'Tempat lahir tidak valid.';
    if (raw.contains('address')) return 'Alamat tidak valid.';
    return 'Gagal menyimpan profil. Periksa kembali data yang diisi.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Foto Profil ──────────────────────────────────────
            Center(
              child: Column(
                children: [
                  ProfileAvatar(radius: 44, photoPath: _profilePhotoPath),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: (_isSaving || _isPickingPhoto)
                            ? null
                            : _pickPhoto,
                        icon: _isPickingPhoto
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.image_rounded),
                        label: Text(_isPickingPhoto ? 'Memproses...' : 'Ganti Foto'),
                      ),
                      if (_profilePhotoPath != null)
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : _removePhoto,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Hapus Foto'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Data Pribadi ──────────────────────────────────────
            _SectionLabel('Data Pribadi'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _fullNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                label: Text.rich(TextSpan(children: [
                  const TextSpan(text: 'Nama Lengkap'),
                  const TextSpan(
                      text: ' *', style: TextStyle(color: Colors.red)),
                ])),
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama lengkap wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _placeOfBirthCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Tempat Lahir',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickBirthDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Lahir',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(
                  DateFormat('dd MMMM yyyy', 'id_ID').format(_birthDate),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Jenis Kelamin',
                border: OutlineInputBorder(),
              ),
              items: _genderOptions
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _gender = v);
              },
            ),
            const SizedBox(height: 20),

            // ── Kontak & Rekening ─────────────────────────────────
            _SectionLabel('Kontak & Rekening'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor HP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Alamat',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bankCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nomor Rekening',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Perubahan'),
            ),
            const SizedBox(height: 8),
            Text(
              '* Nama lengkap wajib diisi. Jabatan, departemen, dan data kepegawaian lainnya hanya dapat diubah oleh admin.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
