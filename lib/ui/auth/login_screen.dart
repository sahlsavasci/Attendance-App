import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Design Tokens: Bento Minimal
  static const Color _canvasBg = Color(0xFFF2F4F7);
  static const Color _cardSurface = Color(0xFFFFFFFF);
  static const Color _cobalt500 = Color(0xFF2952F2);
  static const Color _cobalt700 = Color(0xFF1A36A6);
  static const Color _cobalt50 = Color(0xFFE8EEFF);
  static const Color _inkText = Color(0xFF0E1A2B);
  static const Color _slateText = Color(0xFF5B6474);
  static const Color _errorRed = Color(0xFFD92D20);

  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _activeDemoRole;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  TextStyle _manrope({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? _errorRed : _inkText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: _manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    final emailOrNis = _emailController.text.trim();
    final password = _passwordController.text;

    if (emailOrNis.isEmpty || password.isEmpty) {
      _showSnackBar(
        'Masukkan Email / NIS dan kata sandi terlebih dahulu.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _activeDemoRole = null;
    });

    try {
      await _authService.signIn(emailOrNis, password);
    } on FirebaseAuthException catch (e) {
      _showSnackBar(_describeAuthError(e), isError: true);
    } catch (e) {
      _showSnackBar('Gagal masuk: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleQuickDemo(String role) async {
    final isTeacher = role == 'teacher';
    _emailController.text = isTeacher
        ? AuthService.teacherDemoEmail
        : AuthService.studentDemoEmail;
    _passwordController.text = AuthService.defaultDemoPassword;

    setState(() {
      _isLoading = true;
      _activeDemoRole = role;
    });

    try {
      final profile = await _authService.signInQuickDemo(role);
      if (!mounted) return;
      _showSnackBar(
        'Masuk sebagai ${profile.name} (${profile.isTeacher ? 'Wali Kelas' : profile.userClass})',
      );
    } catch (e) {
      _showSnackBar('Gagal memuat akun demo: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _activeDemoRole = null;
        });
      }
    }
  }

  String _describeAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format alamat email tidak valid.';
      case 'user-not-found':
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'wrong-password':
        return 'Email/NIS atau kata sandi tidak sesuai.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan oleh administrator.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Coba beberapa saat lagi.';
      default:
        return e.message ?? 'Autentikasi gagal (${e.code}).';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvasBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMainSignInCard(),
                  const SizedBox(height: 16),
                  _buildQuickDemoSwitcherCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainSignInCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cobalt50, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _inkText.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Logo Badge (Orbit Work style)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [_cobalt500, _cobalt700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 20),

          // Header Title & Subtitle
          Text(
            'IDN Attendance Portal',
            style: _manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _inkText,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Masuk dengan akun terdaftar SMK IDN Solo',
            style: _manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _slateText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Email / NIS Field
          Text(
            'Email Sekolah atau NIS',
            style: _manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _inkText,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: _manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _inkText,
            ),
            decoration: InputDecoration(
              hintText: 'siswa@idn.sch.id atau 202411001',
              hintStyle: _manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _slateText.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              prefixIcon: const Icon(
                Icons.alternate_email_rounded,
                size: 19,
                color: _slateText,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _cobalt50, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _cobalt500, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Password Field
          Text(
            'Kata Sandi',
            style: _manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _inkText,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _isLoading ? null : _handleSignIn(),
            style: _manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _inkText,
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan kata sandi',
              hintStyle: _manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _slateText.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                size: 19,
                color: _slateText,
              ),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Tampilkan sandi' : 'Sembunyikan sandi',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 19,
                  color: _slateText,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _cobalt50, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _cobalt500, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Primary Sign In Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: _cobalt500,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _cobalt50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading && _activeDemoRole == null
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: _cobalt500,
                      ),
                    )
                  : Text(
                      'Masuk Aplikasi',
                      style: _manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDemoSwitcherCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cobalt50, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _inkText.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _cobalt50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MODE PRESENTASI CEPAT',
                  style: _manrope(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: _cobalt500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '1-Tap Login Multi-Role',
                  style: _manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _slateText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDemoRoleButton(
                  roleKey: 'student',
                  label: 'Demo: Siswa XI RPL',
                  subtitle: 'Sahl • 202411001',
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDemoRoleButton(
                  roleKey: 'teacher',
                  label: 'Demo: Wali Kelas',
                  subtitle: 'Guru Pembimbing',
                  icon: Icons.admin_panel_settings_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoRoleButton({
    required String roleKey,
    required String label,
    required String subtitle,
    required IconData icon,
  }) {
    final isRoleLoading = _isLoading && _activeDemoRole == roleKey;

    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _isLoading ? null : () => _handleQuickDemo(roleKey),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cobalt50, width: 1.2),
          ),
          child: Row(
            children: [
              if (isRoleLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _cobalt500,
                  ),
                )
              else
                Icon(icon, size: 18, color: _cobalt500),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _inkText,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _slateText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

