import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'google_ml_kit.dart';

/// Menyiapkan detektor lebih awal. ML Kit di perangkat tidak perlu diunduh.
Future<void> warmUpFaceCheck() async {}

/// Menghitung jumlah wajah pada foto menggunakan Google ML Kit.
Future<int> countFaces(XFile photo) async {
  final detector = GoogleMlKit.vision.faceDetector();
  try {
    final faces = await detector.processImage(InputImage.fromFilePath(photo.path));
    return faces.length;
  } finally {
    await detector.close();
  }
}

