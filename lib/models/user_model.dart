import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String nis;
  final String role; // 'student' or 'teacher'
  final String userClass;
  final String? avatarUrl;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.nis,
    required this.role,
    required this.userClass,
    this.avatarUrl,
  });

  bool get isTeacher => role.toLowerCase() == 'teacher';
  bool get isStudent => role.toLowerCase() == 'student';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final rawData = doc.data();
    final Map<String, dynamic> data =
        rawData is Map<String, dynamic> ? rawData : <String, dynamic>{};
    return UserModel.fromMap(data, doc.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    final String parsedRole =
        (data['role']?.toString() ?? 'student').trim().toLowerCase();
    return UserModel(
      uid: uid,
      email: (data['email']?.toString() ?? '').trim(),
      name: (data['name']?.toString() ?? '').trim().isNotEmpty
          ? data['name'].toString().trim()
          : 'Peserta Didik XI RPL',
      nis: (data['nis']?.toString() ?? '').trim().isNotEmpty
          ? data['nis'].toString().trim()
          : '-',
      role: parsedRole == 'teacher' ? 'teacher' : 'student',
      userClass: (data['userClass']?.toString() ?? '').trim().isNotEmpty
          ? data['userClass'].toString().trim()
          : 'XI RPL',
      avatarUrl: data['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'name': name,
      'nis': nis,
      'role': role,
      'userClass': userClass,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}

