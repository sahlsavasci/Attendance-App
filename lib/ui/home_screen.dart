import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/models/attendance_model.dart';
import 'package:attendance_app/services/attendance_service.dart';
import 'package:attendance_app/ui/attend/attend_screen.dart';
import 'package:attendance_app/ui/absent/absent_screen.dart';
import 'package:attendance_app/ui/attendance_history/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ==========================================
  // Design System Tokens: Orbit Work - Bento Minimal
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
  static const Color _auroraSky = Color(0xFF9BDCFF);
  static const Color _auroraMint = Color(0xFFA6F3E4);

  final AttendanceService _attendanceService = AttendanceService();
  late final Stream<List<AttendanceModel>> _historyStream;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _historyStream = _attendanceService.streamAttendanceHistory();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
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

  String _getFormattedDate() {
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_now);
    } catch (_) {
      return DateFormat('EEEE, d MMMM yyyy').format(_now);
    }
  }

  String _getFormattedTime() {
    return DateFormat('HH:mm:ss').format(_now);
  }

  _ShiftStatusInfo _getShiftStatus() {
    final h = _now.hour;
    final m = _now.minute;

    if (h < 8 || (h == 8 && m <= 30)) {
      return const _ShiftStatusInfo(
        label: 'Tepat Waktu',
        dotColor: _successGreen,
        bgTint: _cobalt50,
        textColor: _inkText,
        caption: 'Sesi presensi pagi aktif • Hadir sebelum 08:30 WIB',
      );
    } else if ((h > 8 && h < 18) || (h == 8 && m >= 31)) {
      return _ShiftStatusInfo(
        label: 'Terlambat',
        dotColor: _warningOrange,
        bgTint: _warningOrange.withValues(alpha: 0.12),
        textColor: const Color(0xFFB54708),
        caption: 'Melewati pukul 08:30 WIB • Tercatat sebagai terlambat',
      );
    } else {
      return _ShiftStatusInfo(
        label: 'Di Luar Jam',
        dotColor: _errorRed,
        bgTint: _errorRed.withValues(alpha: 0.10),
        textColor: _errorRed,
        caption: 'Jam sekolah berakhir (08:30 – 18:00 WIB)',
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _cobalt50,
                        borderRadius: BorderRadius.circular(12),
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
                _buildRuleRow(
                  icon: Icons.schedule_outlined,
                  title: 'Batas Jam Kehadiran',
                  subtitle:
                      'Check-in sebelum 08:30 WIB tercatat Tepat Waktu (Attend). Pukul 08:31–17:59 WIB tercatat Terlambat (Late).',
                ),
                const SizedBox(height: 14),
                _buildRuleRow(
                  icon: Icons.my_location_outlined,
                  title: 'Radius Geofencing 100 Meter',
                  subtitle:
                      'Wajib berada di dalam area SMK IDN Solo (maksimal 100m dari titik sekolah) dan melampirkan foto selfie.',
                ),
                const SizedBox(height: 14),
                _buildRuleRow(
                  icon: Icons.event_note_outlined,
                  title: 'Izin & Sakit',
                  subtitle:
                      'Gunakan kartu Izin / Sakit apabila berhalangan hadir agar tercatat di log kelas.',
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
                        borderRadius: BorderRadius.circular(14),
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

  Widget _buildRuleRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _canvasBg,
            borderRadius: BorderRadius.circular(10),
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
                  _buildHeaderBar(),
                  const SizedBox(height: 22),
                  _buildHeroShiftCard(),
                  const SizedBox(height: 16),
                  _buildSecondaryBentoGrid(),
                  const SizedBox(height: 16),
                  _buildTodayQuickStatusCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // A. Header Bar (Clean & Lightweight)
  // ==========================================
  Widget _buildHeaderBar() {
    return Row(
      children: [
        Container(
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
          child: Text(
            'XI',
            style: _manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: _manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _slateText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Peserta Didik XI RPL',
                style: _manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _inkText,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: _cardSurface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _showAttendanceRulesSheet,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cobalt50, width: 1.2),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: _inkText,
              ),
            ),
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
              colors: [
                _auroraSky.withValues(alpha: 0.12),
                _cardSurface,
                _auroraMint.withValues(alpha: 0.08),
              ],
              stops: const [0.0, 0.55, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
                  // Left Pill: Dynamic attendance status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: shiftStatus.bgTint,
                      borderRadius: BorderRadius.circular(14),
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

                  // Right Pill: Location badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _cardSurface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
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

              // 2. Schedule Caption
              Text(
                'Batas Tepat Waktu • 08:30 WIB',
                style: _manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _slateText,
                ),
              ),

              const SizedBox(height: 6),

              // 3. Massive Realtime Digital Clock
              Text(
                _getFormattedTime(),
                style: _manrope(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: _inkText,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                shiftStatus.caption,
                style: _manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _slateText,
                ),
              ),

              const SizedBox(height: 20),

              // 4. Primary "1-Tap" Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _navigateTo(const AttendScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cobalt500,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 19),
                      const SizedBox(width: 10),
                      Text(
                        'Check In Kehadiran Sekarang',
                        style: _manrope(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
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
  // C. Secondary Bento Grid (Balanced 2-Column Row)
  // ==========================================
  Widget _buildSecondaryBentoGrid() {
    return Row(
      children: [
        Expanded(
          child: _BentoActionCard(
            icon: Icons.edit_calendar_outlined,
            title: 'Izin / Sakit',
            subtitle: 'Dispensasi & surat sakit',
            onTap: () => _navigateTo(const AbsentScreen()),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _BentoActionCard(
            icon: Icons.bar_chart_rounded,
            title: 'Riwayat Kelas',
            subtitle: 'Log & ekspor CSV',
            onTap: () => _navigateTo(const AttendanceHistoryScreen()),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // D. Today's Quick Status (Compact Card)
  // ==========================================
  Widget _buildTodayQuickStatusCard() {
    return StreamBuilder<List<AttendanceModel>>(
      stream: _historyStream,
      builder: (context, snapshot) {
        final allItems = snapshot.data ?? const <AttendanceModel>[];
        final todayItems = allItems
            .where((item) => _isSameDay(item.createdAt, _now))
            .toList();
        final hasSubmittedToday = todayItems.isNotEmpty;
        final latestToday = hasSubmittedToday ? todayItems.first : null;

        final Color badgeBg = hasSubmittedToday
            ? _successGreen.withValues(alpha: 0.12)
            : _cobalt50;
        final Color badgeIconColor =
            hasSubmittedToday ? _successGreen : _cobalt500;
        final String statusMessage = hasSubmittedToday
            ? 'Tercatat hari ini: ${latestToday!.name} (${latestToday.description})'
            : 'Hari ini belum ada catatan presensi';

        return Material(
          color: _cardSurface,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () => _navigateTo(const AttendanceHistoryScreen()),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasSubmittedToday
                          ? Icons.check_circle_outline_rounded
                          : Icons.event_available_outlined,
                      size: 20,
                      color: badgeIconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFormattedDate(),
                          style: _manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _slateText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _manrope(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _inkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: _slateText,
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
  final String caption;

  const _ShiftStatusInfo({
    required this.label,
    required this.dotColor,
    required this.bgTint,
    required this.textColor,
    required this.caption,
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
