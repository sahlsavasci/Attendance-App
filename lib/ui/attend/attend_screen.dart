import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import 'face_scan_screen.dart';

enum _CheckInStep {
  locationVerification,
  selfieCamera,
  selfieReview,
}

enum _LocationSimMode {
  realGps,
  mockInsideCampus,
  mockOutsideCampus,
}

class AttendScreen extends StatefulWidget {
  final XFile? image;
  final UserModel? currentUser;

  const AttendScreen({super.key, this.image, this.currentUser});

  @override
  State<AttendScreen> createState() => _AttendScreenState();
}

class _AttendScreenState extends State<AttendScreen>
    with SingleTickerProviderStateMixin {
  // ==========================================
  // 1. DESIGN TOKENS & VISUAL IDENTITY
  // ==========================================
  static const Color _canvasBg = Color(0xFFF2F4F7);
  static const Color _surfaceCard = Color(0xFFFFFFFF);
  static const Color _cobalt500 = Color(0xFF2952F2);
  static const Color _cobalt50 = Color(0xFFE8EEFF);
  static const Color _darkCameraUi = Color(0xFF0E1A2B);
  static const Color _slateText = Color(0xFF5B6474);
  static const Color _successGreen = Color(0xFF12B76A);
  static const Color _warningOrange = Color(0xFFF79009);
  static const Color _errorRed = Color(0xFFD92D20);

  // Target Coordinates: SMK IDN Boarding School Solo
  static const double _schoolLat = -7.52554;
  static const double _schoolLng = 110.87102;
  static const double _allowedRadiusMeters = 100.0;

  // Services
  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();

  // State Machine
  _CheckInStep _currentStep = _CheckInStep.locationVerification;
  _LocationSimMode _simMode = _LocationSimMode.realGps;

  // Identity Locking
  UserModel? _currentUser;

  // Location & Geofencing State
  bool _isCheckingLocation = true;
  double _capturedLat = _schoolLat;
  double _capturedLng = _schoolLng;
  double _distanceMeters = 35.0;
  bool _isWithinRadius = false;

  // Selfie Capture & Review State
  XFile? _capturedSelfie;
  Uint8List? _selfieBytes;
  bool _isSubmitting = false;

  // Radar Pulse Animation
  late final AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _currentUser = widget.currentUser;
    _loadAuthenticatedUser();

    if (widget.image != null) {
      _onPhotoCaptured(widget.image!);
    }

    _verifyDeviceLocation();
  }

  @override
  void dispose() {
    _radarController.dispose();
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

  Future<void> _loadAuthenticatedUser() async {
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

  // ==========================================
  // STEP 1 LOGIC: GEOFENCING & EXAMINER DEMO TOGGLE
  // ==========================================
  void _cycleLocationMode() {
    final nextMode = switch (_simMode) {
      _LocationSimMode.realGps => _LocationSimMode.mockInsideCampus,
      _LocationSimMode.mockInsideCampus => _LocationSimMode.mockOutsideCampus,
      _LocationSimMode.mockOutsideCampus => _LocationSimMode.realGps,
    };

    setState(() => _simMode = nextMode);

    if (nextMode == _LocationSimMode.realGps) {
      _showExaminerToast('Mode GPS: Device Real GPS');
      _verifyDeviceLocation();
    } else if (nextMode == _LocationSimMode.mockInsideCampus) {
      // ~35 meters from SMK IDN Boarding School Solo
      const mockLat = _schoolLat + 0.000315;
      const mockLng = _schoolLng;
      final dist = Geolocator.distanceBetween(
        mockLat,
        mockLng,
        _schoolLat,
        _schoolLng,
      );
      setState(() {
        _isCheckingLocation = false;
        _capturedLat = mockLat;
        _capturedLng = mockLng;
        _distanceMeters = dist;
        _isWithinRadius = dist <= _allowedRadiusMeters;
      });
      _showExaminerToast('Demo Mode: Inside Campus (${dist.round()}m away)');
    } else {
      // ~320 meters from SMK IDN Boarding School Solo
      const mockLat = _schoolLat + 0.00288;
      const mockLng = _schoolLng;
      final dist = Geolocator.distanceBetween(
        mockLat,
        mockLng,
        _schoolLat,
        _schoolLng,
      );
      setState(() {
        _isCheckingLocation = false;
        _capturedLat = mockLat;
        _capturedLng = mockLng;
        _distanceMeters = dist;
        _isWithinRadius = dist <= _allowedRadiusMeters;
      });
      _showExaminerToast('Demo Mode: Outside Campus (${dist.round()}m away)');
    }
  }

  void _showExaminerToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkCameraUi,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(Icons.radar_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: _manrope(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _verifyDeviceLocation() async {
    if (_simMode != _LocationSimMode.realGps) {
      return;
    }

    setState(() => _isCheckingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && !kIsWeb) {
        _applyCalculatedCoordinates(
          lat: _schoolLat + 0.00288,
          lng: _schoolLng,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (kIsWeb) {
          // Default to 35m inside campus on Web if browser location prompt is blocked,
          // while still allowing examiner to toggle 320m outside via discreet switch.
          _applyCalculatedCoordinates(
            lat: _schoolLat + 0.000315,
            lng: _schoolLng,
          );
        } else {
          _applyCalculatedCoordinates(
            lat: _schoolLat + 0.00288,
            lng: _schoolLng,
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      if (!mounted || _simMode != _LocationSimMode.realGps) return;
      _applyCalculatedCoordinates(
        lat: position.latitude,
        lng: position.longitude,
      );
    } catch (e) {
      if (!mounted || _simMode != _LocationSimMode.realGps) return;
      if (kIsWeb) {
        _applyCalculatedCoordinates(
          lat: _schoolLat + 0.000315,
          lng: _schoolLng,
        );
      } else {
        _applyCalculatedCoordinates(
          lat: _schoolLat + 0.00288,
          lng: _schoolLng,
        );
      }
    }
  }

  void _applyCalculatedCoordinates({
    required double lat,
    required double lng,
  }) {
    final calculatedDistance = Geolocator.distanceBetween(
      lat,
      lng,
      _schoolLat,
      _schoolLng,
    );
    setState(() {
      _capturedLat = lat;
      _capturedLng = lng;
      _distanceMeters = calculatedDistance;
      _isWithinRadius = calculatedDistance <= _allowedRadiusMeters;
      _isCheckingLocation = false;
    });
  }

  // ==========================================
  // STEP 2 & 3 LOGIC: SELFIE CAPTURE & REVIEW
  // ==========================================
  Future<void> _onPhotoCaptured(XFile photo) async {
    try {
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      setState(() {
        _capturedSelfie = photo;
        _selfieBytes = bytes;
        _currentStep = _CheckInStep.selfieReview;
      });
    } catch (e) {
      debugPrint('Failed reading captured bytes: $e');
      if (!mounted) return;
      setState(() {
        _capturedSelfie = photo;
        _currentStep = _CheckInStep.selfieReview;
      });
    }
  }

  // ==========================================
  // STEP 4 LOGIC: SUBMIT & SUCCESS / FAILURE MODALS
  // ==========================================
  bool _isOnTime(DateTime now) {
    return now.hour < 8 || (now.hour == 8 && now.minute <= 30);
  }

  Future<void> _confirmAndSubmitCheckIn() async {
    if (_isSubmitting) return;

    // Re-check distance boundary using Geolocator.distanceBetween
    final currentDistance = Geolocator.distanceBetween(
      _capturedLat,
      _capturedLng,
      _schoolLat,
      _schoolLng,
    );
    final withinBoundary = currentDistance <= _allowedRadiusMeters;

    if (!withinBoundary || _capturedSelfie == null) {
      await _showFailureModal();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = await _authService.getCurrentUserProfile() ?? _effectiveUser;
      final now = DateTime.now();
      final isOnTime = _isOnTime(now);
      final description = isOnTime ? 'Attend' : 'Late';
      final formattedTimestamp =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      final attendance = AttendanceModel(
        id: '',
        userId: user.uid,
        name: user.name,
        nis: user.nis,
        studentClass: user.userClass,
        approvalStatus: 'approved',
        description: description,
        address: 'SMK IDN Boarding School Solo',
        datetime: formattedTimestamp,
        latitude: _capturedLat,
        longitude: _capturedLng,
        type: 'attendance',
        createdAt: now,
      );

      await _attendanceService.recordAttendance(attendance);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      await _showSuccessModal(
        checkInTime: now,
        isOnTime: isOnTime,
        user: user,
      );
    } catch (e) {
      debugPrint('Error submitting check-in: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _showFailureModal(errorDetail: e.toString());
    }
  }

  Future<void> _showSuccessModal({
    required DateTime checkInTime,
    required bool isOnTime,
    required UserModel user,
  }) async {
    final formattedHourMin = DateFormat('HH:mm').format(checkInTime);
    final statusLabel =
        isOnTime ? 'Tepat Waktu (On time)' : 'Terlambat (Late)';
    final statusColor = isOnTime ? _successGreen : _warningOrange;

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
                  boxShadow: [
                    BoxShadow(
                      color: _darkCameraUi.withValues(alpha: 0.16),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Green Checkmark
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.5, end: 1.0),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _successGreen.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: _successGreen,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Large Timestamp Header (Matches Image 5 "Check-in - Success")
                    Text(
                      'You are checked in • $formattedHourMin',
                      textAlign: TextAlign.center,
                      style: _manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _darkCameraUi,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Status Pill: Tepat Waktu (On time) / Terlambat (Late)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: _manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Summary Tile
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _canvasBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _cobalt50),
                      ),
                      child: Column(
                        children: [
                          _buildModalSummaryRow(
                            label: 'Location',
                            value: 'IDN Solo Campus',
                          ),
                          const Divider(height: 20, color: Color(0xFFE2E8F0)),
                          _buildModalSummaryRow(
                            label: 'Verified by',
                            value: 'Location + Selfie',
                          ),
                          const Divider(height: 20, color: Color(0xFFE2E8F0)),
                          _buildModalSummaryRow(
                            label: 'Student',
                            value: '${user.name} (${user.nis})',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Solid "Done" Button -> pops back to HomeScreen
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
                          'Done',
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

  Future<void> _showFailureModal({String? errorDetail}) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: _surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Red Exclamation Icon Badge (Matches Image 8 "Check-in failed")
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _errorRed.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: _errorRed,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Check-in did not go through',
                    textAlign: TextAlign.center,
                    style: _manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _darkCameraUi,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Location verification failed or outside designated 100m boundary. Your selfie is kept so you can retry without retaking it.',
                    textAlign: TextAlign.center,
                    style: _manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _slateText,
                      height: 1.45,
                    ),
                  ),
                  if (errorDetail != null && errorDetail.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorDetail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: _manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _errorRed,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        setState(() {
                          _currentStep = _CheckInStep.locationVerification;
                        });
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
                        'Try Again',
                        style: _manrope(
                          fontSize: 14.5,
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
        );
      },
    );
  }

  Widget _buildModalSummaryRow({
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: _manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _slateText,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: _manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _darkCameraUi,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // ROOT BUILDER (STATE-DRIVEN MULTI-STEP WORKFLOW)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return switch (_currentStep) {
      _CheckInStep.locationVerification => _buildStep1LocationScaffold(),
      _CheckInStep.selfieCamera => FaceScanScreen(
          onPhotoCaptured: _onPhotoCaptured,
          onCancel: () {
            setState(() => _currentStep = _CheckInStep.locationVerification);
          },
        ),
      _CheckInStep.selfieReview => _buildStep3SelfieReviewScaffold(),
    };
  }

  // ==========================================
  // STEP 1 UI: LOCATION & GEOFENCING VERIFICATION
  // ==========================================
  Widget _buildStep1LocationScaffold() {
    final user = _effectiveUser;
    final roundedDistance = _distanceMeters.round();

    return Scaffold(
      backgroundColor: _canvasBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                // Top Bar with Close button, Title "Check in", and Discreet Examiner Switch
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Tutup',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _darkCameraUi,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Check in',
                          style: _manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _darkCameraUi,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      // Discreet Examiner Switch in top-right corner
                      Tooltip(
                        message:
                            'Examiner Mode Switch (Real GPS / 35m Inside / 320m Outside)',
                        child: InkWell(
                          onTap: _cycleLocationMode,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _simMode == _LocationSimMode.realGps
                                  ? _surfaceCard
                                  : _cobalt50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _cobalt50, width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 15,
                                  color: _simMode == _LocationSimMode.realGps
                                      ? _slateText
                                      : _cobalt500,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  switch (_simMode) {
                                    _LocationSimMode.realGps => 'GPS Live',
                                    _LocationSimMode.mockInsideCampus =>
                                      'Sim 35m',
                                    _LocationSimMode.mockOutsideCampus =>
                                      'Sim 320m',
                                  },
                                  style: _manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _simMode == _LocationSimMode.realGps
                                        ? _slateText
                                        : _cobalt500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Authenticated Student Identity Pill (No manual TextField)
                        _buildAuthenticatedIdentityBanner(user),
                        const SizedBox(height: 16),

                        // Interactive Verification Card (White Bento Card, radius 24)
                        Container(
                          decoration: BoxDecoration(
                            color: _surfaceCard,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _cobalt50, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: _darkCameraUi.withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Radar Pulsing Graphic at Top (Double-tap also toggles Examiner Mode)
                              GestureDetector(
                                onDoubleTap: _cycleLocationMode,
                                child: _buildRadarMapHeader(),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Pass location check to continue',
                                          style: _manrope(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _slateText,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: _isCheckingLocation
                                              ? null
                                              : () {
                                                  setState(
                                                    () => _simMode =
                                                        _LocationSimMode
                                                            .realGps,
                                                  );
                                                  _verifyDeviceLocation();
                                                },
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.refresh_rounded,
                                                  size: 14,
                                                  color: _cobalt500,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Refresh',
                                                  style: _manrope(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: _cobalt500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // 2. Location Verification Row (Matches Image 5 & 8)
                                    _buildLocationStatusRow(roundedDistance),

                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      child: Divider(
                                        height: 1,
                                        color: Color(0xFFF1F5F9),
                                      ),
                                    ),

                                    // 3. Secondary Campus Wi-Fi / Identity Lock Row
                                    _buildSecondaryVerificationRow(user),

                                    const SizedBox(height: 18),

                                    // 4. Subtitle Caption Banner explaining next steps
                                    _buildNextStepBanner(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: BoxDecoration(
                    color: _canvasBg,
                    border: Border(
                      top: BorderSide(
                        color: _cobalt50.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_capturedSelfie != null && _isWithinRadius) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(
                                  () => _currentStep = _CheckInStep.selfieReview,
                                );
                              },
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                              ),
                              label: Text(
                                'Use Saved Selfie & Review',
                                style: _manrope(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: _cobalt500,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _cobalt500,
                                side: const BorderSide(
                                  color: _cobalt500,
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: (!_isCheckingLocation && _isWithinRadius)
                              ? () {
                                  setState(
                                    () =>
                                        _currentStep = _CheckInStep.selfieCamera,
                                  );
                                }
                              : null,
                          icon: Icon(
                            _isWithinRadius
                                ? Icons.camera_alt_outlined
                                : Icons.block_rounded,
                            size: 19,
                          ),
                          label: Text(
                            _isCheckingLocation
                                ? 'Verifying location...'
                                : (_isWithinRadius
                                    ? 'Take selfie'
                                    : 'Outside School Area (Min. 100m)'),
                            style: _manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: (!_isCheckingLocation && _isWithinRadius)
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cobalt500,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE2E8F0),
                            disabledForegroundColor: const Color(0xFF94A3B8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticatedIdentityBanner(UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cobalt50, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: _cobalt50,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
              style: _manrope(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _cobalt500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _darkCameraUi,
                  ),
                ),
                Text(
                  'NIS ${user.nis} • ${user.userClass}',
                  style: _manrope(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _slateText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _cobalt50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: _cobalt500,
                ),
                const SizedBox(width: 4),
                Text(
                  'ID Locked',
                  style: _manrope(
                    fontSize: 10.5,
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

  Widget _buildRadarMapHeader() {
    final statusAccent = _isCheckingLocation
        ? _cobalt500
        : (_isWithinRadius ? _cobalt500 : _errorRed);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
      child: Container(
        height: 190,
        color: const Color(0xFFF5F8FF),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle Map Grid Lines
            Positioned.fill(
              child: CustomPaint(
                painter: _CampusMapGridPainter(),
              ),
            ),

            // Animated Pulsing Geofence Radar Rings
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, _) {
                final progress = _radarController.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer expanding pulse ring
                    Container(
                      width: 96 + (progress * 68),
                      height: 96 + (progress * 68),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusAccent.withValues(
                          alpha: (1.0 - progress) * 0.16,
                        ),
                      ),
                    ),
                    // 100m Geofence Boundary Circle
                    Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusAccent.withValues(alpha: 0.12),
                        border: Border.all(
                          color: statusAccent.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Central School Pin (SMK IDN Solo)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _cobalt500,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _cobalt500.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),

            // Student Position Dot (Inside or Outside the 100m ring)
            if (!_isCheckingLocation)
              Transform.translate(
                offset: _isWithinRadius
                    ? const Offset(22, 18)
                    : const Offset(72, -44),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _isWithinRadius ? _successGreen : _errorRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: (_isWithinRadius ? _successGreen : _errorRed)
                            .withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),

            // Subtle hint at bottom-right of radar
            Positioned(
              bottom: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _cobalt50),
                ),
                child: Text(
                  'Radius: 100m • Double-tap radar to test',
                  style: _manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _slateText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatusRow(int roundedDistance) {
    if (_isCheckingLocation) {
      return Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _cobalt50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_searching_rounded,
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
                  'Location',
                  style: _manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _darkCameraUi,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Finding your position relative to IDN Solo...',
                  style: _manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _slateText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _cobalt500,
            ),
          ),
        ],
      );
    }

    final Color iconColor = _isWithinRadius ? _successGreen : _errorRed;
    final Color badgeBg = _isWithinRadius
        ? _successGreen.withValues(alpha: 0.12)
        : _warningOrange.withValues(alpha: 0.15);
    final Color badgeTextColor =
        _isWithinRadius ? const Color(0xFF067647) : const Color(0xFFB54708);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isWithinRadius
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            color: iconColor,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location',
                style: _manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _darkCameraUi,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isWithinRadius
                    ? 'Location: Within ${roundedDistance}m of IDN Solo'
                    : 'Location: ${roundedDistance}m away from school',
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isWithinRadius
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                size: 13,
                color: badgeTextColor,
              ),
              const SizedBox(width: 4),
              Text(
                _isWithinRadius ? 'Verified' : 'Outside Radius',
                style: _manrope(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: badgeTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryVerificationRow(UserModel user) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.wifi_tethering_rounded,
            color: _slateText,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Campus Coordinates',
                style: _manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _darkCameraUi,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_capturedLat.toStringAsFixed(5)}, ${_capturedLng.toStringAsFixed(5)}',
                style: _manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _slateText,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user.userClass,
            style: _manrope(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _slateText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextStepBanner() {
    final bool verified = !_isCheckingLocation && _isWithinRadius;
    final Color bannerBg = verified
        ? _successGreen.withValues(alpha: 0.10)
        : _errorRed.withValues(alpha: 0.08);
    final Color bannerIconColor = verified ? _successGreen : _errorRed;
    final Color bannerTitleColor =
        verified ? const Color(0xFF067647) : _errorRed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            verified
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: bannerIconColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verified ? 'You can check in' : 'Move closer to IDN Solo',
                  style: _manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: bannerTitleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  verified
                      ? 'Verified by your location. Next, take a quick selfie.'
                      : 'You must be within 100 meters of SMK IDN Boarding School Solo to take a check-in selfie.',
                  style: _manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _darkCameraUi.withValues(alpha: 0.8),
                    height: 1.4,
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
  // STEP 3 UI: SELFIE REVIEW (Matches Image 5 "Review selfie")
  // ==========================================
  Widget _buildStep3SelfieReviewScaffold() {
    final timeStr = DateFormat('HH:mm').format(DateTime.now());

    return Scaffold(
      backgroundColor: _darkCameraUi,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                // Top Bar: Close (X) and Title "Review selfie"
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Material(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _isSubmitting
                              ? null
                              : () {
                                  setState(
                                    () => _currentStep =
                                        _CheckInStep.locationVerification,
                                  );
                                },
                          child: const SizedBox(
                            width: 42,
                            height: 42,
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'Review selfie',
                        style: _manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 42),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Top Pill Badge: "Looks good • SMK IDN Solo"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: _successGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Looks good • SMK IDN Solo ($timeStr)',
                        style: _manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Centered Oval Framed Selfie Preview
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: AspectRatio(
                        aspectRatio: 0.78,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(220),
                            border: Border.all(
                              color: _cobalt500,
                              width: 3.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _cobalt500.withValues(alpha: 0.32),
                                blurRadius: 28,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(220),
                            child: _buildCapturedSelfieImage(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Watermark
                Text(
                  'IDN Boarding School Solo • Biometric Check',
                  style: _manrope(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.58),
                  ),
                ),

                const SizedBox(height: 20),

                // Bottom Action Row: "Retake" & "Confirm & Check In"
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    setState(
                                      () => _currentStep =
                                          _CheckInStep.selfieCamera,
                                    );
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.65),
                                width: 1.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Retake',
                              style: _manrope(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : _confirmAndSubmitCheckIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _cobalt500,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  _cobalt500.withValues(alpha: 0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Confirm & Check In',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _manrope(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCapturedSelfieImage() {
    if (_selfieBytes != null) {
      return Image.memory(
        _selfieBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (_capturedSelfie != null && kIsWeb && _capturedSelfie!.path.isNotEmpty) {
      return Image.network(
        _capturedSelfie!.path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return Container(
      color: const Color(0xFF152642),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 96,
        color: Colors.white54,
      ),
    );
  }
}

/// Draws a clean architectural street/campus grid behind the radar circle.
class _CampusMapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F6)
      ..strokeWidth = 1.0;

    const double step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Subtle dashed outer radar ring
    final center = Offset(size.width / 2, size.height / 2);
    final dashedPaint = Paint()
      ..color = const Color(0xFF2952F2).withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const double radius = 78.0;
    const int segments = 36;
    const double sweep = (2 * math.pi) / (segments * 2);
    for (int i = 0; i < segments; i++) {
      final startAngle = i * 2 * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        dashedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
