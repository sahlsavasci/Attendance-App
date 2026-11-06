import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';

class AbsentScreen extends StatefulWidget {
  final UserModel? currentUser;

  const AbsentScreen({super.key, this.currentUser});

  @override
  State<AbsentScreen> createState() => _AbsentScreenState();
}

class _AbsentScreenState extends State<AbsentScreen> {
  // ==========================================
  // 1. DESIGN SPECIFICATIONS & TOKENS (Style Guide)
  // ==========================================
  static const Color _canvasBg = Color(0xFFF2F4F7);
  static const Color _surfaceCard = Color(0xFFFFFFFF);
  static const Color _cobalt500 = Color(0xFF2952F2);
  static const Color _cobalt700 = Color(0xFF1A36A6);
  static const Color _cobalt50 = Color(0xFFE8EEFF);
  static const Color _inkText = Color(0xFF0E1A2B);
  static const Color _slateText = Color(0xFF5B6474);
  static const Color _successGreen = Color(0xFF12B76A);
  static const Color _warningPending = Color(0xFFF79009);
  static const Color _errorRed = Color(0xFFD92D20);

  static const List<_LeaveTypeOption> _leaveOptions = [
    _LeaveTypeOption(
      value: 'Sakit',
      title: 'Sakit',
      badge: 'Sick Leave',
      subtitle: 'Istirahat dokter / asrama',
      icon: Icons.medical_services_outlined,
    ),
    _LeaveTypeOption(
      value: 'Izin Pulang',
      title: 'Izin Pulang',
      badge: 'Family / Personal',
      subtitle: 'Kepentingan keluarga / tiket',
      icon: Icons.luggage_outlined,
    ),
    _LeaveTypeOption(
      value: 'Dispensasi',
      title: 'Dispensasi',
      badge: 'School Duty',
      subtitle: 'Lomba / tugas sekolah',
      icon: Icons.emoji_events_outlined,
    ),
  ];

  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();
  final TextEditingController _reasonController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  UserModel? _currentUser;
  String _selectedLeaveType = 'Sakit';
  late DateTime _startDate;
  late DateTime _endDate;

