import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../utils/face_detection/face_check.dart';

/// Layar scan wajah: preview kamera langsung (webcam di laptop, kamera depan di HP),
/// jepret, lalu verifikasi ada tepat satu wajah sebelum foto dikembalikan.
class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({super.key});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

enum _ScanState { starting, ready, checking, failed }

class _FaceScanScreenState extends State<FaceScanScreen> {
  static const _navy = Color(0xFF1E2B58);
  static const _danger = Color(0xFFB91C1C);

  CameraController? _controller;
  _ScanState _state = _ScanState.starting;
  String? _cameraError;
  String? _checkMessage;

  @override
  void initState() {
    super.initState();
    _startCamera();
    // Unduh model di latar belakang; kegagalan ditangani saat jepret.
    warmUpFaceCheck().catchError((Object e) => debugPrint('Face model warm-up: $e'));
  }

  Future<void> _startCamera() async {
    setState(() {
      _state = _ScanState.starting;
      _cameraError = null;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _fail('Kamera tidak ditemukan. Pastikan webcam laptop terpasang dan tidak dipakai aplikasi lain.');
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      await _controller?.dispose();
      setState(() {
        _controller = controller;
        _state = _ScanState.ready;
      });
    } on CameraException catch (e) {
      _fail(_describeCameraError(e));
    } catch (e) {
      _fail('Kamera tidak bisa dibuka: $e');
    }
  }

  String _describeCameraError(CameraException e) {
    final code = e.code.toLowerCase();
    if (code.contains('permission') || code.contains('denied') || code.contains('notallowed')) {
      return kIsWeb
          ? 'Izin kamera ditolak. Klik ikon kamera di address bar browser, pilih "Izinkan", lalu coba lagi.'
          : 'Izin kamera ditolak. Aktifkan izin kamera untuk aplikasi ini di pengaturan.';
    }
    if (code.contains('notreadable') || code.contains('trackstart') || code.contains('inuse')) {
      return 'Webcam sedang dipakai aplikasi lain (Zoom, Meet, dll). Tutup aplikasi tersebut, lalu coba lagi.';
    }
    if (code.contains('notfound') || code.contains('nocamera')) {
      return 'Kamera tidak ditemukan di perangkat ini.';
    }
    return 'Kamera tidak bisa dibuka (${e.code}). ${e.description ?? ''}'.trim();
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _state = _ScanState.failed;
      _cameraError = message;
    });
  }

  Future<void> _captureAndVerify() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _state == _ScanState.checking) {
      return;
    }

    setState(() {
      _state = _ScanState.checking;
      _checkMessage = null;
    });

    try {
      final photo = await controller.takePicture();
      final faces = await countFaces(photo);
      if (!mounted) return;

      if (faces == 1) {
        Navigator.pop(context, photo);
        return;
      }

      setState(() {
        _state = _ScanState.ready;
        _checkMessage = faces == 0
            ? 'Wajah tidak terdeteksi. Posisikan wajah di dalam bingkai dengan cahaya yang cukup.'
            : 'Terdeteksi $faces wajah. Pastikan hanya Anda yang ada di depan kamera.';
      });
    } catch (e) {
      debugPrint('Face check error: $e');
      if (!mounted) return;
      setState(() {
        _state = _ScanState.ready;
        _checkMessage = kIsWeb
            ? 'Pemeriksaan wajah gagal dimuat. Periksa koneksi internet, lalu jepret lagi.'
            : 'Pemeriksaan wajah gagal: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Scan Wajah')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _state == _ScanState.failed ? _buildCameraError() : _buildScanner(),
          ),
        ),
      ),
    );
  }

  Widget _buildScanner() {
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;
    final isChecking = _state == _ScanState.checking;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: ColoredBox(
              color: const Color(0xFF0F172A),
              child: isReady
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        if (kIsWeb)
                          // Elemen <video> dari camera_web sudah memakai object-fit: cover.
                          controller.buildPreview()
                        else
                          FittedBox(
                            fit: BoxFit.cover,
                            clipBehavior: Clip.hardEdge,
                            child: SizedBox(
                              // previewSize di HP berorientasi landscape, dibalik untuk layar portrait.
                              width: controller.value.previewSize?.height ?? 480,
                              height: controller.value.previewSize?.width ?? 640,
                              child: CameraPreview(controller),
                            ),
                          ),
                        CustomPaint(painter: _FaceGuidePainter()),
                        if (isChecking)
                          const ColoredBox(
                            color: Color(0x99000000),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: Colors.white),
                                  SizedBox(height: 12),
                                  Text(
                                    'Memeriksa wajah…',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 12),
                          Text(
                            'Membuka kamera…',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          kIsWeb
              ? 'Hadapkan wajah ke webcam, pas di dalam oval. Jika browser meminta izin kamera, pilih "Izinkan".'
              : 'Hadapkan wajah ke kamera depan, pas di dalam oval.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
        ),
        if (_checkMessage != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: _danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _checkMessage!,
                      style: const TextStyle(fontSize: 13, height: 1.4, color: _danger),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: isReady && !isChecking ? _captureAndVerify : null,
          icon: const Icon(Icons.camera_alt, size: 20),
          label: Text(_checkMessage == null ? 'Jepret & Verifikasi' : 'Jepret Ulang'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _navy,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_outlined, size: 48, color: Color(0xFF64748B)),
          const SizedBox(height: 12),
          Text(
            _cameraError ?? 'Kamera tidak bisa dibuka.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _startCamera,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

/// Oval panduan posisi wajah; area di luarnya digelapkan.
class _FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: size.width * 0.62,
      height: size.height * 0.62,
    );

    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(oval);
    canvas.drawPath(shade, Paint()..color = const Color(0x80000000));

    canvas.drawOval(
      oval,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
