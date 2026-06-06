import 'package:absensi_king_royal/auth_service.dart';
import 'package:absensi_king_royal/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final AuthService authService;
  final void Function(AppUser user, bool rememberMe) onLoginSuccess;

  const LoginPage({
    super.key,
    required this.authService,
    required this.onLoginSuccess,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _hidePassword = true;
  bool _isLoading = false;
  String? _serverError;

  static const _keyEmail = 'remember_me_email';
  static const _keyRemember = 'remember_me_checked';

  static const _royalBlue = Color(0xFF0D2B52);
  static const _royalBlueDark = Color(0xFF071828);
  static const _royalGold = Color(0xFFC9A548);

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool(_keyRemember) ?? false;
    if (remembered) {
      final savedEmail = prefs.getString(_keyEmail) ?? '';
      if (savedEmail.isNotEmpty && mounted) {
        setState(() {
          _identityController.text = savedEmail;
          _rememberMe = true;
        });
      }
    }
  }

  Future<void> _saveOrClearEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool(_keyRemember, true);
      await prefs.setString(_keyEmail, email);
    } else {
      await prefs.remove(_keyRemember);
      await prefs.remove(_keyEmail);
    }
  }

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _mapLoginError(LoginErrorType error) {
    switch (error) {
      case LoginErrorType.emailNotRegistered:
        return 'Email/username tidak terdaftar.';
      case LoginErrorType.wrongPassword:
        return 'Password salah.';
      case LoginErrorType.inactiveAccount:
        return 'Akun nonaktif. Silakan hubungi admin.';
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _serverError = null;
    });

    final result = await widget.authService.login(
      identity: _identityController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.user != null) {
      await _saveOrClearEmail(_identityController.text.trim());
      if (!mounted) return;
      widget.onLoginSuccess(result.user!, _rememberMe);
      return;
    }

    setState(() => _serverError = _mapLoginError(result.error!));
  }

  Future<void> _forgotPassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordPage(
          authService: widget.authService,
          initialEmail: _identityController.text.trim(),
        ),
      ),
    );
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC62828), width: 2),
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    // ── Logo ──────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/icons/app_icon.jpg',
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'King Royal Hotel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sistem Manajemen Absensi',
                      style: TextStyle(
                        color: _royalGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Form Card ─────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _royalBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Masukkan kredensial akun Anda',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _identityController,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                'Email / Username',
                                Icons.person_outline_rounded,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email/username wajib diisi.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _hidePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: _inputDecoration(
                                'Password',
                                Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  onPressed: () =>
                                      setState(() => _hidePassword = !_hidePassword),
                                  icon: Icon(
                                    _hidePassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password wajib diisi.';
                                }
                                return null;
                              },
                            ),

                            if (_serverError != null) ...[
                              const SizedBox(height: 12),
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
                                        _serverError!,
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

                            const SizedBox(height: 4),
                            Row(
                              children: [
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: _royalBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (value) async {
                                      final checked = value ?? false;
                                      setState(() => _rememberMe = checked);
                                      if (!checked) {
                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        await prefs.remove(_keyRemember);
                                        await prefs.remove(_keyEmail);
                                      }
                                    },
                                  ),
                                ),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(fontSize: 13),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _forgotPassword,
                                  style: TextButton.styleFrom(
                                    foregroundColor: _royalBlue,
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Lupa password?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _royalBlue,
                                  disabledBackgroundColor:
                                      _royalBlue.withValues(alpha: 0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Masuk',
                                        style: TextStyle(
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

                    const SizedBox(height: 28),
                    Text(
                      'King Royal Hotel © 2025',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12,
                      ),
                    ),
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
