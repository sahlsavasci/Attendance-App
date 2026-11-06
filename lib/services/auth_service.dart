import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class AuthService {
  static final ValueNotifier<UserModel?> _demoFallbackNotifier =
      ValueNotifier<UserModel?>(null);

  static UserModel? get activeDemoFallbackUser => _demoFallbackNotifier.value;
  static ValueListenable<UserModel?> get demoFallbackListenable =>
      _demoFallbackNotifier;

  static const String studentDemoEmail = 'siswa@idn.sch.id';
  static const String teacherDemoEmail = 'guru@idn.sch.id';
  static const String defaultDemoPassword = 'Password123!';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> _usersCollection =
      FirebaseFirestore.instance.collection('users');

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<UserModel?> getCurrentUserProfile() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return _demoFallbackNotifier.value;
    }

    try {
      final doc = await _usersCollection.doc(firebaseUser.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc);
      }

      // Jika dokumen profil belum ada di koleksi `users`, buat otomatis
      final seededProfile = _buildDefaultProfileForEmail(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? studentDemoEmail,
      );
      await _usersCollection
          .doc(firebaseUser.uid)
          .set(seededProfile.toMap(), SetOptions(merge: true));
      return seededProfile;
    } catch (e) {
      debugPrint('Fallback profil lokal karena pembacaan Firestore gagal: $e');
      return _buildDefaultProfileForEmail(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? studentDemoEmail,
      );
    }
  }

  Future<UserModel> signIn(String email, String password) async {
    final normalizedInput = email.trim().toLowerCase();
    // Mendukung login menggunakan NIS siswa demo maupun alamat email langsung
    final resolvedEmail = normalizedInput == '202411001'
        ? studentDemoEmail
        : (normalizedInput.contains('@')
            ? normalizedInput
            : '$normalizedInput@idn.sch.id');

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: resolvedEmail,
        password: password,
      );
      final user = credential.user!;
      return await _ensureAndFetchUserDocument(user.uid, resolvedEmail);
    } on FirebaseAuthException catch (e) {
      // Jika akun adalah akun demo standar dan belum terdaftar di Firebase Auth,
      // daftarkan otomatis agar demonstrasi tidak pernah gagal.
      if (_isDemoEmail(resolvedEmail) &&
          (e.code == 'user-not-found' ||
              e.code == 'invalid-credential' ||
              e.code == 'invalid-login-credentials')) {
        return await _registerAndSeedAccount(
          email: resolvedEmail,
          password: password,
        );
      }
      rethrow;
    }
  }

  Future<UserModel> signInQuickDemo(String role) async {
    final isTeacher = role.trim().toLowerCase() == 'teacher';
    final targetEmail = isTeacher ? teacherDemoEmail : studentDemoEmail;

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: targetEmail,
        password: defaultDemoPassword,
      );
      final uid = credential.user!.uid;
      final profile = _buildDefaultProfileForEmail(
        uid: uid,
        email: targetEmail,
        forcedRole: isTeacher ? 'teacher' : 'student',
      );
      try {
        await _usersCollection
            .doc(uid)
            .set(profile.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Seed koleksi users dilewati: $e');
      }
      _demoFallbackNotifier.value = profile;
      return profile;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        try {
          return await _registerAndSeedAccount(
            email: targetEmail,
            password: defaultDemoPassword,
            forcedRole: isTeacher ? 'teacher' : 'student',
          );
        } catch (_) {
          // Lanjut ke fallback di bawah jika Email/Password provider belum diaktifkan di Console
        }
      }

      // Fallback kedua: coba signInAnonymously agar tetap punya request.auth.uid valid
      try {
        final anonCred = await _auth.signInAnonymously();
        final uid = anonCred.user!.uid;
        final profile = _buildDefaultProfileForEmail(
          uid: uid,
          email: targetEmail,
          forcedRole: isTeacher ? 'teacher' : 'student',
        );
        try {
          await _usersCollection
              .doc(uid)
              .set(profile.toMap(), SetOptions(merge: true));
        } catch (_) {}
        _demoFallbackNotifier.value = profile;
        return profile;
      } catch (_) {
        // Fallback terakhir untuk mode presentasi apabila Firebase Auth Console belum diaktifkan
        final localProfile = _buildDefaultProfileForEmail(
          uid: isTeacher ? 'demo_teacher_uid' : 'demo_student_uid',
          email: targetEmail,
          forcedRole: isTeacher ? 'teacher' : 'student',
        );
        _demoFallbackNotifier.value = localProfile;
        return localProfile;
      }
    }
  }

  Future<void> signOut() async {
    _demoFallbackNotifier.value = null;
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out warning: $e');
    }
  }

  Future<UserModel> _registerAndSeedAccount({
    required String email,
    required String password,
    String? forcedRole,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final profile = _buildDefaultProfileForEmail(
      uid: uid,
      email: email,
      forcedRole: forcedRole,
    );
    try {
      await _usersCollection
          .doc(uid)
          .set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Gagal menyimpan dokumen user baru ke Firestore: $e');
    }
    _demoFallbackNotifier.value = profile;
    return profile;
  }

  Future<UserModel> _ensureAndFetchUserDocument(
    String uid,
    String email,
  ) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final existing = UserModel.fromFirestore(doc);
        _demoFallbackNotifier.value = existing;
        return existing;
      }
      final seeded = _buildDefaultProfileForEmail(uid: uid, email: email);
      await _usersCollection
          .doc(uid)
          .set(seeded.toMap(), SetOptions(merge: true));
      _demoFallbackNotifier.value = seeded;
      return seeded;
    } catch (_) {
      final fallback = _buildDefaultProfileForEmail(uid: uid, email: email);
      _demoFallbackNotifier.value = fallback;
      return fallback;
    }
  }

  bool _isDemoEmail(String email) {
    final lower = email.toLowerCase();
    return lower == studentDemoEmail || lower == teacherDemoEmail;
  }

  UserModel _buildDefaultProfileForEmail({
    required String uid,
    required String email,
    String? forcedRole,
  }) {
    final lower = email.toLowerCase();
    final isTeacher =
        forcedRole == 'teacher' || lower == teacherDemoEmail || lower.contains('guru');

    if (isTeacher) {
      return UserModel(
        uid: uid,
        email: email,
        name: 'Guru Pembimbing',
        nis: 'NIP-19920814',
        role: 'teacher',
        userClass: 'XI RPL',
      );
    }

    if (lower == studentDemoEmail) {
      return UserModel(
        uid: uid,
        email: email,
        name: 'Sahl Savasci',
        nis: '202411001',
        role: 'student',
        userClass: 'XI RPL',
      );
    }

    final namePrefix = email.split('@').first.replaceAll('.', ' ');
    final formattedName = namePrefix.isEmpty
        ? 'Siswa XI RPL'
        : namePrefix[0].toUpperCase() + namePrefix.substring(1);

    return UserModel(
      uid: uid,
      email: email,
      name: formattedName,
      nis: '202411002',
      role: 'student',
      userClass: 'XI RPL',
    );
  }
}

