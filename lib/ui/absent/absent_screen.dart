import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:lottie/lottie.dart';
// import 'attend_screen.dart'; // Aktifkan ini dan pastikan class AttendScreen Anda sudah ada

class AbsentScreen extends StatefulWidget {
  const AbsentScreen({super.key});

  @override
  State<AbsentScreen> createState() => _AbsentScreenState();
}

class _AbsentScreenState extends State<AbsentScreen> {
  // Variabel untuk Kamera
  CameraController? controller;
  bool isCameraReady = false;

  // Variabel untuk ML Kit Face Detection
  bool isBusy = false;
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  // ==========================================
  // 1. Inisialisasi Kamera Depan
  // ==========================================
  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    controller = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false, // Hemat memori, tidak butuh audio untuk foto
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller!.initialize();
      if (mounted) setState(() => isCameraReady = true);
    } catch (e) {
      debugPrint("Failed to initialize camera: $e");
    }
  }

  // ==========================================
  // 2. Pemrosesan Citra & Validasi Wajah AI
  // ==========================================
  Future<void> processImage(InputImage inputImage, XFile imageFile) async {
    if (isBusy) return;
    isBusy = true;

    try {
      final faces = await faceDetector.processImage(inputImage);
      isBusy = false;

      if (!mounted) return;
      // Tutup dialog loading
      Navigator.of(context, rootNavigator: true).pop(); 

      if (faces.isNotEmpty) {
        // Wajah asli terdeteksi -> Lanjut ke layar form konfirmasi presensi
        // Hapus komentar pada navigasi di bawah ini jika AttendScreen sudah dibuat:
        /*
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AttendScreen(image: imageFile),
          ),
        );
        */
        _showSnackBar("Wajah Terdeteksi! Navigasi ke halaman form...", Icons.check_circle_outline);
      } else {
        _showSnackBar("Wajah tidak terdeteksi! Pastikan wajah terlihat jelas di bingkai.", Icons.warning_amber_rounded);
      }
    } catch (e) {
      isBusy = false;
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar("Gagal memproses deteksi wajah: $e", Icons.error_outline);
      }
    }
  }

  // ==========================================
  // Fungsi Pembantu: Menampilkan Pesan SnackBar
  // ==========================================
  void _showSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blueGrey[900],
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. Pembersihan Resource (Dispose)
  // ==========================================
  @override
  void dispose() {
    controller?.dispose(); // Lepaskan kamera dari memori
    faceDetector.close();  // Hentikan proses ML Kit
    super.dispose();
  }

  // ==========================================
  // Tampilan Antarmuka (UI)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Kehadiran'),
        backgroundColor: Colors.blueAccent,
      ),
      body: isCameraReady && controller != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Layer 1 (Bawah): Tampilan Kamera Realtime
                CameraPreview(controller!),

                // Layer 2 (Atas): Overlay Animasi Scanner Lottie & DottedBorder
                Center(
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(24),
                    dashPattern: const [8, 4],
                    color: Colors.blueAccent,
                    strokeWidth: 2,
                    child: SizedBox(
                      width: 260,
                      height: 340,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Lottie.asset(
                            'assets/raw/face_id_ring.json',
                            width: 240,
                            height: 240,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Layer 3 (Paling Atas): Tombol Ambil Gambar
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton.large(
                      onPressed: () async {
                        if (controller != null && controller!.value.isInitialized && !isBusy) {
                          try {
                            // Munculkan loading dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            // Tangkap gambar dari kamera
                            final XFile imageFile = await controller!.takePicture();
                            
                            // Konversi ke InputImage untuk ML Kit
                            final InputImage inputImage = InputImage.fromFilePath(imageFile.path);

                            // Jalankan proses validasi wajah
                            await processImage(inputImage, imageFile);
                          } catch (e) {
                            if (mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
                              _showSnackBar("Error saat mengambil gambar: $e", Icons.error);
                            }
                          }
                        }
                      },
                      backgroundColor: Colors.blueAccent,
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 36),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
    );
  }
}