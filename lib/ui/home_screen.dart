import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/ui/attend/attend_screen.dart';
import 'package:attendance_app/ui/absent/absent_screen.dart';
import 'package:attendance_app/ui/attendance_history/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _navy = Color(0xFF1E2B58);
  static const _royalBlue = Color(0xFF2563EB);

  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
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

  String _getGreeting() {
    final hour = _now.hour;
    if (hour >= 4 && hour < 11) {
      return 'Selamat Pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
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

  String _getCurrentStatusCode() {
    final h = _now.hour;
    final m = _now.minute;
    if (h < 8 || (h == 8 && m <= 30)) {
      return 'Attend';
    } else if ((h > 8 && h < 18) || (h == 8 && m >= 31)) {
      return 'Late';
    } else {
      return 'Leave';
    }
  }

  String _getCurrentStatusLabel(String code) {
    switch (code) {
      case 'Attend':
        return 'Sesi Tepat Waktu (Attend)';
      case 'Late':
        return 'Melewati 08:30 (Late)';
      default:
        return 'Di Luar Jam Operasional (Leave)';
    }
  }

  Color _getCurrentStatusColor(String code) {
    switch (code) {
      case 'Attend':
        return const Color(0xFF047857);
      case 'Late':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFFB91C1C);
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showSystemInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.school, color: _navy),
            SizedBox(width: 8),
            Text(
              'IDN Boarding School',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Sistem Presensi Digital Siswa XI RPL.\n'
          'Gunakan menu Presensi Kehadiran untuk check-in mandiri dan menu Izin & Sakit untuk pengajuan ketidakhadiran.',
          style: TextStyle(height: 1.4, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  List<_MenuActionItem> _buildMenuItems() {
    return [
      _MenuActionItem(
        title: 'Presensi Kehadiran',
        subtitle: 'Catat kehadiran hari ini beserta foto selfie, koordinat GPS & waktu',
        badgeText: 'Check-in',
        badgeColor: const Color(0xFF047857),
        icon: Icons.camera_alt_outlined,
        iconColor: _royalBlue,
        iconBg: const Color(0xFFEFF6FF),
        imageAsset: 'assets/images/ic_absen.png',
        onTap: () => _navigateTo(const AttendScreen()),
      ),
      _MenuActionItem(
        title: 'Pengajuan Izin & Sakit',
        subtitle: 'Formulir izin tidak hadir atau sakit untuk peserta didik',
        badgeText: 'Perizinan',
        badgeColor: const Color(0xFFB45309),
        icon: Icons.assignment_outlined,
        iconColor: const Color(0xFFD97706),
        iconBg: const Color(0xFFFEF3C7),
        imageAsset: 'assets/images/ic_leave.png',
        onTap: () => _navigateTo(const AbsentScreen()),
      ),
      _MenuActionItem(
        title: 'Riwayat Presensi',
        subtitle: 'Daftar catatan kehadiran real-time, pencarian & pengelolaan data',
        badgeText: 'Realtime',
        badgeColor: const Color(0xFF4338CA),
        icon: Icons.history,
        iconColor: const Color(0xFF4F46E5),
        iconBg: const Color(0xFFEEF2FF),
        imageAsset: 'assets/images/ic_history.png',
        onTap: () => _navigateTo(const AttendanceHistoryScreen()),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Presensi Digital XI RPL'),
        actions: [
          IconButton(
            tooltip: 'Informasi Sistem',
            icon: const Icon(Icons.info_outline, size: 22),
            onPressed: _showSystemInfoDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 768) {
              return _buildDesktopLayout();
            }
            return _buildMobileLayout();
          },
        ),
      ),
      bottomNavigationBar: Container(
        height: 52,
        decoration: const BoxDecoration(
          color: _navy,
          border: Border(
            top: BorderSide(color: Color(0xFF334155), width: 0.5),
          ),
        ),
        alignment: Alignment.center,
        child: const Text(
          'IDN Boarding School Solo • XI Rekayasa Perangkat Lunak',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE2E8F0),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. Layout Mobile (< 768px): Vertikal 1 Kolom
  // ==========================================
  Widget _buildMobileLayout() {
    final menuItems = _buildMenuItems();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          children: [
            _buildIdentityAndProfileBanner(),
            const SizedBox(height: 14),
            _buildLiveClockAndStatusCard(),
            const SizedBox(height: 14),
            _buildCompactMetricsCard(),
            const SizedBox(height: 24),
            const Text(
              'PILIHAN MENU UTAMA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < menuItems.length; i++) ...[
              _ModernMenuCard(item: menuItems[i], isGrid: false),
              if (i < menuItems.length - 1) const SizedBox(height: 14),
            ],
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. Layout Desktop/Tablet (>= 768px): Split Dashboard 2 Kolom
  // ==========================================
  Widget _buildDesktopLayout() {
    final menuItems = _buildMenuItems();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 28.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kolom Kiri: Sidebar / Status Panel
              SizedBox(
                width: 370,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIdentityAndProfileBanner(),
                    const SizedBox(height: 16),
                    _buildLiveClockAndStatusCard(),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              // Kolom Kanan: Card Metrik Ringkas + Action Grid 2 Kolom
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCompactMetricsCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'PILIHAN MENU UTAMA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: menuItems.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 175,
                      ),
                      itemBuilder: (context, index) {
                        return _ModernMenuCard(
                          item: menuItems[index],
                          isGrid: true,
                        );
                      },
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

  // ==========================================
  // Komponen Sidebar: Banner Identitas & Kartu Profil Siswa
  // ==========================================
  Widget _buildIdentityAndProfileBanner() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_outlined, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'IDN BOARDING SCHOOL SOLO',
                  style: TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Aktif',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getGreeting(),
            style: const TextStyle(
              color: Color(0xFF93C5FD),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Peserta Didik XI RPL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kompetensi Keahlian Rekayasa Perangkat Lunak',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Color(0xFFBFDBFE)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _getFormattedDate(),
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Komponen Sidebar: Live Clock Digital & Indikator Status Jam
  // ==========================================
  Widget _buildLiveClockAndStatusCard() {
    final statusCode = _getCurrentStatusCode();
    final statusLabel = _getCurrentStatusLabel(statusCode);
    final statusColor = _getCurrentStatusColor(statusCode);

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'WAKTU SERVER REALTIME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF475569),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  statusCode.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _getFormattedTime(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'WIB',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Card Metrik Ringkas (Hari/Tanggal, Batas 08:30 WIB, Instruksi Cepat)
  // ==========================================
  Widget _buildCompactMetricsCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, size: 18, color: _royalBlue),
              SizedBox(width: 8),
              Text(
                'RINGKASAN & PANDUAN PRESENSI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _MetricPill(
                icon: Icons.today_outlined,
                label: 'Hari & Tanggal Aktif',
                value: _getFormattedDate(),
              ),
              const _MetricPill(
                icon: Icons.access_time_filled,
                label: 'Batas Tepat Waktu',
                value: 'Sebelum 08:30 WIB (Lewat = Terlambat)',
              ),
              const _MetricPill(
                icon: Icons.verified_user_outlined,
                label: 'Instruksi Cepat',
                value: 'Ambil selfie + pastikan di dalam radius 100m sekolah',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1E2B58)),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuActionItem {
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String imageAsset;
  final VoidCallback onTap;

  const _MenuActionItem({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.imageAsset,
    required this.onTap,
  });
}

class _ModernMenuCard extends StatelessWidget {
  final _MenuActionItem item;
  final bool isGrid;

  const _ModernMenuCard({
    required this.item,
    required this.isGrid,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: isGrid ? _buildGridContent() : _buildRowContent(),
        ),
      ),
    );
  }

  Widget _buildRowContent() {
    return Row(
      children: [
        _buildIconBox(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  _buildBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Color(0xFF64748B),
        ),
      ],
    );
  }

  Widget _buildGridContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIconBox(),
            _buildBadge(),
          ],
        ),
        const Spacer(),
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF475569),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildIconBox() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: item.iconBg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(8),
      child: Image.asset(
        item.imageAsset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          item.icon,
          color: item.iconColor,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: item.badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: item.badgeColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        item.badgeText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: item.badgeColor,
        ),
      ),
    );
  }
}
