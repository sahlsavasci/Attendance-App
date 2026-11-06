import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String userId;
  final String nis;
  final String studentClass;
  final String approvalStatus; // 'pending', 'approved', 'rejected'
  final String name;
  final String description;
  final String address;
  final String datetime;
  final String type;
  final String? reason;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const AttendanceModel({
    required this.id,
    this.userId = '',
    this.nis = '-',
    this.studentClass = 'XI RPL',
    this.approvalStatus = 'approved',
    required this.name,
    required this.description,
    required this.address,
    required this.datetime,
    required this.type,
    this.reason,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final rawData = doc.data();
    final Map<String, dynamic> data =
        rawData is Map<String, dynamic> ? rawData : <String, dynamic>{};
    return AttendanceModel.fromMap(data, doc.id);
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> data, String id) {
    final String parsedType = data['type']?.toString() ?? 'attendance';
    final String defaultApproval =
        parsedType == 'permission' ? 'pending' : 'approved';

    return AttendanceModel(
      id: id,
      userId: data['userId']?.toString() ?? '',
      nis: (data['nis']?.toString() ?? '').trim().isNotEmpty
          ? data['nis'].toString().trim()
          : '-',
      studentClass: (data['studentClass']?.toString() ?? '').trim().isNotEmpty
          ? data['studentClass'].toString().trim()
          : 'XI RPL',
      approvalStatus:
          (data['approvalStatus']?.toString() ?? '').trim().isNotEmpty
              ? data['approvalStatus'].toString().trim().toLowerCase()
              : defaultApproval,
      name: (data['name']?.toString() ?? '').trim().isNotEmpty
          ? data['name'].toString().trim()
          : 'Siswa',
      description: data['description']?.toString() ?? '-',
      address: data['address']?.toString() ?? '-',
      datetime: data['datetime']?.toString() ?? '-',
      type: parsedType,
      reason: data['reason']?.toString(),
      latitude: _parseDouble(data['latitude']),
      longitude: _parseDouble(data['longitude']),
      createdAt: _parseDateTime(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'nis': nis,
      'studentClass': studentClass,
      'approvalStatus': approvalStatus,
      'name': name,
      'description': description,
      'address': address,
      'datetime': datetime,
      'type': type,
      if (reason != null) 'reason': reason,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
