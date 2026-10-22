// File generated to provide multi-platform Firebase initialization options.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCC1ffWrr23lSg9Hm0sxMtD5K_ZSeW8H3I',
    appId: '1:464978807940:web:2dc662111249523d7346d1',
    messagingSenderId: '464978807940',
    projectId: 'sahl-attendance-app',
    authDomain: 'sahl-attendance-app.firebaseapp.com',
    storageBucket: 'sahl-attendance-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCC1ffWrr23lSg9Hm0sxMtD5K_ZSeW8H3I',
    appId: '1:464978807940:android:2dc662111249523d7346d1',
    messagingSenderId: '464978807940',
    projectId: 'sahl-attendance-app',
    storageBucket: 'sahl-attendance-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCC1ffWrr23lSg9Hm0sxMtD5K_ZSeW8H3I',
    appId: '1:464978807940:ios:2dc662111249523d7346d1',
    messagingSenderId: '464978807940',
    projectId: 'sahl-attendance-app',
    storageBucket: 'sahl-attendance-app.firebasestorage.app',
    iosBundleId: 'com.example.attendanceApp',
  );
}
