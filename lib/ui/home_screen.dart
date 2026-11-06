import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/models/attendance_model.dart';
import 'package:attendance_app/models/user_model.dart';
import 'package:attendance_app/services/attendance_service.dart';
import 'package:attendance_app/services/auth_service.dart';
import 'package:attendance_app/ui/attend/attend_screen.dart';
import 'package:attendance_app/ui/absent/absent_screen.dart';
import 'package:attendance_app/ui/attendance_history/history_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel? currentUser;

  const HomeScreen({super.key, this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ==========================================
  // 1. DESIGN TOKENS (Style Guide & Details)
  // ==========================================
  static const Color _canvasBg = Color(0xFFF2F4F7);
  static const Color _cardSurface = Color(0xFFFFFFFF);
  static const Color _cobalt500 = Color(0xFF2952F2);
  static const Color _cobalt700 = Color(0xFF1A36A6);
  static const Color _cobalt50 = Color(0xFFE8EEFF);
  static const Color _inkText = Color(0xFF0E1A2B);
  static const Color _slateText = Color(0xFF5B6474);
  static const Color _successGreen = Color(0xFF12B76A);
  static const Color _warningOrange = Color(0xFFF79009);
  static const Color _errorRed = Color(0xFFD92D20);

  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();
  late final Stream<List<AttendanceModel>> _historyStream;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  UserModel? _userProfile;

  UserModel get _effectiveUser =>
      widget.currentUser ??
      _userProfile ??
      const UserModel(
        uid: 'demo_student_uid',
        email: AuthService.studentDemoEmail,
        name: 'Sahl Savasci',
        nis: '202411001',
        role: 'student',
        userClass: 'XI RPL',
      );

  @override
  void initState() {
    super.initState();
    _userProfile = widget.currentUser;
    if (_userProfile == null) {
      _loadUserProfile();
    }
    _historyStream = _attendanceService.streamAttendanceHistory();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  Future<void> _loadUserProfile() async {
    final loaded = await _authService.getCurrentUserProfile();
    if (mounted && loaded != null) {
      setState(() => _userProfile = loaded);
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
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

  String _getGreeting() {
    final hour = _now.hour;
    if (hour >= 4 && hour < 11) {
      return 'Selamat Pagi,';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang,';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore,';
    } else {
      return 'Selamat Malam,';
    }
  }

  String _getFormattedTime() {
    return '${DateFormat('HH:mm:ss').format(_now)} WIB';
  }

  _ShiftStatusInfo _getShiftStatus() {
    final h = _now.hour;
    final m = _now.minute;

    if (h < 8 || (h == 8 && m <= 30)) {
      return _ShiftStatusInfo(
        label: 'Tepat Waktu',
        dotColor: _successGreen,
        bgTint: _successGreen.withValues(alpha: 0.12),
        textColor: const Color(0xFF067647),
      );
    } else if ((h > 8 && h < 18) || (h == 8 && m >= 31)) {
      return _ShiftStatusInfo(
        label: 'Terlambat',
        dotColor: _warningOrange,
        bgTint: _warningOrange.withValues(alpha: 0.14),
        textColor: const Color(0xFFB54708),
      );
    } else {
      return _ShiftStatusInfo(
        label: 'Di Luar Jam',
        dotColor: _errorRed,
        bgTint: _errorRed.withValues(alpha: 0.12),
        textColor: _errorRed,
      );
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showStudentBadgeSheet() {
    final user = _effectiveUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lanyard Strap (Matching Image 6: Employee/Student Badge)
                Container(
                  width: 34,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: _cobalt500,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  alignment: Alignment.center,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      'IDN SOLO',
                      style: _manrope(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 48,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D5DD),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Main Lanyard Badge Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _cardSurface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: _cobalt50, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _inkText.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _cobalt500,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SMK IDN Boarding School',
                            style: _manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _inkText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_cobalt500, _cobalt700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: _cobalt50, width: 3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'S',
                          style: _manrope(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.name,
                        textAlign: TextAlign.center,
                        style: _manrope(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: _inkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.isTeacher
                            ? 'Wali Kelas / Guru Pembimbing'
                            : 'Peserta Didik Aktif',
                        style: _manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _slateText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _cobalt50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.userClass,
                          style: _manrope(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: _cobalt500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _canvasBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.isTeacher ? 'NIP / ID Guru' : 'Nomor Induk Siswa',
                                  style: _manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _slateText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.nis,
                                  style: _manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _inkText,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _cobalt50),
                              ),
                              child: const Icon(
                                Icons.qr_code_2_rounded,
                                size: 28,
                                color: _inkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                Navigator.pop(sheetContext);
                                await _authService.signOut();
                              },
                              icon: const Icon(Icons.logout_rounded, size: 17),
                              label: Text(
                                'Keluar Akun',
                                style: _manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _errorRed,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _errorRed,
                                side: BorderSide(
                                  color: _errorRed.withValues(alpha: 0.35),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _cobalt500,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Tutup Kartu',
                                style: _manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAttendanceRulesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: _cobalt50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: _cobalt500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aturan Presensi XI RPL',
                            style: _manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _inkText,
                            ),
                          ),
                          Text(
                            'SMK IDN Boarding School Solo',
                            style: _manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _slateText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildRuleItem(
                  icon: Icons.schedule_outlined,
                  title: 'Batas Jam Kehadiran (08:30 WIB)',
                  subtitle:
                      'Check-in sebelum 08:30 WIB tercatat Tepat Waktu. Pukul 08:31–17:59 WIB tercatat Terlambat.',
                ),
                const SizedBox(height: 14),
                _buildRuleItem(
                  icon: Icons.my_location_outlined,
                  title: 'Radius Geofencing 100 Meter',
                  subtitle:
                      'Wajib berada di dalam area SMK IDN Solo (maksimal 100m dari titik sekolah) dan mengambil selfie.',
                ),
                const SizedBox(height: 14),
                _buildRuleItem(
                  icon: Icons.lock_person_outlined,
                  title: 'Identity Locking & Verifikasi Wali Kelas',
                  subtitle:
                      'Setiap presensi dikunci ke NIS pengguna yang login. Perubahan/penghapusan data hanya diizinkan untuk Wali Kelas.',
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cobalt500,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Mengerti',
                      style: _manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRuleItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: _cobalt50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: _cobalt700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: _manrope(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _inkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: _manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _slateText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvasBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopHeader(),
                  const SizedBox(height: 22),
                  _buildHeroShiftCard(),
                  const SizedBox(height: 16),
                  _buildSecondaryBentoGrid(),
                  const SizedBox(height: 16),
                  _buildQuickMetricSummaryCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // A. Top Header (Menampilkan Nama, NIS & Kelas dari UserModel)
  // ==========================================
  Widget _buildTopHeader() {
    final user = _effectiveUser;

    return Row(
      children: [
        GestureDetector(
          onTap: _showStudentBadgeSheet,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_cobalt500, _cobalt700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _cobalt50, width: 2),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _showStudentBadgeSheet,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()} ${user.userClass} • ${user.nis}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _slateText,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _inkText,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _cobalt50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.isTeacher ? 'GURU' : 'SISWA',
                        style: _manrope(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: _cobalt500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _cardSurface,
            shape: BoxShape.circle,
            border: Border.all(color: _cobalt50, width: 1.2),
          ),
          child: IconButton(
            tooltip: 'Kartu Identitas & Keluar',
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.badge_outlined,
              size: 19,
              color: _cobalt500,
            ),
            onPressed: _showStudentBadgeSheet,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _cardSurface,
            shape: BoxShape.circle,
            border: Border.all(color: _cobalt50, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _inkText.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(
            tooltip: 'Aturan Presensi',
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.info_outline_rounded,
              size: 19,
              color: _inkText,
            ),
            onPressed: _showAttendanceRulesSheet,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // B. The Hero Shift Card ("One Card for the Day")
  // ==========================================
  Widget _buildHeroShiftCard() {
    final shiftStatus = _getShiftStatus();

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF9BDCFF).withValues(alpha: 0.15),
                const Color(0xFFA6F3E4).withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.85),
              ],
            ),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Status Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: shiftStatus.bgTint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: shiftStatus.dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          shiftStatus.label,
                          style: _manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: shiftStatus.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _cardSurface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _cobalt50, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: _slateText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'SMK IDN Solo',
                          style: _manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _slateText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 2. Schedule Label
              Text(
                'Batas Tepat Waktu • 08:30 WIB',
                style: _manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _slateText,
                ),
              ),

              const SizedBox(height: 6),

              // 3. Realtime Digital Clock
              Text(
                _getFormattedTime(),
                style: _manrope(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: _inkText,
                  letterSpacing: -0.8,
                  height: 1.15,
                ),
              ),

              const SizedBox(height: 20),

              // 4. Primary "1-Tap" Check-in Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _navigateTo(
                    AttendScreen(currentUser: _effectiveUser),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cobalt500,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'Check In Kehadiran Sekarang',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _manrope(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.camera_alt_outlined, size: 19),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // C. Secondary Bento Grid (2-Column Row)
  // ==========================================
  Widget _buildSecondaryBentoGrid() {
    return Row(
      children: [
        Expanded(
          child: _BentoActionCard(
            icon: Icons.calendar_today_outlined,
            title: 'Izin / Sakit',
            subtitle: 'Dispensasi & surat sakit',
            onTap: () => _navigateTo(
              AbsentScreen(currentUser: _effectiveUser),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _BentoActionCard(
            icon: Icons.history_rounded,
            title: 'Riwayat Kelas',
            subtitle: 'Log presensi & unduh CSV',
            onTap: () => _navigateTo(
              AttendanceHistoryScreen(currentUser: _effectiveUser),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // D. Quick Metric Summary Card
  // ==========================================
  Widget _buildQuickMetricSummaryCard() {
    return StreamBuilder<List<AttendanceModel>>(
      stream: _historyStream,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AttendanceModel>[];
        final currentMonthItems = items
            .where((item) =>
                item.createdAt.year == _now.year &&
                item.createdAt.month == _now.month)
            .toList();

        final bool hasStreamData = currentMonthItems.isNotEmpty;
        int totalHadir = 20;
        int tepatWaktu = 18;
        int terlambatAtauIzin = 2;

        if (hasStreamData) {
          tepatWaktu = currentMonthItems.where((item) {
            final d = item.description.toLowerCase();
            return item.type != 'permission' &&
                (d.contains('attend') ||
                    d.contains('tepat') ||
                    d.contains('hadir'));
          }).length;

          terlambatAtauIzin = currentMonthItems.length - tepatWaktu;
          totalHadir = currentMonthItems
              .where((item) => item.type != 'permission')
              .length;
        }

        final double progressRatio = (totalHadir + terlambatAtauIzin) > 0
            ? (tepatWaktu / (totalHadir + terlambatAtauIzin)).clamp(0.15, 1.0)
            : 0.9;

        return Material(
          color: _cardSurface,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () => _navigateTo(
              AttendanceHistoryScreen(currentUser: _effectiveUser),
            ),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _cobalt50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🔥 Kehadiran Bulan Ini',
                          style: _manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _inkText,
                          ),
                        ),
                      ),
                      Text(
                        '$tepatWaktu / ${totalHadir > 0 ? totalHadir : 20}',
                        style: _manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _inkText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressRatio,
                      minHeight: 6,
                      backgroundColor: _cobalt50,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_cobalt500),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '$totalHadir Hari Hadir',
                        style: _manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _inkText,
                        ),
                      ),
                      Text(
                        '•',
                        style: _manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _slateText,
                        ),
                      ),
                      Text(
                        '$tepatWaktu Tepat Waktu',
                        style: _manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _successGreen,
                        ),
                      ),
                      Text(
                        '•',
                        style: _manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _slateText,
                        ),
                      ),
                      Text(
                        '$terlambatAtauIzin Terlambat / Izin',
                        style: _manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _slateText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShiftStatusInfo {
  final String label;
  final Color dotColor;
  final Color bgTint;
  final Color textColor;

  const _ShiftStatusInfo({
    required this.label,
    required this.dotColor,
    required this.bgTint,
    required this.textColor,
  });
}

class _BentoActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BentoActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8EEFF), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0E1A2B).withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8EEFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF2952F2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0E1A2B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5B6474),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
