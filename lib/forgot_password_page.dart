import 'package:absensi_king_royal/auth_service.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  final AuthService authService;
  final String initialEmail;

  const ForgotPasswordPage({
    super.key,
    required this.authService,
    this.initialEmail = '',
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmController = TextEditingController();

  int _step = 1; // 1 = email, 2 = otp + password baru
  bool _loading = false;
  bool _hideNew = true;
  bool _hideConfirm = true;
  String? _errorText;
  String _sentEmail = '';

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPassController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorText = 'Email tidak boleh kosong.');
      return;
    }
    setState(() {
      _loading = true;
      _errorText = null;
    });
    await widget.authService.requestPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sentEmail = email;
      _step = 2;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kode OTP telah dikirim ke $email.')),
    );
  }

  Future<void> _resetPassword() async {
    final otp = _otpController.text.trim();
    final newPass = _newPassController.text;
    final confirm = _confirmController.text;

    if (otp.length < 4) {
      setState(() => _errorText = 'Masukkan kode OTP yang valid.');
      return;
    }
    if (newPass.length < 3) {
      setState(() => _errorText = 'Password baru minimal 3 karakter.');
      return;
    }
    if (newPass != confirm) {
      setState(() => _errorText = 'Konfirmasi password tidak cocok.');
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final success = await widget.authService.resetPasswordWithOTP(
      email: _sentEmail,
      otp: otp,
      newPassword: newPass,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil direset. Silakan login.')),
      );
      Navigator.pop(context);
    } else {
      _otpController.clear();
      setState(() => _errorText = 'Kode OTP tidak valid atau sudah kadaluarsa.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lupa Password'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Step indicator
                    Row(
                      children: [
                        _StepDot(active: _step >= 1, done: _step > 1, label: '1'),
                        Expanded(
                          child: Divider(
                            color: _step > 1 ? cs.primary : cs.outlineVariant,
                            thickness: 2,
                          ),
                        ),
                        _StepDot(active: _step >= 2, done: false, label: '2'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Masukkan Email',
                            style: TextStyle(
                              fontSize: 11,
                              color: _step >= 1 ? cs.primary : cs.outlineVariant,
                            )),
                        Text('Kode OTP & Password Baru',
                            style: TextStyle(
                              fontSize: 11,
                              color: _step >= 2 ? cs.primary : cs.outlineVariant,
                            )),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (_step == 1) ...[
                      Text(
                        'Masukkan email yang terdaftar. Kami akan mengirimkan kode OTP.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _sendOtp(),
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(_errorText!,
                            style: TextStyle(color: cs.error, fontSize: 13)),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _loading ? null : _sendOtp,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Kirim Kode OTP'),
                      ),
                    ],

                    if (_step == 2) ...[
                      Text(
                        'Kode OTP telah dikirim ke $_sentEmail',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Kode OTP',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_clock_outlined),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newPassController,
                        obscureText: _hideNew,
                        decoration: InputDecoration(
                          labelText: 'Password Baru (min. 3 karakter)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_hideNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(() => _hideNew = !_hideNew),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmController,
                        obscureText: _hideConfirm,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _resetPassword(),
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password Baru',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_hideConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () =>
                                setState(() => _hideConfirm = !_hideConfirm),
                          ),
                        ),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(_errorText!,
                            style: TextStyle(color: cs.error, fontSize: 13)),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _loading ? null : _resetPassword,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Reset Password'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() {
                                  _step = 1;
                                  _errorText = null;
                                  _otpController.clear();
                                  _newPassController.clear();
                                  _confirmController.clear();
                                }),
                        child: const Text('Kirim ulang OTP'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  final bool done;
  final String label;

  const _StepDot({required this.active, required this.done, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? cs.primary : cs.surfaceContainerHighest,
      ),
      child: Center(
        child: done
            ? Icon(Icons.check, size: 16, color: cs.onPrimary)
            : Text(label,
                style: TextStyle(
                  color: active ? cs.onPrimary : cs.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                )),
      ),
    );
  }
}
