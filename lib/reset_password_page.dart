import 'package:absensi_king_royal/auth_service.dart';
import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  final AuthService authService;
  final AppUser user;

  const ResetPasswordPage({
    super.key,
    required this.authService,
    required this.user,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _isSubmitting = false;
  String? _errorText;

  static const _royalBlue = Color(0xFF0D2B52);
  static const _royalBlueDark = Color(0xFF071828);

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _mapError(PasswordChangeErrorType? error) {
    switch (error) {
      case PasswordChangeErrorType.wrongCurrentPassword:
        return 'Password saat ini tidak sesuai.';
      case PasswordChangeErrorType.weakPassword:
        return 'Password baru minimal 3 karakter.';
      case PasswordChangeErrorType.mismatch:
        return 'Konfirmasi password baru tidak sama.';
      case null:
        return 'Terjadi kesalahan.';
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final result = await widget.authService.changePassword(
      userId: widget.user.id,
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmNewPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.isSuccess) {
      setState(() => _errorText = _mapError(result.error));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password berhasil diubah.')),
    );
    Navigator.pop(context);
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _royalBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC62828)),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      labelStyle: TextStyle(color: Colors.grey.shade500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _toggleIcon(bool hide, VoidCallback onTap) => IconButton(
        onPressed: onTap,
        icon: Icon(
          hide ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          color: Colors.grey.shade400,
          size: 20,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_royalBlue, _royalBlueDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Ubah Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Icon banner ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),

              // ── Content card ────────────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Keamanan Akun',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _royalBlue,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF0FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  size: 16,
                                  color: _royalBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.user.email,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _royalBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: _hideCurrent,
                            decoration: _inputDecoration(
                              'Password Saat Ini',
                              Icons.lock_outline_rounded,
                              suffix: _toggleIcon(
                                _hideCurrent,
                                () => setState(() => _hideCurrent = !_hideCurrent),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Wajib diisi.' : null,
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _hideNew,
                            decoration: _inputDecoration(
                              'Password Baru',
                              Icons.lock_outline_rounded,
                              suffix: _toggleIcon(
                                _hideNew,
                                () => setState(() => _hideNew = !_hideNew),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Wajib diisi.';
                              if (v.length < 3) return 'Minimal 3 karakter.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _hideConfirm,
                            decoration: _inputDecoration(
                              'Konfirmasi Password Baru',
                              Icons.lock_outline_rounded,
                              suffix: _toggleIcon(
                                _hideConfirm,
                                () => setState(() => _hideConfirm = !_hideConfirm),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Wajib diisi.';
                              if (v != _newPasswordController.text) {
                                return 'Konfirmasi tidak sama.';
                              }
                              return null;
                            },
                          ),

                          if (_errorText != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDEDED),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFC62828).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Color(0xFFC62828),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorText!,
                                      style: const TextStyle(
                                        color: Color(0xFFC62828),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _isSubmitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: _royalBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded),
                              label: Text(
                                _isSubmitting ? 'Menyimpan...' : 'Simpan Password Baru',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
