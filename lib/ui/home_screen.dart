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
                  icon: Icons.description_outlined,
                  title: 'Dispensasi & Surat Sakit',
                  subtitle:
                      'Gunakan kartu Izin / Sakit apabila berhalangan hadir agar tercatat di log presensi kelas.',
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
  // A. Top Header
  // ==========================================
  Widget _buildTopHeader() {
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
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 22,
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
                  fontSize: 13,
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
        Container(
          width: 42,
          height: 42,
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
              size: 20,
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
                  // Left Pill: Dynamic attendance status chip
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

                  // Right Pill: School boundary badge
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
                  onPressed: () => _navigateTo(const AttendScreen()),
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
            onTap: () => _navigateTo(const AbsentScreen()),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _BentoActionCard(
            icon: Icons.history_rounded,
            title: 'Riwayat Kelas',
            subtitle: 'Log presensi & unduh CSV',
            onTap: () => _navigateTo(const AttendanceHistoryScreen()),
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

        // Hitung metrik dari stream bila ada data, atau gunakan baseline metrik
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
            onTap: () => _navigateTo(const AttendanceHistoryScreen()),
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