  XFile? _attachmentFile;
  Uint8List? _attachmentBytes;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day);

    _currentUser = widget.currentUser;
    _loadUserProfile();
    _reasonController.addListener(_onReasonChanged);
  }

  void _onReasonChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getCurrentUserProfile();
    if (mounted && profile != null) {
      setState(() => _currentUser = profile);
    }
  }

  UserModel get _effectiveUser =>
      _currentUser ??
      widget.currentUser ??
      const UserModel(
        uid: 'demo_student_uid',
        email: AuthService.studentDemoEmail,
        name: 'Sahl Savasci',
        nis: '202411001',
        role: 'student',
        userClass: 'XI RPL',
      );

  @override
  void dispose() {
    _reasonController.removeListener(_onReasonChanged);
    _reasonController.dispose();
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

  List<BoxShadow> get _bentoShadow => [
        BoxShadow(
          color: _inkText.withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  int get _calculatedDurationDays {
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
    final diff = end.difference(start).inDays + 1;
    return diff < 1 ? 1 : diff;
  }

  String _formatIndonesianDate(DateTime date) {
    try {
      return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('EEE, d MMM yyyy').format(date);
    }
  }

  // ==========================================
  // DATE PICKERS
  // ==========================================
  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: 'PILIH DARI TANGGAL',
      builder: _buildDatePickerTheme,
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
      helpText: 'PILIH SAMPAI TANGGAL',
      builder: _buildDatePickerTheme,
    );
    if (picked != null && mounted) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      helpText: 'PILIH RENTANG TANGGAL IZIN',
      builder: _buildDatePickerTheme,
    );
    if (pickedRange != null && mounted) {
      setState(() {
        _startDate = DateTime(
          pickedRange.start.year,
          pickedRange.start.month,
          pickedRange.start.day,
        );
        _endDate = DateTime(
          pickedRange.end.year,
          pickedRange.end.month,
          pickedRange.end.day,
        );
      });
    }
  }

  Widget _buildDatePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: _cobalt500,
          onPrimary: Colors.white,
          surface: _surfaceCard,
          onSurface: _inkText,
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  // ==========================================
  // ATTACHMENT UPLOADER (SURAT DOKTER / BUKTI)
  // ==========================================
  Future<void> _handleAttachmentTap() async {
    if (kIsWeb) {
      await _pickAttachment(ImageSource.gallery);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                const SizedBox(height: 16),
                Text(
                  'Lampirkan Foto Bukti / Surat',
                  style: _manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _inkText,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: _cobalt50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: _cobalt500,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Ambil Foto Kamera',
                    style: _manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _inkText,
                    ),
                  ),
                  subtitle: Text(
                    'Potret langsung surat dokter atau surat tugas',
                    style: _manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _slateText,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAttachment(ImageSource.camera);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: _cobalt50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: _cobalt500,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Pilih dari Galeri / File',
                    style: _manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _inkText,
                    ),
                  ),
                  subtitle: Text(
                    'Unggah gambar surat keterangan dari perangkat',
                    style: _manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _slateText,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAttachment(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAttachment(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1440,
        maxHeight: 1440,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _attachmentFile = picked;
        _attachmentBytes = bytes;
      });
    } catch (e) {
      _showSnackBar(
        'Tidak dapat memuat lampiran gambar: $e',
        isError: true,
      );
    }
  }

  void _clearAttachment() {
    setState(() {
      _attachmentFile = null;
      _attachmentBytes = null;
    });
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

  // ==========================================
  // SUBMISSION & CONFIRMATION BOTTOM SHEET
  // ==========================================
  Future<void> _submitLeaveRequest() async {
    if (_isSubmitting) return;

    final reasonText = _reasonController.text.trim();
    setState(() => _isSubmitting = true);

    try {
      final user = await _authService.getCurrentUserProfile() ?? _effectiveUser;
      final now = DateTime.now();

      final startStr = DateFormat('dd/MM/yyyy').format(_startDate);
      final endStr = DateFormat('dd/MM/yyyy').format(_endDate);
      final dateRangeLabel = startStr == endStr
          ? '$startStr (1 Hari)'
          : '$startStr - $endStr ($_calculatedDurationDays Hari)';
      final submittedAtStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      final formattedReason = [
        if (reasonText.isNotEmpty) reasonText,
        if (_attachmentFile != null) '[Lampiran: ${_attachmentFile!.name}]',
      ].join(' ');

      final permission = AttendanceModel(
        id: '',
        userId: user.uid,
        name: user.name,
        nis: user.nis,
        studentClass: user.userClass,
        description: _selectedLeaveType,
        address: 'SMK IDN Boarding School Solo',
        datetime: '$dateRangeLabel • $submittedAtStr',
        reason: formattedReason.isNotEmpty
            ? formattedReason
            : 'Pengajuan $_selectedLeaveType ($dateRangeLabel)',
        type: 'permission',
        approvalStatus: 'pending',
        createdAt: now,
      );

      await _attendanceService.submitPermission(permission);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      await _showConfirmationBottomSheet();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar('Gagal mengirim pengajuan izin: $e', isError: true);
    }
  }

  Future<void> _showConfirmationBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: _surfaceCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _cobalt50, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: _inkText.withValues(alpha: 0.14),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Orange/Blue Clock Icon Badge
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _warningPending.withValues(alpha: 0.18),
                            _cobalt50,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.schedule_send_rounded,
                        color: _warningPending,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Pending Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _warningPending.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: _warningPending,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Status: Pending Approval',
                            style: _manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFB54708),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title: "Pengajuan Terkirim!"
                    Text(
                      'Pengajuan Terkirim!',
                      textAlign: TextAlign.center,
                      style: _manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _inkText,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    Text(
                      'Surat perizinan Anda berhasil dikirim ke Wali Kelas dan berstatus PENDING. Silakan cek status di menu Riwayat.',
                      textAlign: TextAlign.center,
                      style: _manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _slateText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Summary Mini Bento Tile
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _canvasBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _cobalt50),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kategori Izin',
                                style: _manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _slateText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedLeaveType,
                                style: _manrope(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: _inkText,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _cobalt50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Durasi: $_calculatedDurationDays Hari',
                              style: _manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _cobalt500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Button: "Kembali ke Beranda"
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(modalContext).pop();
                          if (mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cobalt500,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Kembali ke Beranda',
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
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // PAGE COMPOSITION & BUILDER
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final user = _effectiveUser;

    return Scaffold(
      backgroundColor: _canvasBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A. Header Bar
                  _buildHeaderBar(),
                  const SizedBox(height: 20),

                  // B. Student Profile Capsule (Read-Only)
                  _buildStudentProfileCapsule(user),
                  const SizedBox(height: 18),

                  // C. Leave Type Selector (Selectable Bento Tiles)
                  _buildLeaveTypeSelectorCard(),
                  const SizedBox(height: 16),

                  // D. Date Range Bento Card
                  _buildDateRangeBentoCard(),
                  const SizedBox(height: 16),

                  // E. Reason & Attachment Section
                  _buildReasonAndAttachmentCard(),
                  const SizedBox(height: 24),

                  // F. Primary Submit Button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // A. HEADER BAR
  // ==========================================
  Widget _buildHeaderBar() {
    return Row(
      children: [
        // Back button wrapped in a rounded white tile
        Material(
          color: _surfaceCard,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cobalt50, width: 1.2),
                boxShadow: _bentoShadow,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: _inkText,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pengajuan Izin',
                style: _manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _inkText,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SMK IDN Boarding School Solo',
                style: _manrope(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _slateText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // B. STUDENT PROFILE CAPSULE (READ-ONLY)
  // ==========================================
  Widget _buildStudentProfileCapsule(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cobalt50, width: 1.2),
        boxShadow: _bentoShadow,
      ),
      child: Row(
        children: [
          // Left: Circular student avatar / icon badge
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
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
              style: _manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Middle: Student's real name + NIS & Class
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _manrope(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _inkText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'NIS: ${user.nis} • ${user.userClass}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _slateText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right: Subtle blue chip "Siswa Aktif"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _cobalt50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Siswa Aktif',
                  style: _manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _cobalt500,
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
  // C. LEAVE TYPE SELECTOR (SELECTABLE BENTO TILES)
  // ==========================================
  Widget _buildLeaveTypeSelectorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cobalt50, width: 1.2),
        boxShadow: _bentoShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jenis Perizinan',
                style: _manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _inkText,
                ),
              ),
              Text(
                'Pilih 1 kategori',
                style: _manrope(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _slateText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(_leaveOptions.length, (index) {
            final option = _leaveOptions[index];
            final isSelected = _selectedLeaveType == option.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _leaveOptions.length - 1 ? 0 : 10,
              ),
              child: _buildSelectableLeaveTile(
                option: option,
                isSelected: isSelected,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSelectableLeaveTile({
    required _LeaveTypeOption option,
    required bool isSelected,
  }) {
    return Material(
      color: isSelected
          ? _cobalt50.withValues(alpha: 0.55)
          : _surfaceCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => setState(() => _selectedLeaveType = option.value),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? _cobalt500 : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? _cobalt500 : _cobalt50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  option.icon,
                  size: 22,
                  color: isSelected ? Colors.white : _cobalt500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          option.title,
                          style: _manrope(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: _inkText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.85)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            option.badge,
                            style: _manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? _cobalt500 : _slateText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      option.subtitle,
                      style: _manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _slateText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Solid blue checkmark indicator when active
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? _cobalt500 : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? _cobalt500 : const Color(0xFFCBD5E1),
                    width: 1.8,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // D. DATE RANGE BENTO CARD (IMAGE 6)
  // ==========================================
  Widget _buildDateRangeBentoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cobalt50, width: 1.2),
        boxShadow: _bentoShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rentang Tanggal Izin',
                style: _manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _inkText,
                ),
              ),
              // Calculated Duration Pill Badge: "Durasi: [X] Hari"
              InkWell(
                onTap: _pickDateRange,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _cobalt50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.date_range_rounded,
                        size: 13,
                        color: _cobalt500,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Durasi: $_calculatedDurationDays Hari',
                        style: _manrope(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _cobalt500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Two Clickable Segmented Boxes: "Dari Tanggal" & "Sampai Tanggal"
          Row(
            children: [
              Expanded(
                child: _buildDateSegmentBox(
                  label: 'Dari Tanggal',
                  formattedDate: _formatIndonesianDate(_startDate),
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickStartDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDateSegmentBox(
                  label: 'Sampai Tanggal',
                  formattedDate: _formatIndonesianDate(_endDate),
                  icon: Icons.event_available_outlined,
                  onTap: _pickEndDate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSegmentBox({
    required String label,
    required String formattedDate,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cobalt50, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: _cobalt500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _slateText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formattedDate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _inkText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // E. REASON & ATTACHMENT SECTION (IMAGE 6)
  // ==========================================
  Widget _buildReasonAndAttachmentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cobalt50, width: 1.2),
        boxShadow: _bentoShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Reason Input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alasan / Keterangan Tambahan',
                style: _manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _inkText,
                ),
              ),
              Text(
                '${_reasonController.text.length}/200',
                style: _manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _slateText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            minLines: 3,
            maxLength: 200,
            style: _manrope(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _inkText,
              height: 1.45,
            ),
            decoration: InputDecoration(
              counterText: '',
              labelText: 'Alasan / Keterangan Tambahan',
              alignLabelWithHint: true,
              hintText: 'Tuliskan alasan jelas izin atau diagnosa dokter...',
              hintStyle: _manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _slateText.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _cobalt50, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _cobalt50, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _cobalt500, width: 1.6),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 2. Attachment Uploader (Surat Dokter / Bukti)
          Text(
            'Lampiran Surat / Bukti Pendukung',
            style: _manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _inkText,
            ),
          ),
          const SizedBox(height: 8),
          if (_attachmentFile != null)
            _buildAttachmentPreviewTile()
          else
            _buildAttachmentUploaderBox(),
        ],
      ),
    );
  }

  Widget _buildAttachmentUploaderBox() {
    return DottedBorder(
      color: _cobalt500.withValues(alpha: 0.45),
      strokeWidth: 1.5,
      dashPattern: const [6, 5],
      borderType: BorderType.RRect,
      radius: const Radius.circular(16),
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _handleAttachmentTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: _cobalt50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.attach_file_rounded,
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
                        'Lampirkan Foto Bukti / Surat (Opsional)',
                        style: _manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _cobalt500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Surat keterangan dokter, tiket, atau dispensasi lomba',
                        style: _manrope(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: _slateText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.camera_alt_outlined,
                  color: _cobalt500,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentPreviewTile() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cobalt50, width: 1.4),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 58,
              height: 58,
              child: _attachmentBytes != null
                  ? Image.memory(
                      _attachmentBytes!,
                      fit: BoxFit.cover,
                    )
                  : (kIsWeb && _attachmentFile != null
                      ? Image.network(
                          _attachmentFile!.path,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: _cobalt50,
                          child: const Icon(
                            Icons.image_outlined,
                            color: _cobalt500,
                          ),
                        )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _attachmentFile?.name ?? 'lampiran_surat.jpg',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _inkText,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: _successGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bukti foto siap dilampirkan',
                      style: _manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _successGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hapus Lampiran',
            onPressed: _clearAttachment,
            icon: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _errorRed.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: _errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // F. PRIMARY SUBMIT BUTTON
  // ==========================================
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitLeaveRequest,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded, size: 18),
        label: Text(
          _isSubmitting ? 'Mengirim Pengajuan...' : 'Kirim Pengajuan Izin',
          style: _manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _cobalt500,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _cobalt500.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _LeaveTypeOption {
  final String value;
  final String title;
  final String badge;
  final String subtitle;
  final IconData icon;

  const _LeaveTypeOption({
    required this.value,
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.icon,
  });
}
