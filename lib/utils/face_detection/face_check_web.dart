import 'dart:js_interop';

import 'package:camera/camera.dart';

// Fungsi global didefinisikan di web/index.html.
@JS('faceCheckWarmUp')
external JSPromise<JSBoolean> _faceCheckWarmUp();

@JS('faceCheckCount')
external JSPromise<JSNumber> _faceCheckCount(String imageUrl);

/// Mengunduh model deteksi wajah lebih awal agar jepretan pertama tidak lambat.
Future<void> warmUpFaceCheck() async {
  await _faceCheckWarmUp().toDart;
}

/// Menghitung jumlah wajah pada foto webcam. Di web, [XFile.path] berisi blob URL.
Future<int> countFaces(XFile photo) async {
  final result = await _faceCheckCount(photo.path).toDart;
  return result.toDartInt;
}

