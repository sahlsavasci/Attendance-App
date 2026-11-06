import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:attendance_app/firebase_options.dart';
import 'package:attendance_app/models/user_model.dart';
import 'package:attendance_app/services/auth_service.dart';
import 'package:attendance_app/ui/auth/login_screen.dart';
import 'package:attendance_app/ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale bahasa Indonesia untuk formatting tanggal & waktu
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('Failed to initialize date formatting: $e');
  }

  // Inisialisasi Firebase multiplatform (Web, Android, iOS)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint(
      'Firebase connected successfully on ${DefaultFirebaseOptions.currentPlatform.projectId}',
    );
  } catch (e) {
    debugPrint('Firebase connection warning: $e');
  }

  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    const cobalt500 = Color(0xFF2952F2);
    const inkText = Color(0xFF0E1A2B);
    const canvasBg = Color(0xFFF2F4F7);

    return MaterialApp(
      title: 'Attendance App - XI RPL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.manrope().fontFamily,
        scaffoldBackgroundColor: canvasBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: cobalt500,
          primary: cobalt500,
          secondary: cobalt500,
          surface: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: cobalt500,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: GoogleFonts.manrope(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: cobalt500,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8EEFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8EEFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: cobalt500, width: 1.6),
          ),
          labelStyle: GoogleFonts.manrope(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5B6474),
          ),
          hintStyle: GoogleFonts.manrope(
            fontSize: 13,
            color: const Color(0xFF5B6474),
          ),
        ),
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: GoogleFonts.manrope().fontFamily,
          bodyColor: inkText,
          displayColor: inkText,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserModel?>(
      valueListenable: AuthService.demoFallbackListenable,
      builder: (context, demoProfile, _) {
        return StreamBuilder<User?>(
          stream: _authService.authStateChanges,
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting &&
                demoProfile == null) {
              return const _AuthLoadingScaffold();
            }

            final firebaseUser = authSnapshot.data;

            // Jika belum login di Firebase Auth maupun Demo Preset, arahkan ke LoginScreen
            if (firebaseUser == null && demoProfile == null) {
              return const LoginScreen();
            }

            // Jika profil sudah tersedia dari Demo Preset / cache dengan UID yang sesuai
            if (demoProfile != null &&
                (firebaseUser == null || demoProfile.uid == firebaseUser.uid)) {
              return HomeScreen(currentUser: demoProfile);
            }

            // Ambil UserModel dari Firestore berdasarkan user yang sedang login
            return FutureBuilder<UserModel?>(
              future: _authService.getCurrentUserProfile(),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return const _AuthLoadingScaffold();
                }

                final resolvedUser = profileSnapshot.data ??
                    UserModel(
                      uid: firebaseUser!.uid,
                      email: firebaseUser.email ?? AuthService.studentDemoEmail,
                      name: 'Sahl Savasci',
                      nis: '202411001',
                      role: 'student',
                      userClass: 'XI RPL',
                    );

                return HomeScreen(currentUser: resolvedUser);
              },
            );
          },
        );
      },
    );
  }
}

class _AuthLoadingScaffold extends StatelessWidget {
  const _AuthLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF2F4F7),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2952F2),
        ),
      ),
    );
  }
}
