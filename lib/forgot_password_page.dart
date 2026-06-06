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

  int _step = 1;
  bool _loading = false;
  bool _hideNew = true;
  bool _hideConfirm = true;
  String? _errorText;
  String _sentEmail = '';

  static const _royalBlue = Color(0xFF0D2B52);
  static const _royalBlueDark = Color(0xFF071828);
  static const _royalGold = Color(0xFFC9A548);

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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                    const Expanded(
                      child: Text(
                        'Lupa Password',
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
              const SizedBox(height: 12),

              // ── Step indicator ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    _StepCircle(step: 1, current: _step, label: 'Email'),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: _step > 1
                            ? _royalGold
                            : Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    _StepCircle(step: 2, current: _step, label: 'Verifikasi'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Card ────────────────────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_step == 1) ..._buildStep1(),
                          if (_step == 2) ..._buildStep2(),
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

  List<Widget> _buildStep1() => [
        const Text(
          'Masukkan Email',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _royalBlue,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kode OTP akan dikirim ke email yang terdaftar.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendOtp(),
          decoration: _inputDecoration('Alamat Email', Icons.email_outlined),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 12),
          _ErrorBox(_errorText!),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _loading ? null : _sendOtp,
            style: FilledButton.styleFrom(
              backgroundColor: _royalBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text(
                    'Kirim Kode OTP',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ];

  List<Widget> _buildStep2() => [
        const Text(
          'Verifikasi & Password Baru',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _royalBlue,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            children: [
              const TextSpan(text: 'Kode OTP telah dikirim ke '),
              TextSpan(
                text: _sentEmail,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _royalBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(
            fontSize: 20,
            letterSpacing: 6,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: 'Kode OTP',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _royalBlue, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _newPassController,
          obscureText: _hideNew,
          decoration: _inputDecoration(
            'Password Baru (min. 3 karakter)',
            Icons.lock_outline_rounded,
            suffix: IconButton(
              icon: Icon(
                _hideNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey.shade400,
                size: 20,
              ),
              onPressed: () => setState(() => _hideNew = !_hideNew),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirmController,
          obscureText: _hideConfirm,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _resetPassword(),
          decoration: _inputDecoration(
            'Konfirmasi Password Baru',
            Icons.lock_outline_rounded,
            suffix: IconButton(
              icon: Icon(
                _hideConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey.shade400,
                size: 20,
              ),
              onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
            ),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 12),
          _ErrorBox(_errorText!),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _loading ? null : _resetPassword,
            style: FilledButton.styleFrom(
              backgroundColor: _royalBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: _loading
                ? null
                : () => setState(() {
                      _step = 1;
                      _errorText = null;
                      _otpController.clear();
                      _newPassController.clear();
                      _confirmController.clear();
                    }),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Kirim Ulang OTP'),
            style: TextButton.styleFrom(foregroundColor: _royalBlue),
          ),
        ),
      ];
}

class _StepCircle extends StatelessWidget {
  final int step;
  final int current;
  final String label;

  const _StepCircle({required this.step, required this.current, required this.label});

  static const _royalBlue = Color(0xFF0D2B52);
  static const _royalGold = Color(0xFFC9A548);

  @override
  Widget build(BuildContext context) {
    final isDone = current > step;
    final isActive = current >= step;

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? _royalGold
                : isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
            border: isActive && !isDone
                ? Border.all(color: _royalGold, width: 2.5)
                : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, size: 18, color: _royalBlue)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isActive ? _royalBlue : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEDED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC62828).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
