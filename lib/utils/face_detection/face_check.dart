// Satu API untuk semua platform:
// - Android/iOS: Google ML Kit (face_check_mobile.dart)
// - Browser (laptop): MediaPipe Face Detector via JS (face_check_web.dart)
export 'face_check_mobile.dart'
    if (dart.library.js_interop) 'face_check_web.dart';

